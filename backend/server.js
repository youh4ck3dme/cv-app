require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const MISTRAL_API_KEY = process.env.MISTRAL_API_KEY;
const REVENUECAT_API_KEY = process.env.REVENUECAT_API_KEY;

// 🔒 SECRET ROTATION GUARD: Prevent dummy keys from reaching production
if (process.env.NODE_ENV === 'production') {
  if (!MISTRAL_API_KEY || MISTRAL_API_KEY.startsWith('YOUR_') || MISTRAL_API_KEY === '') {
    console.error('CRITICAL: MISTRAL_API_KEY is not set or uses a placeholder in production mode!');
    process.exit(1);
  }
}

// Middleware
app.use(helmet());
app.disable('x-powered-by');

const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
app.use(cors({
  origin: allowedOrigin === '*' ? '*' : (origin, callback) => {
    if (!origin || origin === allowedOrigin) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  }
}));
app.use(express.json({ limit: '2mb' })); // Accept base64 images

// Structured Security Telemetry Logger
// 🔒 LOG DISCIPLINE: Strips ALL sensitive payload fields before logging
function logSecurityEvent(eventType, metadata = {}) {
  const logPayload = {
    timestamp: new Date().toISOString(),
    event: eventType,
    ...metadata
  };
  // Never log user data, credentials, or AI content
  delete logPayload.text;
  delete logPayload.image;
  delete logPayload.customApiKey;
  delete logPayload.consent;
  delete logPayload.apiKey;
  // Mask any key that looks like an API key
  if (logPayload.hasCustomKey !== undefined) {
    // Keep only boolean flag, not the key itself
  }
  console.log(JSON.stringify(logPayload));
}

const analyzeLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // limit each IP to 5 requests per minute for expensive AI operations
  message: { error: 'Too many requests. Please try again after a minute.' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    logSecurityEvent('rate_limit_exceeded', {
      ip: req.ip,
      path: req.path,
      appUserId: req.headers['x-user-id'] || req.body.appUserId
    });
    res.status(options.statusCode).send(options.message);
  }
});

const permissionsLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 40, // limit each IP to 40 requests per minute
  message: { error: 'Too many requests. Please try again after a minute.' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    logSecurityEvent('rate_limit_exceeded', {
      ip: req.ip,
      path: req.path,
      appUserId: req.headers['x-user-id'] || req.body.appUserId
    });
    res.status(options.statusCode).send(options.message);
  }
});

const telemetryLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 3, // limit each IP to 3 requests per minute to prevent telemetry flood / spam
  message: { error: 'Too many telemetry reports. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    logSecurityEvent('rate_limit_exceeded', {
      ip: req.ip,
      path: req.path
    });
    res.status(options.statusCode).send(options.message);
  }
});

const entitlementCache = new Map();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes cache TTL

const MINIMUM_SUPPORTED_VERSION = process.env.MINIMUM_SUPPORTED_VERSION || '1.0.0';

function isVersionOutdated(clientVersion, minVersion) {
  if (!clientVersion) return true;
  const cleanVersion = clientVersion.split('+')[0].trim();
  const cleanMin = minVersion.split('+')[0].trim();
  const cParts = cleanVersion.split('.').map(num => parseInt(num, 10) || 0);
  const mParts = cleanMin.split('.').map(num => parseInt(num, 10) || 0);
  for (let i = 0; i < 3; i++) {
    const c = cParts[i] || 0;
    const m = mParts[i] || 0;
    if (c < m) return true;
    if (c > m) return false;
  }
  return false;
}

function securityHardeningMiddleware(req, res, next) {
  // 1. Play Integrity Check Hook
  if (process.env.ENFORCE_PLAY_INTEGRITY === 'true') {
    const integrityToken = req.headers['x-play-integrity-token'];
    if (!integrityToken) {
      logSecurityEvent('play_integrity_failed', {
        ip: req.ip,
        reason: 'missing_token',
        path: req.path
      });
      return res.status(403).json({ error: 'Forbidden: Play Integrity token required.' });
    }
    logSecurityEvent('play_integrity_verified', {
      ip: req.ip,
      appUserId: req.headers['x-user-id'] || req.body.appUserId
    });
  }

  // 2. App Version Validation
  const clientVersion = req.headers['x-app-version'];
  if (isVersionOutdated(clientVersion, MINIMUM_SUPPORTED_VERSION)) {
    logSecurityEvent('outdated_version_blocked', {
      ip: req.ip,
      clientVersion: clientVersion || 'unknown',
      minSupported: MINIMUM_SUPPORTED_VERSION,
      path: req.path
    });
    return res.status(426).json({
      upgradeRequired: true,
      minimumVersion: MINIMUM_SUPPORTED_VERSION,
      message: 'App update required. Please download the latest version from the Play Store.'
    });
  }

  next();
}


const crypto = require('crypto');

let ED25519_PRIVATE_KEY;
const privateKeyBase64 = process.env.ED25519_PRIVATE_KEY_BASE64;
if (privateKeyBase64) {
  try {
    const pem = Buffer.from(privateKeyBase64, 'base64').toString('utf8');
    ED25519_PRIVATE_KEY = crypto.createPrivateKey(pem);
  } catch (err) {
    console.error('CRITICAL: Failed to load Ed25519 private key from ED25519_PRIVATE_KEY_BASE64:', err.message);
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
} else {
  if (process.env.NODE_ENV === 'production') {
    console.error('CRITICAL: ED25519_PRIVATE_KEY_BASE64 environment variable must be set in production mode!');
    process.exit(1);
  }
  console.warn('WARNING: ED25519_PRIVATE_KEY_BASE64 is not set. Using a fallback Ed25519 private key for development.');
  const fallbackPem = `-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIM4w81FZ8VAXj6/MUpEu7jBi7k3cepjnAE9vc2ac1Bl2
-----END PRIVATE KEY-----`;
  ED25519_PRIVATE_KEY = crypto.createPrivateKey(fallbackPem);
}

const ABUSE_KEYWORDS = [
  'nazi', 'hitler', 'terrorist', 'jihad', 'bomb building',
  'fake passport', 'counterfeit money', 'identity fraud',
  'phishing template', 'social security number generator'
];

function isContentUnsafe(text) {
  if (!text) return false;
  const lower = text.toLowerCase();
  return ABUSE_KEYWORDS.some(keyword => lower.includes(keyword));
}

function generatePayloadSignature(payload) {
  const message = JSON.stringify({
    canGenerateCV: payload.canGenerateCV,
    canExportPDF: payload.canExportPDF,
    isPremium: payload.isPremium,
    expiresAt: payload.expiresAt || null,
    appUserId: payload.appUserId || null,
    jti: payload.jti || null,
    iat: payload.iat || null,
  });
  return crypto.sign(null, Buffer.from(message), ED25519_PRIVATE_KEY).toString('hex');
}


// RevenueCat Entitlement Check Helper (Detailed status check with expiration date & cache fallback)
async function getEntitlementStatus(appUserId) {
  if (!appUserId) return { isSubscribed: false, expiresAt: null };

  const now = Date.now();
  const cached = entitlementCache.get(appUserId);
  if (cached && (now - cached.cachedAt < CACHE_TTL_MS)) {
    logSecurityEvent('entitlement_cache_hit', {
      appUserId,
      isSubscribed: cached.isSubscribed,
      expiresAt: cached.expiresAt
    });
    return { isSubscribed: cached.isSubscribed, expiresAt: cached.expiresAt };
  }

  if (!REVENUECAT_API_KEY || REVENUECAT_API_KEY === 'YOUR_REVENUECAT_SECRET_API_KEY' || REVENUECAT_API_KEY.startsWith('YOUR_')) {
    if (process.env.NODE_ENV === 'production') {
      logSecurityEvent('entitlement_sync_failed', {
        appUserId,
        reason: 'missing_api_key_production'
      });
      return { isSubscribed: false, expiresAt: null };
    }
    console.warn('REVENUECAT_API_KEY is not configured or uses placeholder. Allowing access by default for development.');
    const dummyExpires = new Date();
    dummyExpires.setFullYear(dummyExpires.getFullYear() + 1); // 1 year in future
    const dummyStatus = { isSubscribed: true, expiresAt: dummyExpires.toISOString() };
    
    // Cache the dev placeholder status as well
    entitlementCache.set(appUserId, {
      ...dummyStatus,
      cachedAt: now
    });
    
    return dummyStatus;
  }
  try {
    const rcResponse = await axios.get(`https://api.revenuecat.com/v1/subscribers/${appUserId}`, {
      headers: {
        'Authorization': `Bearer ${REVENUECAT_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    if (rcResponse.status === 200) {
      const entitlements = rcResponse.data?.subscriber?.entitlements || {};
      const getActive = (ent) => {
        if (!ent) return null;
        if (!ent.expires_date) return { isActive: true, expiresAt: null }; // Lifetime
        const isActive = new Date(ent.expires_date) > new Date();
        return isActive ? { isActive: true, expiresAt: ent.expires_date } : null;
      };

      const activeEnt = getActive(entitlements.premium) || getActive(entitlements.premium_access);
      const isSubscribed = activeEnt !== null;
      const expiresAt = activeEnt ? activeEnt.expiresAt : null;

      // Update in-memory cache
      entitlementCache.set(appUserId, {
        isSubscribed,
        expiresAt,
        cachedAt: now
      });

      logSecurityEvent('entitlement_sync_success', {
        appUserId,
        isSubscribed,
        expiresAt
      });

      return { isSubscribed, expiresAt };
    }

    if (cached) {
      logSecurityEvent('entitlement_fallback_used', {
        appUserId,
        reason: `revenuecat_status_${rcResponse.status}`,
        isSubscribed: cached.isSubscribed
      });
      return { isSubscribed: cached.isSubscribed, expiresAt: cached.expiresAt };
    }
    return { isSubscribed: false, expiresAt: null };
  } catch (error) {
    logSecurityEvent('entitlement_sync_failed', {
      appUserId,
      error: error.message
    });
    // Outage Fallback: If cache exists (even if expired), return it.
    if (cached) {
      logSecurityEvent('entitlement_fallback_used', {
        appUserId,
        reason: 'revenuecat_api_exception',
        isSubscribed: cached.isSubscribed
      });
      return { isSubscribed: cached.isSubscribed, expiresAt: cached.expiresAt };
    }
    return { isSubscribed: false, expiresAt: null };
  }
}

// Compatibility wrapper for /api/analyze
async function checkEntitlement(appUserId) {
  const status = await getEntitlementStatus(appUserId);
  return status.isSubscribed;
}

app.post('/api/analyze', securityHardeningMiddleware, analyzeLimiter, async (req, res) => {
  try {
    const { image, text, language, appUserId, customApiKey, consent } = req.body;
    const clientAppUserId = appUserId || req.headers['x-user-id'];
    const clientCustomApiKey = customApiKey || req.headers['x-custom-api-key'];

    if (consent !== true && consent !== 'true') {
      logSecurityEvent('consent_rejected', {
        ip: req.ip,
        appUserId: clientAppUserId
      });
      return res.status(400).json({ error: 'Consent required for data processing.' });
    }

    if (!language) {
      return res.status(400).json({ error: 'Missing language parameter' });
    }

    if (!text && !image) {
      return res.status(400).json({ error: 'Request body must contain either a text description or a base64 image.' });
    }

    if (text) {
      if (text.length > 50000) {
        logSecurityEvent('input_validation_failed', {
          ip: req.ip,
          appUserId: clientAppUserId,
          reason: 'length_exceeded'
        });
        return res.status(400).json({ error: 'Input text length exceeds safe limits (max 50,000 characters).' });
      }
      if (isContentUnsafe(text)) {
        logSecurityEvent('content_moderation_triggered', {
          ip: req.ip,
          appUserId: clientAppUserId,
          reason: 'unsafe_content'
        });
        return res.status(400).json({ error: 'Content violated safety moderation policies.' });
      }
    }

    let apiKeyToUse = MISTRAL_API_KEY;

    // Determine authorization method
    if (clientCustomApiKey && clientCustomApiKey.trim().length > 0) {
      apiKeyToUse = clientCustomApiKey;
      // 🔒 LOG DISCIPLINE: Never log key value — log only that custom key path was taken
      logSecurityEvent('custom_key_path_taken', { ip: req.ip });
    } else {
      // Enforce subscription verification
      if (!clientAppUserId) {
        return res.status(401).json({ error: 'Unauthorized: Missing appUserId header or body parameter' });
      }

      const isSubscribed = await checkEntitlement(clientAppUserId);
      if (!isSubscribed) {
        return res.status(403).json({ error: 'Subscription required: Premium entitlement not found or expired.' });
      }
      logSecurityEvent('entitlement_access_granted', { appUserId: clientAppUserId });
    }

    const systemPrompt = `You are a highly advanced ATS-optimized Resume/CV Parser and Writer. Your goal is to parse the input text or image and extract a complete, professional, and grammatically perfect resume JSON matching the layout specification. Output language MUST be strictly ${language === 'sk' ? 'Slovak' : 'English'}.`; // Simplified prompt for brevity

    const messages = [];
    messages.push({ role: 'system', content: systemPrompt });
    const userContent = [];
    if (text) {
      userContent.push({ type: 'text', text: `INPUT CV TEXT:\n${text}` });
    } else {
      userContent.push({ type: 'text', text: 'Please parse the attached resume image and generate the CV JSON.' });
    }
    if (image) {
      userContent.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } });
    }
    messages.push({ role: 'user', content: userContent });

    const response = await axios.post('https://api.mistral.ai/v1/chat/completions', {
      model: 'pixtral-12b',
      temperature: 0.1,
      response_format: { type: 'json_object' },
      messages: messages,
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKeyToUse}`,
      },
    });

    if (response.status !== 200) {
      // 🔒 ERROR UX: Never leak upstream API error details to the client
      logSecurityEvent('ai_upstream_error', {
        path: '/api/analyze',
        upstreamStatus: response.status
      });
      return res.status(503).json({ error: 'AI temporarily unavailable. Please try again shortly.' });
    }

    const content = response.data.choices?.[0]?.message?.content;
    if (!content) {
      logSecurityEvent('ai_empty_response', { path: '/api/analyze' });
      return res.status(503).json({ error: 'AI temporarily unavailable. Please try again shortly.' });
    }

    res.json({ result: content });
  } catch (error) {
    // 🔒 ERROR UX: Map all AI/network errors to a clean, user-facing 503
    // Log only error type/code for telemetry — never raw error message (may leak key info)
    logSecurityEvent('api_error', {
      path: '/api/analyze',
      errorCode: error.code || 'UNKNOWN',
      upstreamStatus: error.response?.status
    });
    res.status(503).json({ error: 'AI temporarily unavailable. Please try again shortly.' });
  }
});

app.post('/api/permissions', securityHardeningMiddleware, permissionsLimiter, async (req, res) => {
  try {
    const { appUserId, customApiKey } = req.body;
    const clientAppUserId = appUserId || req.headers['x-user-id'];
    const clientCustomApiKey = customApiKey || req.headers['x-custom-api-key'];

    let canGenerateCV = true;
    let canExportPDF = false;
    let isPremium = false;
    let expiresAt = null;

    // Rule #3 Bypass Mitigation: Custom API key ONLY unlocks AI generation
    // NOT premium PDF export, premium templates, etc.
    if (clientCustomApiKey && clientCustomApiKey.trim().length > 0) {
      canGenerateCV = true;
    }

    if (clientAppUserId) {
      const entitlement = await getEntitlementStatus(clientAppUserId);
      if (entitlement.isSubscribed) {
        canExportPDF = true;
        isPremium = true;
        expiresAt = entitlement.expiresAt;
      }
    }

    const payload = {
      canGenerateCV,
      canExportPDF,
      isPremium,
      expiresAt,
      appUserId: clientAppUserId || null,
      jti: crypto.randomUUID(),
      iat: Math.floor(Date.now() / 1000),
    };

    const signature = generatePayloadSignature(payload);

    logSecurityEvent('permissions_granted', {
      appUserId: clientAppUserId,
      hasCustomKey: !!clientCustomApiKey,
      isPremium,
      expiresAt,
      jti: payload.jti
    });

    res.json({
      ...payload,
      signature,
    });
  } catch (error) {
    logSecurityEvent('api_error', {
      path: '/api/permissions',
      error: error.message
    });
    console.error('Permissions check error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
app.post('/api/security-telemetry', securityHardeningMiddleware, telemetryLimiter, (req, res) => {
  try {
    const { eventType, details, appUserId } = req.body;

    logSecurityEvent('client_security_alert', {
      severity: 'CRITICAL',
      alertType: eventType || 'UNKNOWN_ALERT',
      appUserId: appUserId || 'UNKNOWN_USER',
      details: details || {},
      ip: req.ip
    });

    res.status(204).end();
  } catch (error) {
    logSecurityEvent('telemetry_endpoint_error', {
      error: error.message
    });
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Backend gateway listening on port ${PORT}`);
});
