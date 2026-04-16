import 'package:isar/isar.dart';

part 'patient_package.g.dart';

/// Encrypted personal data for a patient.
@collection
class PatientPackage {
  /// Unique identifier managed by Isar.
  Id id = Isar.autoIncrement;

  /// Unique identifier for the patient.
  @Index(unique: true)
  late String patientId;

  /// Encrypted personal identity information.
  String? encryptedPersonalInfo;

  /// Encrypted medical history.
  String? encryptedMedicalHistory;

  /// Encrypted emergency contacts.
  String? encryptedEmergencyContacts;

  /// Encrypted insurance information.
  String? encryptedInsuranceInfo;

  /// Hash of the encryption key for verification.
  late String encryptionKeyHash;

  /// Timestamp of the last update.
  late DateTime lastUpdated;

  /// Timestamp when consent expires.
  DateTime? consentExpiry;

  PatientPackage({
    required this.patientId,
    this.encryptedPersonalInfo,
    this.encryptedMedicalHistory,
    this.encryptedEmergencyContacts,
    this.encryptedInsuranceInfo,
    required this.encryptionKeyHash,
    DateTime? lastUpdated,
    this.consentExpiry,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}
