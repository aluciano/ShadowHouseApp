import 'game_card.dart';
import 'player_type.dart';

class Player {
  Player({
    required this.id,
    required this.name,
    required this.type,
    required this.hand,
    required this.playedCards,
    this.score = 0,
    this.isAccomplice = false,
    this.hasHandcuffs = false,
  });

  final String id;
  final String name;
  final PlayerType type;

  final List<GameCard> hand;
  final List<GameCard> playedCards;

  int score;
  bool isAccomplice;
  bool hasHandcuffs;
}