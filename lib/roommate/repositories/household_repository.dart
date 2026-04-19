import '../models/household_member.dart';

abstract class HouseholdRepository {
  Stream<List<HouseholdMember>> watchHouseholdMembers(String householdId);
}
