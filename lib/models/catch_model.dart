import 'package:cloud_firestore/cloud_firestore.dart';

class FishCatch {
  final String? id;
  final String userId;
  final String species;
  final String frenchName;
  final String family;
  final double confidence;
  final List<Map<String, dynamic>> top5;
  final String? imageBase64;
  final String? fishImageUrl;
  final DateTime timestamp;
  // Champs optionnels
  final double? sizecm;
  final double? weightkg;
  final String? location;
  final String? notes;

  const FishCatch({
    this.id,
    required this.userId,
    required this.species,
    required this.frenchName,
    required this.family,
    required this.confidence,
    required this.top5,
    this.imageBase64,
    this.fishImageUrl,
    required this.timestamp,
    this.sizecm,
    this.weightkg,
    this.location,
    this.notes,
  });

  FishCatch copyWith({
    double? sizecm,
    double? weightkg,
    String? location,
    String? notes,
  }) => FishCatch(
    id: id,
    userId: userId,
    species: species,
    frenchName: frenchName,
    family: family,
    confidence: confidence,
    top5: top5,
    imageBase64: imageBase64,
    fishImageUrl: fishImageUrl,
    timestamp: timestamp,
    sizecm: sizecm ?? this.sizecm,
    weightkg: weightkg ?? this.weightkg,
    location: location ?? this.location,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toFirestore() => {
    'userId':       userId,
    'species':      species,
    'frenchName':   frenchName,
    'family':       family,
    'confidence':   confidence,
    'top5':         top5,
    'imageBase64':  imageBase64,
    'fishImageUrl': fishImageUrl,
    'timestamp':    Timestamp.fromDate(timestamp),
    if (sizecm != null)   'sizecm':   sizecm,
    if (weightkg != null) 'weightkg': weightkg,
    if (location != null) 'location': location,
    if (notes != null)    'notes':    notes,
  };

  factory FishCatch.fromFirestore(String id, Map<String, dynamic> d) => FishCatch(
    id:           id,
    userId:       d['userId'] as String? ?? 'demo_user',
    species:      d['species'] as String? ?? '',
    frenchName:   d['frenchName'] as String? ?? '',
    family:       d['family'] as String? ?? '',
    confidence:   (d['confidence'] as num?)?.toDouble() ?? 0,
    top5:         (d['top5'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ?? [],
    imageBase64:  d['imageBase64'] as String?,
    fishImageUrl: d['fishImageUrl'] as String?,
    timestamp:    (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    sizecm:       (d['sizecm'] as num?)?.toDouble(),
    weightkg:     (d['weightkg'] as num?)?.toDouble(),
    location:     d['location'] as String?,
    notes:        d['notes'] as String?,
  );
}
