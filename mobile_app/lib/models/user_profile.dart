class UserProfile {
  int healthPoints;
  int currentStreak; // days staying within good AQI
  String rank;

  UserProfile({
    this.healthPoints = 1250,
    this.currentStreak = 5,
    this.rank = 'Clean Air Champion',
  });

  void addPoints(int points) {
    healthPoints += points;
    _updateRank();
  }

  void _updateRank() {
    if (healthPoints > 2000) {
      rank = 'Air Quality Master';
    } else if (healthPoints > 1000) {
      rank = 'Clean Air Champion';
    } else if (healthPoints > 500) {
      rank = 'Eco Defender';
    } else {
      rank = 'Novice Explorer';
    }
  }
}

// Global instance for hackathon demo
final UserProfile currentUserProfile = UserProfile();
