/// Structured user attributes for offer targeting and personalization.
///
/// All fields are optional -- pass only what you have available.
///
/// ```dart
/// final attrs = UserAttributes(
///   email: 'user@example.com',
///   firstName: 'Jane',
///   subscriptionTier: 'premium',
/// );
/// Encore.shared.identify(userId: 'user_123', attributes: attrs);
/// ```
class UserAttributes {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? postalCode;
  final String? city;
  final String? state;
  final String? countryCode;
  final String? latitude;
  final String? longitude;
  final String? dateOfBirth;
  final String? gender;
  final String? language;
  final String? subscriptionTier;
  final String? monthsSubscribed;
  final String? billingCycle;
  final String? lastPaymentAmount;
  final String? lastActiveDate;
  final String? totalSessions;
  final Map<String, String> custom;

  const UserAttributes({
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.postalCode,
    this.city,
    this.state,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.gender,
    this.language,
    this.subscriptionTier,
    this.monthsSubscribed,
    this.billingCycle,
    this.lastPaymentAmount,
    this.lastActiveDate,
    this.totalSessions,
    this.custom = const {},
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (email != null) 'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (postalCode != null) 'postalCode': postalCode,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (countryCode != null) 'countryCode': countryCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (language != null) 'language': language,
      if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
      if (monthsSubscribed != null) 'monthsSubscribed': monthsSubscribed,
      if (billingCycle != null) 'billingCycle': billingCycle,
      if (lastPaymentAmount != null) 'lastPaymentAmount': lastPaymentAmount,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate,
      if (totalSessions != null) 'totalSessions': totalSessions,
      if (custom.isNotEmpty) 'custom': custom,
    };
  }
}
