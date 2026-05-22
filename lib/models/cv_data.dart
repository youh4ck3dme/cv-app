
class PersonalInfo {
  final String fullName;
  final String title;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String github;
  final String birthDate;
  final String drivingLicense;

  PersonalInfo({
    required this.fullName,
    required this.title,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.github,
    required this.birthDate,
    required this.drivingLicense,
  });

  factory PersonalInfo.empty() {
    return PersonalInfo(
      fullName: '',
      title: '',
      email: '',
      phone: '',
      location: '',
      linkedin: '',
      github: '',
      birthDate: '',
      drivingLicense: '',
    );
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      linkedin: json['linkedin'] ?? '',
      github: json['github'] ?? '',
      birthDate: json['birthDate'] ?? '',
      drivingLicense: json['drivingLicense'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'title': title,
      'email': email,
      'phone': phone,
      'location': location,
      'linkedin': linkedin,
      'github': github,
      'birthDate': birthDate,
      'drivingLicense': drivingLicense,
    };
  }
}

class Experience {
  final String id;
  final String company;
  final String role;
  final String period;
  final String? rawText;
  final List<String> bullets;

  Experience({
    required this.id,
    required this.company,
    required this.role,
    required this.period,
    this.rawText,
    required this.bullets,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? '',
      company: json['company'] ?? '',
      role: json['role'] ?? '',
      period: json['period'] ?? '',
      rawText: json['rawText'],
      bullets: List<String>.from(json['bullets'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'role': role,
      'period': period,
      'rawText': rawText,
      'bullets': bullets,
    };
  }
}

class Education {
  final String id;
  final String school;
  final String field;
  final String period;

  Education({
    required this.id,
    required this.school,
    required this.field,
    required this.period,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] ?? '',
      school: json['school'] ?? '',
      field: json['field'] ?? '',
      period: json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school': school,
      'field': field,
      'period': period,
    };
  }
}

class SkillGroup {
  final String id;
  final String label;
  final List<String> tags;

  SkillGroup({
    required this.id,
    required this.label,
    required this.tags,
  });

  factory SkillGroup.fromJson(Map<String, dynamic> json) {
    return SkillGroup(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'tags': tags,
    };
  }
}

class Language {
  final String id;
  final String name;
  final String level;
  final int dots;

  Language({
    required this.id,
    required this.name,
    required this.level,
    required this.dots,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      level: json['level'] ?? '',
      dots: (json['dots'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'dots': dots,
    };
  }
}

class Project {
  final String id;
  final String name;
  final String description;
  final String period;
  final List<String> technologies;
  final String? url;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.period,
    required this.technologies,
    this.url,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      period: json['period'] ?? '',
      technologies: List<String>.from(json['technologies'] ?? []),
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'period': period,
      'technologies': technologies,
      'url': url,
    };
  }
}

class Certificate {
  final String id;
  final String name;
  final String issuer;
  final String date;
  final String? url;

  Certificate({
    required this.id,
    required this.name,
    required this.issuer,
    required this.date,
    this.url,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      date: json['date'] ?? '',
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'date': date,
      'url': url,
    };
  }
}

class Interest {
  final String id;
  final String name;
  final String? description;

  Interest({
    required this.id,
    required this.name,
    this.description,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class Reference {
  final String id;
  final String name;
  final String position;
  final String company;
  final String email;
  final String phone;

  Reference({
    required this.id,
    required this.name,
    required this.position,
    required this.company,
    required this.email,
    required this.phone,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      company: json['company'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'company': company,
      'email': email,
      'phone': phone,
    };
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String date;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
    };
  }
}

class CustomSection {
  final String id;
  final String title;
  final String content;
  final int order;

  CustomSection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });

  factory CustomSection.fromJson(Map<String, dynamic> json) {
    return CustomSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
    };
  }
}

class CVData {
  final PersonalInfo personalInfo;
  final String about;
  final List<Experience> experience;
  final List<Education> education;
  final List<SkillGroup> skills;
  final List<Language> languages;
  final List<Project> projects;
  final List<Certificate> certificates;
  final List<Interest> interests;
  final List<Reference> references;
  final List<Achievement> achievements;
  final List<CustomSection> customSections;
  final String selectedTemplate; // 'minimalist', 'modern-dark', 'executive'
  final String selectedLanguage; // 'sk', 'en'

  CVData({
    required this.personalInfo,
    required this.about,
    required this.experience,
    required this.education,
    required this.skills,
    required this.languages,
    required this.projects,
    required this.certificates,
    required this.interests,
    required this.references,
    required this.achievements,
    required this.customSections,
    required this.selectedTemplate,
    required this.selectedLanguage,
  });

  factory CVData.empty() {
    return CVData(
      personalInfo: PersonalInfo.empty(),
      about: '',
      experience: [],
      education: [],
      skills: [],
      languages: [],
      projects: [],
      certificates: [],
      interests: [],
      references: [],
      achievements: [],
      customSections: [],
      selectedTemplate: 'minimalist',
      selectedLanguage: 'sk',
    );
  }

  factory CVData.fromJson(Map<String, dynamic> json) {
    return CVData(
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'])
          : PersonalInfo.empty(),
      about: json['about'] ?? '',
      experience: (json['experience'] as List? ?? [])
          .map((item) => Experience.fromJson(item))
          .toList(),
      education: (json['education'] as List? ?? [])
          .map((item) => Education.fromJson(item))
          .toList(),
      skills: (json['skills'] as List? ?? [])
          .map((item) => SkillGroup.fromJson(item))
          .toList(),
      languages: (json['languages'] as List? ?? [])
          .map((item) => Language.fromJson(item))
          .toList(),
      projects: (json['projects'] as List? ?? [])
          .map((item) => Project.fromJson(item))
          .toList(),
      certificates: (json['certificates'] as List? ?? [])
          .map((item) => Certificate.fromJson(item))
          .toList(),
      interests: (json['interests'] as List? ?? [])
          .map((item) => Interest.fromJson(item))
          .toList(),
      references: (json['references'] as List? ?? [])
          .map((item) => Reference.fromJson(item))
          .toList(),
      achievements: (json['achievements'] as List? ?? [])
          .map((item) => Achievement.fromJson(item))
          .toList(),
      customSections: (json['customSections'] as List? ?? [])
          .map((item) => CustomSection.fromJson(item))
          .toList(),
      selectedTemplate: json['selectedTemplate'] ?? 'minimalist',
      selectedLanguage: json['selectedLanguage'] ?? 'sk',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalInfo': personalInfo.toJson(),
      'about': about,
      'experience': experience.map((item) => item.toJson()).toList(),
      'education': education.map((item) => item.toJson()).toList(),
      'skills': skills.map((item) => item.toJson()).toList(),
      'languages': languages.map((item) => item.toJson()).toList(),
      'projects': projects.map((item) => item.toJson()).toList(),
      'certificates': certificates.map((item) => item.toJson()).toList(),
      'interests': interests.map((item) => item.toJson()).toList(),
      'references': references.map((item) => item.toJson()).toList(),
      'achievements': achievements.map((item) => item.toJson()).toList(),
      'customSections': customSections.map((item) => item.toJson()).toList(),
      'selectedTemplate': selectedTemplate,
      'selectedLanguage': selectedLanguage,
    };
  }
}
