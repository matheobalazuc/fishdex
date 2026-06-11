import 'package:cloud_firestore/cloud_firestore.dart';

class FishCatch {
  final String? id;
  final String userId;
  final String userName;
  final String species;
  final String frenchName;
  final String family;
  final double confidence;
  final List<Map<String, dynamic>> top5;
  final String? imageBase64;
  final String? fishImageUrl;
  final DateTime timestamp;
  final double? sizecm;
  final double? weightkg;
  final String? location;
  final String? notes;
  final bool isPublished;
  final bool isPrivate;
  // Social (gérés par SocialService, jamais écrasés via toFirestore)
  final List<String> likedBy;
  final int commentsCount;

  const FishCatch({
    this.id,
    required this.userId,
    this.userName = 'Pêcheur',
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
    this.isPublished = false,
    this.isPrivate = false,
    this.likedBy = const [],
    this.commentsCount = 0,
  });

  FishCatch copyWith({
    String? species,
    String? frenchName,
    String? family,
    double? confidence,
    String? imageBase64,
    String? fishImageUrl,
    double? sizecm,
    double? weightkg,
    String? location,
    String? notes,
    bool? isPublished,
    bool? isPrivate,
    List<String>? likedBy,
    int? commentsCount,
    bool clearImage    = false,
    bool clearSize     = false,
    bool clearWeight   = false,
    bool clearLocation = false,
    bool clearNotes    = false,
  }) => FishCatch(
    id:           id,
    userId:       userId,
    userName:     userName,
    species:      species      ?? this.species,
    frenchName:   frenchName   ?? this.frenchName,
    family:       family       ?? this.family,
    confidence:   confidence   ?? this.confidence,
    top5:         top5,
    imageBase64:  clearImage   ? null : (imageBase64  ?? this.imageBase64),
    fishImageUrl: fishImageUrl ?? this.fishImageUrl,
    timestamp:    timestamp,
    sizecm:       clearSize    ? null : (sizecm   ?? this.sizecm),
    weightkg:     clearWeight  ? null : (weightkg ?? this.weightkg),
    location:     clearLocation? null : (location ?? this.location),
    notes:        clearNotes   ? null : (notes    ?? this.notes),
    isPublished:  isPublished  ?? this.isPublished,
    isPrivate:    isPrivate    ?? this.isPrivate,
    likedBy:      likedBy      ?? this.likedBy,
    commentsCount:commentsCount?? this.commentsCount,
  );

  // likedBy / commentsCount gérés par SocialService → non inclus ici
  Map<String, dynamic> toFirestore() => {
    'userId':       userId,
    'userName':     userName,
    'species':      species,
    'frenchName':   frenchName,
    'family':       family,
    'confidence':   confidence,
    'top5':         top5,
    'imageBase64':  imageBase64,
    'fishImageUrl': fishImageUrl,
    'timestamp':    Timestamp.fromDate(timestamp),
    'isPublished':  isPublished,
    'isPrivate':    isPrivate,
    if (sizecm   != null) 'sizecm':   sizecm,
    if (weightkg != null) 'weightkg': weightkg,
    if (location != null) 'location': location,
    if (notes    != null) 'notes':    notes,
  };

  factory FishCatch.fromFirestore(String id, Map<String, dynamic> d) => FishCatch(
    id:           id,
    userId:       d['userId']    as String? ?? '',
    userName:     d['userName']  as String? ?? 'Pêcheur',
    species:      d['species']   as String? ?? '',
    frenchName:   d['frenchName']as String? ?? '',
    family:       d['family']    as String? ?? '',
    confidence:   (d['confidence'] as num?)?.toDouble() ?? 0,
    top5:         (d['top5'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ?? [],
    imageBase64:  d['imageBase64']  as String?,
    fishImageUrl: d['fishImageUrl'] as String?,
    timestamp:    (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    sizecm:       (d['sizecm']   as num?)?.toDouble(),
    weightkg:     (d['weightkg'] as num?)?.toDouble(),
    location:     d['location']  as String?,
    notes:        d['notes']     as String?,
    isPublished:  d['isPublished'] as bool? ?? false,
    isPrivate:    d['isPrivate']   as bool? ?? false,
    likedBy:      List<String>.from(d['likedBy'] as List? ?? []),
    commentsCount:(d['commentsCount'] as num?)?.toInt() ?? 0,
  );
}
