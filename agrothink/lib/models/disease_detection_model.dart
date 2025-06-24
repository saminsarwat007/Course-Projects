class DiseaseDetectionModel {
  final String id;
  final String imagePath;
  final String cropType;
  final String diseaseName;
  final String description;
  final List<String> treatments;
  final DateTime detectedAt;
  final String detectedBy;

  DiseaseDetectionModel({
    required this.id,
    required this.imagePath,
    required this.cropType,
    required this.diseaseName,
    required this.description,
    required this.treatments,
    required this.detectedAt,
    required this.detectedBy,
  });

  // Create a disease detection result from Firebase data
  factory DiseaseDetectionModel.fromMap(Map<String, dynamic> map) {
    return DiseaseDetectionModel(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      cropType: map['cropType'] ?? '',
      diseaseName: map['diseaseName'] ?? '',
      description: map['description'] ?? '',
      treatments: List<String>.from(map['treatments'] ?? []),
      detectedAt:
          map['detectedAt'] != null
              ? (map['detectedAt'] as DateTime)
              : DateTime.now(),
      detectedBy: map['detectedBy'] ?? '',
    );
  }

  // Convert disease detection result to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'cropType': cropType,
      'diseaseName': diseaseName,
      'description': description,
      'treatments': treatments,
      'detectedAt': detectedAt,
      'detectedBy': detectedBy,
    };
  }

  // Mock data generator for UI development
  static List<DiseaseDetectionModel> getMockData() {
    return [
      DiseaseDetectionModel(
        id: '1',
        imagePath: 'assets/sample_image_1.jpg',
        cropType: 'Rice',
        diseaseName: 'Bacterial Leaf Blight',
        description:
            'A bacterial disease that produces grey-green water-soaked lesions on leaves, which later turn yellow to straw-colored.',
        treatments: [
          'Use disease-resistant rice varieties',
          'Apply copper-based fungicides',
          'Ensure proper drainage in fields',
          'Remove infected plants',
        ],
        detectedAt: DateTime.now().subtract(const Duration(days: 2)),
        detectedBy: 'user123',
      ),
      DiseaseDetectionModel(
        id: '2',
        imagePath: 'assets/sample_image_2.jpg',
        cropType: 'Tomato',
        diseaseName: 'Early Blight',
        description:
            'A fungal disease causing dark spots with concentric rings on lower leaves first.',
        treatments: [
          'Rotate crops annually',
          'Apply fungicides early in season',
          'Ensure proper plant spacing',
          'Remove infected leaves',
        ],
        detectedAt: DateTime.now().subtract(const Duration(days: 5)),
        detectedBy: 'user456',
      ),
      DiseaseDetectionModel(
        id: '3',
        imagePath: 'assets/sample_image_3.jpg',
        cropType: 'Wheat',
        diseaseName: 'Powdery Mildew',
        description:
            'A fungal disease that appears as white powdery spots on leaves and stems.',
        treatments: [
          'Apply sulfur-based fungicides',
          'Plant resistant varieties',
          'Increase air circulation',
          'Avoid overhead irrigation',
        ],
        detectedAt: DateTime.now().subtract(const Duration(days: 7)),
        detectedBy: 'user789',
      ),
    ];
  }
}
