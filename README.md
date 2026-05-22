# CV Životopis Mobile App (Flutter) 📱

Tento adresár obsahuje mobilnú aplikáciu **CV Životopis** vyvíjanú v frameworku **Flutter** pre platformy Android a iOS.

---

## 🛠️ Architektúra a Štruktúra Kódu

Aplikácia je postavená na moderných návrhoch vo Flutteri s rozdelením na logickú vrstvu a UI.

### Použité knižnice:
- **Riverpod (`flutter_riverpod`):** Pre správu stavu, závislostí a asynchrónnych operácií.
- **Flutter Hooks (`flutter_hooks`):** Pre zjednodušenie životného cyklu widgetov a zamedzenie boilerplate kódu (napr. textové kontroléry, focus node).
- **RevenueCat (`purchases_flutter`):** Pre správu platobnej brány, kontrolu aktívneho predplatného a obnovu nákupov.
- **Google Fonts:** Pre modernú a konzistentnú typografiu.

---

## 📂 Dôležité komponenty

- **[paywall_screen.dart](file:///Users/erikbabcan/cv-zivotopis-app/flutter_cv_app/lib/screens/paywall_screen.dart):** 
  Obrazovka platobnej brány (Paywall) spĺňajúca podmienky Apple App Store pre predplatné produkty. Ponúka nákup ročného a mesačného predplatného, obnovu nákupov (Restore) a zmluvné podmienky (Terms/Privacy).
- **Double-tap prevention:** 
  Počas prebiehajúcej transakcie sa rozhranie prepne do stavu načítavania, čím sa deaktivujú nákupné tlačidlá a zabráni sa duplicitným transakciám.
- **PlatformException mapping:** 
  Mapovanie chybových kódov RevenueCat na používateľsky zrozumiteľné chybové hlášky (napr. zrušenie platby, čakajúca platba atď.).

---

## 🧪 Testovanie

Pre mobilnú aplikáciu sú pripravené robustné widget a unit testy, ktoré pokrývajú kompletnú funkcionalitu nákupného procesu:
- **Umiestnenie testov:** [paywall_screen_test.dart](file:///Users/erikbabcan/cv-zivotopis-app/flutter_cv_app/test/paywall_screen_test.dart).

### Pokryté testovacie prípady:
1. Úspešné zobrazenie a načítanie platobných balíčkov (layout verification).
2. Úspešný nákupný proces a presmerovanie na obrazovku náhľadu PDF životopisu.
3. Overenie deaktivácie tlačidiel počas nákupu (double-tap prevention).
4. Správne zobrazenie chýb (napr. chyba siete, zamietnutie platby).
5. Správne správanie pri tichom zrušení nákupu (žiadny otravný SnackBar pre používateľa).
6. Spracovanie čakajúcej platby (Payment pending).
7. Úspešná a neúspešná obnova predchádzajúcich nákupov (Restore purchases).

### Spustenie testov:
```bash
flutter test
```

---

## 🚀 Spustenie a Vývoj

1. Získanie závislostí:
   ```bash
   flutter pub get
   ```
2. Spustenie aplikácie (vyžaduje pripojené zariadenie alebo emulátor):
   ```bash
   flutter run
   ```
