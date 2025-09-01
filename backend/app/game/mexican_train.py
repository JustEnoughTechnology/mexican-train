from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
import random
import uuid
import time
import logging
from app.core.ai_config import ai_config

class TrainType(str, Enum):
    PERSONAL = "personal"
    MEXICAN = "mexican"

@dataclass
class Domino:
    left: int
    right: int
    id: str = None
    
    def __post_init__(self):
        if self.id is None:
            self.id = str(uuid.uuid4())
    
    def matches(self, value: int) -> bool:
        return self.left == value or self.right == value
    
    def flip(self) -> 'Domino':
        return Domino(self.right, self.left, self.id)
    
    def value(self) -> int:
        return self.left + self.right
    
    def is_double(self) -> bool:
        return self.left == self.right

@dataclass
class Train:
    train_type: TrainType
    owner_id: Optional[str]
    dominoes: List[Domino]
    is_open: bool = False
    needs_double_satisfaction: bool = False
    
    def get_end_value(self) -> Optional[int]:
        if not self.dominoes:
            return None
        return self.dominoes[-1].right
    
    def can_play_domino(self, domino: Domino, required_value: int) -> bool:
        return domino.matches(required_value)
    
    def add_domino(self, domino: Domino, required_value: int) -> bool:
        if not self.can_play_domino(domino, required_value):
            return False
        
        # Orient domino correctly
        if domino.left == required_value:
            self.dominoes.append(domino)
        else:
            self.dominoes.append(domino.flip())
        
        # Handle double satisfaction
        if domino.is_double():
            self.needs_double_satisfaction = True
        else:
            self.needs_double_satisfaction = False
        
        return True

class MexicanTrainMatch:
    """A Mexican Train Match contains multiple games and tracks overall scoring"""
    
    def __init__(self, match_id: str, players: List[str], config: Dict = None):
        self.match_id = match_id
        self.players = players
        self.ai_players: List[str] = []
        self.spectators: List[str] = []
        self.created_at = time.time()
        self.logger = logging.getLogger(f"MexicanTrainMatch.{match_id}")
        
        # Match configuration
        self.config = config or {}
        self.name = self.config.get("name", f"Match {match_id}")
        self.description = self.config.get("description", "")
        self.host = self.config.get("host", players[0] if players else "Unknown")
        self.max_players = min(max(self.config.get("max_players", 4), 1), 8)
        self.min_players = min(max(self.config.get("min_players", 2), 1), self.max_players)
        self.allow_spectators = self.config.get("allow_spectators", True)
        self.visibility = self.config.get("visibility", "public")
        self.password = self.config.get("password", None)
        
        # AI configuration
        self.ai_enabled = self.config.get("ai_enabled", True)
        self.ai_skill_level = min(max(self.config.get("ai_skill_level", 1), 1), 5)  # 1-5 skill levels
        self.ai_fill_to_max = self.config.get("ai_fill_to_max", True)
        
        # Timer configuration
        self.countdown_minutes = self.config.get("countdown_minutes", 10)
        self.countdown_start_time = None
        self.auto_start_scheduled = False
        
        # Match settings
        self.max_domino = self.config.get("max_domino", 12)  # Double-12 set by default
        self.games_to_play = self.config.get("games_to_play", 13)  # Traditional: 12 down to 0 + bonus rounds
        
        # Match state
        self.match_started = False
        self.match_completed = False
        self.current_game_number = 1
        self.games_played = 0
        
        # NEW: Store all games within the match instead of separate entities
        self.games: List['MexicanTrainGame'] = []  # All games played in this match
        self.current_game: Optional['MexicanTrainGame'] = None  # Currently active game
        
        # Match scoring - tracks scores across all games
        self.match_scores: Dict[str, int] = {player: 0 for player in self.players}
        
        # Match statistics for analytics
        self.match_stats = {
            "total_dominoes_played": 0,
            "total_turns_taken": 0,
            "games_won_by_player": {player: 0 for player in self.players},
            "lowest_scoring_game": None,
            "highest_scoring_game": None,
            "longest_game": None,
            "shortest_game": None,
            "most_dominoes_in_hand_at_end": 0,
            "total_match_duration": 0
        }
        
    def start_match(self) -> Dict:
        """Start the match and create the first game"""
        if self.match_started:
            return {"success": False, "error": "Match already started"}
            
        # Add AI players if needed
        if self.ai_enabled and self.ai_fill_to_max:
            self._add_ai_players_to_max()
            
        self.match_started = True
        
        # Initialize match scores for all players (including AI)
        self.match_scores = {player: 0 for player in self.players}
        
        # Start first game
        return self.start_next_game()
    
    def start_next_game(self) -> Dict:
        """Start the next game in the match"""
        if self.current_game_number > self.games_to_play:
            return self._complete_match()
            
        # Create new game with internal ID (not exposed as separate entity)
        internal_game_id = f"internal_game_{self.current_game_number}"
        game_config = self.config.copy()
        game_config["is_match_game"] = True
        game_config["game_number"] = self.current_game_number
        game_config["match_id"] = self.match_id
        game_config["verbose"] = self.config.get("verbose", True)
        
        # Create game and add it to the match's games list
        new_game = MexicanTrainGame(internal_game_id, self.players.copy(), self.max_domino, game_config)
        new_game.ai_players = self.ai_players.copy()
        new_game.spectators = self.spectators.copy()
        
        # Start the game
        result = new_game.start_game(force_start=True)
        
        if result["success"]:
            self.current_game = new_game
            self.games.append(new_game)  # Store in match's game list
            
            self.logger.info(f"Started game {self.current_game_number} of {self.games_to_play} in match {self.match_id}")
            return {
                "success": True,
                "message": f"Started game {self.current_game_number} of {self.games_to_play}",
                "game_number": self.current_game_number,
                "match_state": self.get_match_state()
            }
        else:
            return result
    
    def complete_current_game(self, game_scores: Dict[str, int]) -> Dict:
        """Complete the current game and update match scores"""
        if not self.current_game:
            return {"success": False, "error": "No active game"}
            
        completed_game = self.current_game
        
        # Add game scores to match totals
        for player, score in game_scores.items():
            if player in self.match_scores:
                self.match_scores[player] += score
        
        # Find winner and update statistics
        winner = min(game_scores.keys(), key=lambda p: game_scores[p])
        if winner in self.match_stats["games_won_by_player"]:
            self.match_stats["games_won_by_player"][winner] += 1
        
        # Update match statistics
        game_state = completed_game.get_game_state()
        self.match_stats["total_dominoes_played"] += game_state.get("dominoes_played", 0)
        self.match_stats["total_turns_taken"] += game_state.get("turns_taken", 0)
        
        # Track game duration and scoring statistics
        game_duration = game_state.get("game_duration", 0)
        total_game_score = sum(game_scores.values())
        max_dominoes_at_end = max([len(game_state.get("player_hands", {}).get(p, [])) for p in game_scores.keys()] or [0])
        
        self.match_stats["most_dominoes_in_hand_at_end"] = max(
            self.match_stats["most_dominoes_in_hand_at_end"], 
            max_dominoes_at_end
        )
        
        # Track lowest/highest scoring games
        if not self.match_stats["lowest_scoring_game"] or total_game_score < self.match_stats["lowest_scoring_game"]["total_score"]:
            self.match_stats["lowest_scoring_game"] = {
                "game_number": self.current_game_number,
                "total_score": total_game_score,
                "scores": game_scores.copy()
            }
            
        if not self.match_stats["highest_scoring_game"] or total_game_score > self.match_stats["highest_scoring_game"]["total_score"]:
            self.match_stats["highest_scoring_game"] = {
                "game_number": self.current_game_number,
                "total_score": total_game_score,
                "scores": game_scores.copy()
            }
        
        # Track longest/shortest games
        if not self.match_stats["longest_game"] or game_duration > self.match_stats["longest_game"]["duration"]:
            self.match_stats["longest_game"] = {
                "game_number": self.current_game_number,
                "duration": game_duration,
                "winner": winner
            }
            
        if not self.match_stats["shortest_game"] or game_duration < self.match_stats["shortest_game"]["duration"]:
            self.match_stats["shortest_game"] = {
                "game_number": self.current_game_number,
                "duration": game_duration,
                "winner": winner
            }
        
        # Mark current game as completed (but keep it in the games list)
        completed_game.completed_at = time.time()
        completed_game.final_scores = game_scores.copy()
        
        self.current_game_number += 1
        self.games_played += 1
        self.current_game = None
        
        # Check if match is complete
        if self.current_game_number > self.games_to_play:
            return self._complete_match()
        else:
            # Start next game
            return self.start_next_game()
    
    def is_match_complete(self) -> bool:
        """Check if the match is complete"""
        return self.match_completed or self.games_played >= self.games_to_play
    
    def _complete_match(self) -> Dict:
        """Complete the match and determine winner"""
        self.match_completed = True
        
        # Calculate final match duration
        self.match_stats["total_match_duration"] = time.time() - self.created_at
        
        # Determine match winner
        winner = min(self.match_scores.keys(), key=lambda p: self.match_scores[p])
        
        # Calculate final analytics
        final_analytics = {
            "match_winner": winner,
            "total_games_played": len(self.games),
            "match_duration_minutes": round(self.match_stats["total_match_duration"] / 60, 2),
            "average_game_duration": round(self.match_stats["total_match_duration"] / len(self.games) / 60, 2) if self.games else 0,
            "most_games_won": max(self.match_stats["games_won_by_player"].items(), key=lambda x: x[1]),
            "lowest_final_score": min(self.match_scores.items(), key=lambda x: x[1]),
            "highest_final_score": max(self.match_scores.items(), key=lambda x: x[1]),
        }
        
        # Add celebration data for frontend
        celebration_data = {
            "match_winner": winner,
            "winning_score": self.match_scores[winner],
            "margin_of_victory": sorted(self.match_scores.values())[1] - self.match_scores[winner] if len(self.match_scores) > 1 else 0,
            "games_won": self.match_stats["games_won_by_player"][winner],
            "notable_achievements": self._get_notable_achievements()
        }
        
        return {
            "success": True,
            "match_completed": True,
            "winner": winner,
            "final_scores": self.match_scores.copy(),
            "match_analytics": final_analytics,
            "celebration_data": celebration_data,
            "match_statistics": self.match_stats
        }
    
    def _get_notable_achievements(self) -> List[str]:
        """Get notable achievements for match celebration"""
        achievements = []
        
        if self.match_stats["longest_game"]:
            achievements.append(f"Longest game: Game #{self.match_stats['longest_game']['game_number']} lasting {self.match_stats['longest_game']['duration']:.1f} minutes")
        
        if self.match_stats["shortest_game"]:
            achievements.append(f"Quickest victory: Game #{self.match_stats['shortest_game']['game_number']} in {self.match_stats['shortest_game']['duration']:.1f} minutes")
        
        if self.match_stats["lowest_scoring_game"]:
            low_game = self.match_stats["lowest_scoring_game"]
            achievements.append(f"Lowest scoring game: Game #{low_game['game_number']} with {low_game['total_score']} total points")
        
        if self.match_stats["highest_scoring_game"]:
            high_game = self.match_stats["highest_scoring_game"]
            achievements.append(f"Highest scoring game: Game #{high_game['game_number']} with {high_game['total_score']} total points")
        
        if self.match_stats["most_dominoes_in_hand_at_end"] > 10:
            achievements.append(f"Most dominoes held at game end: {self.match_stats['most_dominoes_in_hand_at_end']} dominoes")
        
        return achievements
    
    def _add_ai_players_to_max(self):
        """Add AI players to fill match to max capacity"""
        ai_names = [
            "Sleepy_Caboose", "Slow_Freight", "Local_Express", "Fast_Passenger", "Locomotive_Legend"
        ]
        
        current_total = len(self.players) + len(self.ai_players)
        ai_needed = self.max_players - current_total
        
        for i in range(ai_needed):
            if i < len(ai_names):
                ai_name = ai_names[i]
                self.ai_players.append(ai_name)
                self.players.append(ai_name)
                self.logger.info(f"Added AI player: {ai_name} (Level {self.ai_skill_level})")
    
    def get_match_state(self, requesting_player: str = None) -> Dict:
        """Get current match state with all games and analytics"""
        # Build game history from the stored games list
        game_history = []
        for i, game in enumerate(self.games):
            if hasattr(game, 'final_scores'):  # Completed games
                game_history.append({
                    "game_number": i + 1,
                    "scores": game.final_scores,
                    "winner": min(game.final_scores.keys(), key=lambda p: game.final_scores[p]),
                    "completed_at": getattr(game, 'completed_at', None),
                    "duration": game.get_game_state().get("game_duration", 0)
                })
        
        return {
            "match_id": self.match_id,
            "name": self.name,
            "description": self.description,
            "host": self.host,
            "players": self.players,
            "ai_players": self.ai_players,
            "spectators": self.spectators,
            "match_started": self.match_started,
            "match_completed": self.match_completed,
            "current_game_number": self.current_game_number,
            "games_to_play": self.games_to_play,
            "games_played": self.games_played,
            "match_scores": self.match_scores,
            "game_history": game_history,
            "match_statistics": self.match_stats,  # New: Analytics data
            "current_game_state": self.current_game.get_game_state(requesting_player) if self.current_game else None,
            "max_players": self.max_players,
            "min_players": self.min_players,
            "allow_spectators": self.allow_spectators,
            "visibility": self.visibility,
            "created_at": self.created_at,
            "total_games": len(self.games)  # New: Total games stored in match
        }

class MexicanTrainGame:
    def __init__(self, game_id: str, players: List[str], max_domino: int = 12, config: Dict = None):
        self.game_id = game_id
        self.players = players
        self.ai_players: List[str] = []  # Track AI players separately
        self.max_domino = max_domino
        self.logger = logging.getLogger(f"MexicanTrainGame.{game_id}")
        # Remove old verbose system - now using logging
        # self.verbose = config.get('verbose', True) if config else True
        self.current_round = max_domino
        self.current_player_index = 0
        self.game_started = False  # Track if game has actually started with multiple players
        self.spectators: List[str] = []  # Track spectators (can watch but not play)
        
        # Game configuration
        self.config = config or {}
        self.name = self.config.get("name", f"Game {game_id}")
        self.description = self.config.get("description", "")
        self.host = self.config.get("host", players[0] if players else "Unknown")
        self.max_players = min(max(self.config.get("max_players", 4), 1), 8)  # Clamp to 1-8
        self.min_players = min(max(self.config.get("min_players", 2), 1), self.max_players)  # Clamp to 1-max
        self.allow_spectators = self.config.get("allow_spectators", True)
        self.visibility = self.config.get("visibility", "public")
        self.password = self.config.get("password", None)
        
        # AI configuration
        self.ai_enabled = self.config.get("ai_enabled", True)
        self.ai_skill_level = min(max(self.config.get("ai_skill_level", 1), 1), 3)  # Clamp to 1-3
        self.ai_fill_to_max = self.config.get("ai_fill_to_max", True)
        
        # Timer configuration
        self.countdown_minutes = self.config.get("countdown_minutes", 10)
        self.created_at = None  # Will be set when game is created
        self.countdown_start_time = None  # Will be set when countdown starts
        self.auto_start_scheduled = False
        
        # Game state
        self.dominoes_per_player = self._calculate_dominoes_per_player()
        self.boneyard: List[Domino] = []
        self.player_hands: Dict[str, List[Domino]] = {}
        self.trains: Dict[str, Train] = {}
        self.mexican_train: Optional[Train] = None
        self.engine_domino: Optional[Domino] = None
        
        # Doubles tracking
        self.unsatisfied_doubles: List[Tuple[str, str]] = []  # List of (train_type, train_owner) with unsatisfied doubles
        self.player_has_played_double: bool = False  # Track if current player played a double this turn
        
        # AI players will be added when game starts if enabled and fill_to_max is set
        
        # Round tracking - will include AI players when game starts
        self.round_scores: Dict[str, List[int]] = {player: [] for player in self.players}
        
        # setup_round() will be called when game starts
    
    def _add_ai_players_to_max(self):
        """Add AI players to fill the game to max capacity"""
        ai_names = [
            "AI_Express", "AI_Conductor", "AI_Engineer", "AI_Freight", 
            "AI_Thunder", "AI_Lightning", "AI_Steam", "AI_Diesel"
        ]
        
        current_total = len(self.players) + len(self.ai_players)
        ai_needed = self.max_players - current_total
        
        for i in range(ai_needed):
            if i < len(ai_names):
                ai_name = ai_names[i]
                self.ai_players.append(ai_name)
                self.players.append(ai_name)  # Add to main players list too
                self.logger.info(f"Added AI player: {ai_name} (Level {self.ai_skill_level})")
    
    def _calculate_dominoes_per_player(self) -> int:
        player_count = len(self.players)
        if player_count <= 2:
            return 16
        elif player_count <= 4:
            return 15
        elif player_count <= 6:
            return 12
        else:
            return 10
    
    def _create_domino_set(self) -> List[Domino]:
        dominoes = []
        for left in range(self.max_domino + 1):
            for right in range(left, self.max_domino + 1):
                dominoes.append(Domino(left, right))
        return dominoes
    
    def setup_round(self):
        # Create and shuffle dominoes
        all_dominoes = self._create_domino_set()
        random.shuffle(all_dominoes)
        
        # Deal to players first (so we can find highest double in hands)
        self.player_hands = {}
        for i, player in enumerate(self.players):
            start_idx = i * self.dominoes_per_player
            end_idx = start_idx + self.dominoes_per_player
            self.player_hands[player] = all_dominoes[start_idx:end_idx]
        
        # Find highest double among all player hands
        highest_double_value = -1
        starting_player = None
        engine_domino = None
        
        for player, hand in self.player_hands.items():
            for domino in hand:
                if domino.is_double() and domino.left > highest_double_value:
                    highest_double_value = domino.left
                    starting_player = player
                    engine_domino = domino
        
        # If no double found, use the highest value domino
        if engine_domino is None:
            highest_value = -1
            for player, hand in self.player_hands.items():
                for domino in hand:
                    total_value = domino.left + domino.right
                    if total_value > highest_value:
                        highest_value = total_value
                        starting_player = player
                        # Use the higher end as the engine value
                        engine_value = max(domino.left, domino.right)
                        engine_domino = Domino(engine_value, engine_value)  # Create a double
        
        # Set engine domino and current round value
        if engine_domino:
            if engine_domino.is_double():
                self.current_round = engine_domino.left
                self.engine_domino = engine_domino
                # Remove the actual engine domino from player's hand
                if starting_player:
                    if engine_domino in self.player_hands[starting_player]:
                        self.player_hands[starting_player].remove(engine_domino)
                    else:
                        self.logger.warning(f"Engine domino {engine_domino.left}-{engine_domino.right} not found in {starting_player}'s hand")
                    self.logger.debug(f"Engine: {engine_domino.left}-{engine_domino.right} from {starting_player}'s hand")
            else:
                # Create a double from highest single domino
                self.current_round = max(engine_domino.left, engine_domino.right)
                self.engine_domino = Domino(self.current_round, self.current_round)
                self.logger.debug(f"Engine: {self.current_round}-{self.current_round} (no doubles found)")
        else:
            # Fallback to double-12
            self.current_round = self.max_domino
            self.engine_domino = Domino(self.max_domino, self.max_domino)
            self.logger.debug(f"Engine: {self.max_domino}-{self.max_domino} (fallback)")
        
        # Set starting player
        if starting_player:
            self.current_player_index = self.players.index(starting_player)
            self.logger.info(f"Starting player: {starting_player} (had the highest double/value)")
        else:
            self.current_player_index = 0
            self.logger.info(f"Starting player: {self.players[0]} (default)")
        
        # Remaining dominoes go to boneyard (excluding dealt cards)
        dealt_count = len(self.players) * self.dominoes_per_player
        self.boneyard = all_dominoes[dealt_count:]
        
        # Remove engine domino from boneyard if it wasn't from a player's hand
        if not starting_player and self.engine_domino and self.engine_domino in self.boneyard:
            self.boneyard.remove(self.engine_domino)
        elif not starting_player and self.engine_domino:
            self.logger.warning(f"Engine domino {self.engine_domino.left}-{self.engine_domino.right} not found in boneyard")
        
        # Initialize trains
        self.trains = {}
        for player in self.players:
            self.trains[player] = Train(TrainType.PERSONAL, player, [])
        
        # Initialize Mexican Train (always open to all players)
        self.mexican_train = Train(TrainType.MEXICAN, None, [])
        self.mexican_train.is_open = True  # Mexican train is always open
    
    def get_current_player(self) -> str:
        return self.players[self.current_player_index]
    
    def get_valid_moves(self, player_id: str) -> List[Dict]:
        moves = []
        hand = self.player_hands.get(player_id, [])
        
        # If there are unsatisfied doubles, player can only play on those trains
        if self.has_unsatisfied_doubles():
            for domino in hand:
                moves.extend(self._get_moves_for_domino_doubles_only(player_id, domino))
        else:
            # Normal play - can play anywhere
            for domino in hand:
                moves.extend(self._get_moves_for_domino(player_id, domino))
        
        return moves
    
    def get_valid_moves_for_domino(self, player_id: str, domino: Domino) -> List[Dict]:
        """Get valid moves for a specific domino"""
        # Verify the domino is in the player's hand
        hand = self.player_hands.get(player_id, [])
        domino_in_hand = None
        for d in hand:
            if d.id == domino.id:
                domino_in_hand = d
                break
        
        if not domino_in_hand:
            self.logger.debug(f"Domino {domino.left}-{domino.right} (ID: {domino.id}) not found in {player_id}'s hand")
            return []
        
        return self._get_moves_for_domino(player_id, domino_in_hand)
    
    def _get_moves_for_domino(self, player_id: str, domino: Domino) -> List[Dict]:
        """Helper method to get all valid moves for a specific domino"""
        moves = []
        
        # Check personal train (always can play on your own train)
        if self._can_play_on_train(domino, self.trains[player_id], self.current_round):
            moves.append({
                "domino": domino,
                "train": "personal", 
                "train_owner": player_id
            })
        
        # Check other players' trains (only if they're open)
        for train_owner, train in self.trains.items():
            if train_owner != player_id and train.is_open:
                if self._can_play_on_train(domino, train, self.current_round):
                    moves.append({
                        "domino": domino,
                        "train": "personal",
                        "train_owner": train_owner
                    })
        
        # Check Mexican train  
        if self.mexican_train and self._can_play_on_train(domino, self.mexican_train, self.current_round):
            moves.append({
                "domino": domino,
                "train": "mexican",
                "train_owner": None
            })
        
        return moves
    
    def _get_moves_for_domino_doubles_only(self, player_id: str, domino: Domino) -> List[Dict]:
        """Get valid moves for a domino when there are unsatisfied doubles (restricted to double trains only)"""
        moves = []
        
        # Only allow moves on trains that have unsatisfied doubles
        for train_type, train_owner in self.unsatisfied_doubles:
            if train_type == "mexican":
                if self.mexican_train and self._can_play_on_train(domino, self.mexican_train, self.current_round):
                    moves.append({
                        "domino": domino,
                        "train": "mexican",
                        "train_owner": None
                    })
            elif train_type == "personal" and train_owner in self.trains:
                train = self.trains[train_owner]
                if self._can_play_on_train(domino, train, self.current_round):
                    moves.append({
                        "domino": domino,
                        "train": "personal",
                        "train_owner": train_owner
                    })
        
        return moves
    
    def _can_play_on_train(self, domino: Domino, train: Train, engine_value: int) -> bool:
        if not train.dominoes:
            # Empty train - must match engine
            return domino.matches(engine_value)
        else:
            # Must match end of train
            return domino.matches(train.get_end_value())
    
    async def make_ai_move(self, ai_player_name: str) -> Dict:
        """AI makes a move automatically using strategy based on skill level"""
        import random
        
        self.logger.debug(f"AI PLAYER {ai_player_name} MAKING MOVE (Level {self.ai_skill_level})")
        
        # Get all valid moves for the AI player
        valid_moves = self.get_valid_moves(ai_player_name)
        self.logger.debug(f"Found {len(valid_moves)} valid moves")
        
        if valid_moves:
            # Choose move based on AI skill level strategy
            chosen_move = self._choose_ai_move(ai_player_name, valid_moves)
            self.logger.debug(f"AI chose: {chosen_move['domino'].left}-{chosen_move['domino'].right} on {chosen_move['train']} train ({chosen_move.get('reason', 'no reason given')})")
            
            # Make the move
            result = self.make_move(
                ai_player_name,
                chosen_move['domino'],
                chosen_move['train'],
                chosen_move['train_owner']
            )
            
            if result['success']:
                self.logger.debug(f"AI successfully played domino")
            else:
                self.logger.debug(f"AI failed to play: {result.get('error')}")
            
            return result
        else:
            # No valid moves, must draw from boneyard
            self.logger.debug(f"No valid moves, drawing from boneyard")
            draw_result = self.draw_from_boneyard(ai_player_name)
            
            if draw_result['success'] and draw_result.get('can_play_drawn'):
                # AI drew a domino they can play - make the move immediately
                self.logger.debug(f"Drew domino: {draw_result['domino']['left']}-{draw_result['domino']['right']}")
                
                drawn_domino = Domino(
                    draw_result['domino']['left'],
                    draw_result['domino']['right'],
                    draw_result['domino']['id']
                )
                
                # Get valid moves for the drawn domino
                new_valid_moves = self._get_moves_for_domino(ai_player_name, drawn_domino)
                
                if new_valid_moves:
                    # Pick a move and play it
                    chosen_move = random.choice(new_valid_moves)
                    self.logger.debug(f"AI playing drawn domino on {chosen_move['train']} train")
                    
                    result = self.make_move(
                        ai_player_name,
                        chosen_move['domino'],
                        chosen_move['train'],
                        chosen_move['train_owner']
                    )
                    
                    if result['success']:
                        self.logger.debug(f"AI played drawn domino")
                    return result
            
            # Either draw failed, couldn't play drawn domino, or turn was already passed
            # The draw_from_boneyard method handles all the turn passing logic
            self.logger.debug(f"AI draw completed: {draw_result.get('message', 'Draw handled')}")
            return draw_result
    
    def _choose_ai_move(self, ai_player_name: str, valid_moves: List[Dict]) -> Dict:
        """Choose the best move based on AI skill level strategy using configurable system"""
        # Get strategy configuration for this AI level
        strategy = ai_config.get_strategy(self.ai_skill_level)
        
        if not strategy:
            # Fallback to random if no strategy configured
            chosen = random.choice(valid_moves)
            chosen['reason'] = 'no strategy configured - random fallback'
            return chosen
        
        return self._apply_strategy(ai_player_name, valid_moves, strategy)
    
    def _apply_strategy(self, ai_player_name: str, valid_moves: List[Dict], strategy: Dict) -> Dict:
        """Apply a configured strategy to choose the best move"""
        strategy_name = strategy.get('name', 'Unknown')
        tactics = strategy.get('tactics', [])
        
        if not tactics:
            # No tactics defined, fallback to random
            chosen = random.choice(valid_moves)
            chosen['reason'] = f'{strategy_name}: no tactics - random fallback'
            return chosen
        
        # Initialize scoring for all moves
        for move in valid_moves:
            move['score'] = 0.0
            move['reason_parts'] = []
        
        # Apply each tactic in priority order
        for tactic_config in sorted(tactics, key=lambda t: t.get('priority', 999)):
            tactic_name = tactic_config['name']
            tactic_weight = tactic_config.get('weight', 1.0)
            
            tactic_method = getattr(self, f'_tactic_{tactic_name}', None)
            if tactic_method:
                try:
                    tactic_method(ai_player_name, valid_moves, tactic_weight)
                except Exception as e:
                    self.logger.error(f"Error applying tactic {tactic_name}: {e}")
            else:
                self.logger.warning(f"Tactic '{tactic_name}' not implemented")
        
        # Choose the highest scoring move
        best_move = max(valid_moves, key=lambda m: m['score'])
        reason_text = f"{strategy_name}: " + ", ".join(best_move['reason_parts'])
        best_move['reason'] = reason_text
        
        return best_move
    
    # ========== AI TACTICS ==========
    
    def _tactic_random(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Apply random scoring to moves"""
        for move in valid_moves:
            move['score'] += random.random() * weight
            move['reason_parts'].append(f"random({weight:.1f})")
    
    def _tactic_maximize_pips(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer moves with higher pip counts to reduce penalties"""
        if not valid_moves:
            return
        
        max_pips = max(move['domino'].value() for move in valid_moves)
        for move in valid_moves:
            pip_score = (move['domino'].value() / max_pips) * weight if max_pips > 0 else 0
            move['score'] += pip_score
            if pip_score > 0:
                move['reason_parts'].append(f"max_pips({move['domino'].value()})")
    
    def _tactic_minimize_pips(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer moves with lower pip counts"""
        if not valid_moves:
            return
        
        min_pips = min(move['domino'].value() for move in valid_moves)
        max_pips = max(move['domino'].value() for move in valid_moves)
        for move in valid_moves:
            pip_score = ((max_pips - move['domino'].value()) / max_pips) * weight if max_pips > 0 else 0
            move['score'] += pip_score
            if pip_score > 0:
                move['reason_parts'].append(f"min_pips({move['domino'].value()})")
    
    def _tactic_prefer_own_train(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer playing on own train to keep it closed"""
        for move in valid_moves:
            if move['train'] == ai_player_name:
                move['score'] += weight
                move['reason_parts'].append(f"own_train({weight:.1f})")
    
    def _tactic_prefer_mexican_train(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer playing on the Mexican train"""
        for move in valid_moves:
            if move['train'] == 'mexican':
                move['score'] += weight
                move['reason_parts'].append(f"mexican({weight:.1f})")
    
    def _tactic_prefer_open_trains(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer playing on opponent's open trains"""
        for move in valid_moves:
            train_name = move['train']
            if (train_name != ai_player_name and train_name != 'mexican' and 
                train_name in self.trains and self.trains[train_name].is_open):
                move['score'] += weight
                move['reason_parts'].append(f"open_train({weight:.1f})")
    
    def _tactic_block_opponents(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Try to play dominoes that make it harder for opponents"""
        # Simple blocking: prefer uncommon numbers that opponents likely can't match
        for move in valid_moves:
            domino = move['domino']
            played_number = domino.right if move.get('flipped') else domino.left
            
            # Count how many dominoes in play have this number
            number_frequency = 0
            for player_id in self.players:
                if player_id != ai_player_name:  # Check opponents
                    for hand_domino in self.player_hands[player_id]:
                        if hand_domino.left == played_number or hand_domino.right == played_number:
                            number_frequency += 1
            
            # Lower frequency = better blocking potential
            blocking_score = weight * (1.0 / (number_frequency + 1))
            move['score'] += blocking_score
            if blocking_score > 0:
                move['reason_parts'].append(f"block({played_number})")
    
    def _tactic_preserve_doubles(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Avoid playing doubles unless necessary"""
        for move in valid_moves:
            if move['domino'].left == move['domino'].right:  # It's a double
                move['score'] -= weight  # Negative score to discourage
                move['reason_parts'].append(f"preserve_double(-{weight:.1f})")
    
    def _tactic_dump_doubles(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Play doubles when possible to avoid being stuck"""
        for move in valid_moves:
            if move['domino'].left == move['domino'].right:  # It's a double
                move['score'] += weight
                move['reason_parts'].append(f"dump_double({weight:.1f})")
    
    def _tactic_endgame_awareness(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Adjust strategy when few dominoes remain"""
        total_hand_size = sum(len(hand) for hand in self.player_hands.values())
        if total_hand_size <= 8:  # Endgame threshold
            # In endgame, prioritize getting rid of high-value dominoes
            max_pips = max(move['domino'].value() for move in valid_moves) if valid_moves else 0
            for move in valid_moves:
                if max_pips > 0:
                    endgame_score = (move['domino'].value() / max_pips) * weight
                    move['score'] += endgame_score
                    move['reason_parts'].append(f"endgame({move['domino'].value()})")
    
    def _tactic_hand_composition(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Consider overall hand makeup when choosing moves"""
        ai_hand = self.player_hands[ai_player_name]
        if not ai_hand:
            return
        
        # Count numbers in hand to see what we have most/least of
        number_counts = {}
        for domino in ai_hand:
            number_counts[domino.left] = number_counts.get(domino.left, 0) + 1
            number_counts[domino.right] = number_counts.get(domino.right, 0) + 1
        
        for move in valid_moves:
            domino = move['domino']
            # Numbers that will be exposed after playing this domino
            exposed_numbers = []
            if move.get('flipped'):
                exposed_numbers.append(domino.left)
            else:
                exposed_numbers.append(domino.right)
            
            # Prefer moves that expose numbers we have more of
            composition_score = 0
            for num in exposed_numbers:
                composition_score += number_counts.get(num, 0) * 0.5
            
            move['score'] += composition_score * weight
            if composition_score > 0:
                move['reason_parts'].append(f"hand_comp({composition_score:.1f})")
    
    def _tactic_chain_length(self, ai_player_name: str, valid_moves: List[Dict], weight: float) -> None:
        """Prefer moves that enable the longest chain of plays from current hand"""
        ai_hand = self.player_hands[ai_player_name]
        if not ai_hand:
            return
        
        max_chain_length = 0
        move_chain_lengths = {}
        
        for move in valid_moves:
            domino = move['domino']
            train_name = move['train']
            
            # Calculate what number would be exposed after playing this domino
            if move.get('flipped'):
                exposed_number = domino.left
            else:
                exposed_number = domino.right
            
            # Create a copy of the hand without this domino to simulate the move
            remaining_hand = [d for d in ai_hand if d != domino]
            
            # Calculate chain length from this position
            chain_length = self._calculate_chain_length(remaining_hand, exposed_number, train_name)
            move_chain_lengths[id(move)] = chain_length
            max_chain_length = max(max_chain_length, chain_length)
        
        # Score moves based on their chain length potential
        for move in valid_moves:
            chain_length = move_chain_lengths[id(move)]
            if max_chain_length > 0:
                chain_score = (chain_length / max_chain_length) * weight
                move['score'] += chain_score
                if chain_length > 0:
                    move['reason_parts'].append(f"chain({chain_length})")
    
    def _calculate_chain_length(self, hand: List, start_number: int, train_name: str) -> int:
        """Calculate the maximum number of dominoes that could be played in sequence"""
        if not hand:
            return 0
        
        max_length = 0
        
        # Try each domino that can connect to the start_number
        for i, domino in enumerate(hand):
            if domino.left == start_number or domino.right == start_number:
                # Determine what number would be exposed if we play this domino
                next_number = domino.right if domino.left == start_number else domino.left
                
                # Create remaining hand without this domino
                remaining_hand = hand[:i] + hand[i+1:]
                
                # Recursively calculate chain length from this position
                chain_length = 1 + self._calculate_chain_length(remaining_hand, next_number, train_name)
                max_length = max(max_length, chain_length)
        
        return max_length
    
    # ========== LEGACY AI METHODS (kept for backward compatibility) ==========
    
    def _ai_minimize_pips(self, valid_moves: List[Dict]) -> Dict:
        """Level 2 AI: Always play the domino with HIGHEST pip count to minimize penalties"""
        best_move = max(valid_moves, key=lambda move: move['domino'].value())
        best_move['reason'] = f'minimize penalties (playing {best_move["domino"].value()} pips)'
        return best_move
    
    def _ai_hand_management(self, ai_player_name: str, valid_moves: List[Dict]) -> Dict:
        """Level 3 AI: Hand management + train preference"""
        import random
        
        # Prefer playing on own train to keep it closed
        own_train_moves = [m for m in valid_moves if m['train'] == 'personal' and m['train_owner'] == ai_player_name]
        
        if own_train_moves:
            # Among own train moves, prefer getting rid of high pip dominoes  
            best_move = max(own_train_moves, key=lambda move: move['domino'].value())
            best_move['reason'] = 'own train + high pips'
            return best_move
        
        # If can't play on own train, get rid of highest pip domino
        best_move = max(valid_moves, key=lambda move: move['domino'].value())
        best_move['reason'] = 'get rid of heavy domino'
        return best_move
    
    def _ai_blocking_strategy(self, ai_player_name: str, valid_moves: List[Dict]) -> Dict:
        """Level 4 AI: Opponent awareness + strategic blocking"""
        import random
        
        # Check if in endgame (someone has ≤ 3 dominoes)
        min_hand_size = min(len(hand) for hand in self.player_hands.values())
        is_endgame = min_hand_size <= 3
        
        if is_endgame:
            self.logger.debug(f"AI detects endgame (min hand: {min_hand_size})")
            # In endgame, prioritize going out or minimize penalty
            if len(self.player_hands[ai_player_name]) == min_hand_size:
                # We might win - play lowest pip to get closer to going out
                best_move = min(valid_moves, key=lambda move: move['domino'].value())
                best_move['reason'] = 'endgame: race to win'
                return best_move
            else:
                # Damage control - play highest pip to reduce penalty
                best_move = max(valid_moves, key=lambda move: move['domino'].value())
                best_move['reason'] = 'endgame: minimize penalty'
                return best_move
        
        # Normal play: prefer own train, then mexican train
        train_priority = {
            ('personal', ai_player_name): 3,  # Own train (keeps it closed)
            ('mexican', None): 2,  # Mexican train (neutral)
        }
        
        # Score moves by train preference and pip management
        for move in valid_moves:
            train_key = (move['train'], move.get('train_owner'))
            move['score'] = train_priority.get(train_key, 1)  # Other trains get score 1
            # Slight preference for getting rid of higher pips
            move['score'] += move['domino'].value() * 0.1
        
        best_move = max(valid_moves, key=lambda move: move['score'])
        best_move['reason'] = f'strategic choice (score: {best_move["score"]:.1f})'
        return best_move
    
    def _ai_expert_strategy(self, ai_player_name: str, valid_moves: List[Dict]) -> Dict:
        """Level 5 AI: Multi-layer expert optimization"""
        import random
        
        # Advanced game state analysis
        my_hand_size = len(self.player_hands[ai_player_name])
        opponent_hands = {p: len(hand) for p, hand in self.player_hands.items() if p != ai_player_name}
        min_opponent_hand = min(opponent_hands.values()) if opponent_hands else 999
        total_dominoes_left = sum(len(hand) for hand in self.player_hands.values())
        
        self.logger.debug(f"Expert analysis: My hand={my_hand_size}, Min opponent={min_opponent_hand}, Total left={total_dominoes_left}")
        
        # Multi-factor scoring
        for move in valid_moves:
            score = 0
            reasons = []
            
            # Factor 1: Train strategy (30% weight)
            if move['train'] == 'personal' and move['train_owner'] == ai_player_name:
                score += 30
                reasons.append('own-train')
            elif move['train'] == 'mexican':
                score += 20
                reasons.append('mexican-train')
            else:
                score += 10
                reasons.append('opponent-train')
            
            # Factor 2: Pip management (25% weight)
            domino_value = move['domino'].value()
            if my_hand_size <= 3:  # Nearly out - prioritize low pips
                score += (20 - domino_value) * 1.25
                reasons.append(f'endgame-low-pips({domino_value})')
            elif min_opponent_hand <= 2:  # Opponent nearly out - damage control
                score += domino_value * 1.25
                reasons.append(f'opponent-endgame-high-pips({domino_value})')
            else:  # Normal play - moderate preference for high pips
                score += domino_value * 0.8
                reasons.append(f'normal-pips({domino_value})')
            
            # Factor 3: Hand composition analysis (20% weight) 
            # Prefer to keep dominoes that match common numbers
            domino = move['domino']
            numbers_in_hand = []
            for hand_domino in self.player_hands[ai_player_name]:
                if hand_domino != domino:  # Don't count the domino we're about to play
                    numbers_in_hand.extend([hand_domino.left, hand_domino.right])
            
            # Count how many times each number appears in our remaining hand
            number_counts = {}
            for num in numbers_in_hand:
                number_counts[num] = number_counts.get(num, 0) + 1
            
            # Playing a domino that matches numbers we have lots of is good
            domino_numbers = [domino.left, domino.right]
            flexibility_bonus = sum(number_counts.get(num, 0) for num in domino_numbers)
            score += flexibility_bonus * 4
            if flexibility_bonus > 0:
                reasons.append(f'hand-synergy({flexibility_bonus})')
            
            # Factor 4: Endgame urgency (15% weight)
            if min_opponent_hand <= 1:
                score += 15  # Emergency mode
                reasons.append('emergency')
            elif min_opponent_hand <= 3:
                score += 10  # High alert
                reasons.append('urgent')
            
            # Factor 5: Double handling (10% weight)
            if domino.is_double():
                # Playing doubles is risky unless we can likely satisfy them
                # This is a simplified check - real implementation would be more sophisticated
                score -= 5  # Small penalty for double risk
                reasons.append('double-risk')
            
            move['score'] = score
            move['reason'] = f"expert({','.join(reasons[:3])})"  # Top 3 reasons
        
        # Choose the highest scoring move
        best_move = max(valid_moves, key=lambda move: move['score'])
        self.logger.debug(f"Expert chose move with score: {best_move['score']:.1f}")
        return best_move
    
    def make_move(self, player_id: str, domino: Domino, train_type: str, train_owner: Optional[str] = None) -> Dict:
        self.logger.debug(f"MAKE_MOVE: {player_id} playing {domino.left}-{domino.right} on {train_type} train (owner: {train_owner})")
        
        if self.get_current_player() != player_id:
            self.logger.info(f"Invalid turn: {player_id} tried to play, but it's {self.get_current_player()}'s turn")
            return {"success": False, "error": "Not your turn"}
        
        # Find the domino in the player's hand by ID
        player_hand = self.player_hands.get(player_id, [])
        self.logger.debug(f"Player {player_id} has {len(player_hand)} dominos in hand")
        
        domino_in_hand = None
        for d in player_hand:
            if d.id == domino.id:
                domino_in_hand = d
                self.logger.debug(f"Found domino in hand: {d.left}-{d.right}")
                break
        
        if not domino_in_hand:
            self.logger.debug(f"Domino not found in player's hand!")
            self.logger.debug(f"Looking for ID: {domino.id}")
            self.logger.debug(f"Hand IDs: {[d.id for d in player_hand[:3]]}...") # Show first 3 IDs
            return {"success": False, "error": "Domino not in hand"}
        
        # Determine target train
        if train_type == "mexican":
            if not self.mexican_train:
                self.mexican_train = Train(TrainType.MEXICAN, None, [])
            target_train = self.mexican_train
            required_value = self.current_round if not target_train.dominoes else target_train.get_end_value()
        else:
            target_train = self.trains[train_owner]
            required_value = self.current_round if not target_train.dominoes else target_train.get_end_value()
        
        self.logger.debug(f"Target train has {len(target_train.dominoes)} dominos")
        self.logger.debug(f"Required value to match: {required_value}")
        self.logger.debug(f"Domino values: {domino_in_hand.left}-{domino_in_hand.right}")
        self.logger.debug(f"Does domino match? {domino_in_hand.matches(required_value)}")
        
        # Validate move (use the domino from hand)
        if not target_train.can_play_domino(domino_in_hand, required_value):
            self.logger.debug(f"Invalid move - domino doesn't match required value {required_value}")
            return {"success": False, "error": f"Invalid move - need {required_value}"}
        
        self.logger.debug(f"Valid move! Adding domino to train...")
        
        # Make the move
        target_train.add_domino(domino_in_hand, required_value)
        
        # Safely remove domino from hand (double-check it's still there)
        if domino_in_hand in self.player_hands[player_id]:
            self.player_hands[player_id].remove(domino_in_hand)
        else:
            self.logger.warning(f"Domino {domino_in_hand.id} not found in hand during removal (already removed?)")
        
        self.logger.debug(f"Move successful! Player now has {len(self.player_hands[player_id])} dominos")
        
        # Close the player's train if they played on their own train and it was open
        if train_type == "personal" and train_owner == player_id and target_train.is_open:
            target_train.is_open = False
            self.logger.debug(f"{player_id}'s train is now CLOSED (played on own train)")
        
        # Check for round end
        if not self.player_hands[player_id]:
            return self._end_round(player_id)
        
        # Handle doubles according to traditional Mexican Train rules
        is_double_played = domino_in_hand.is_double()
        is_satisfying_double = target_train.needs_double_satisfaction
        
        if is_double_played:
            # Player played a double - it needs to be satisfied
            self.add_unsatisfied_double(train_type, train_owner)
            self.player_has_played_double = True
            self.logger.debug(f"{player_id} played a double - gets another turn and must satisfy it")
            # Player gets another turn but must satisfy the double eventually
        elif is_satisfying_double:
            # Player satisfied an existing double
            self.remove_unsatisfied_double(train_type, train_owner)
            self.logger.debug(f"{player_id} satisfied a double on {train_type} train")
        
        # Determine if turn should continue or pass
        if is_double_played:
            # Player played a double - they get another turn
            # Turn will end when they can't/don't satisfy the double
            pass
        else:
            # Normal move or satisfied a double - check if turn should end
            if self.player_has_played_double and self.has_unsatisfied_doubles():
                # Player played a double earlier but hasn't satisfied it - train opens and turn ends
                self.logger.debug(f"{player_id} failed to satisfy their double - train opens")
                if player_id in self.trains:
                    self.trains[player_id].is_open = True
            
            # Turn ends
            self.next_turn()
        
        return {
            "success": True,
            "game_state": self.get_game_state(),
            "next_player": self.get_current_player(),
            "should_trigger_ai": self.get_current_player() in self.ai_players
        }
    
    def has_unsatisfied_doubles(self) -> bool:
        """Check if there are any unsatisfied doubles on the table"""
        return len(self.unsatisfied_doubles) > 0
    
    def get_unsatisfied_doubles(self) -> List[Tuple[str, str]]:
        """Get list of trains with unsatisfied doubles"""
        return self.unsatisfied_doubles.copy()
    
    def add_unsatisfied_double(self, train_type: str, train_owner: Optional[str]):
        """Add a double that needs to be satisfied"""
        double_location = (train_type, train_owner or "")
        if double_location not in self.unsatisfied_doubles:
            self.unsatisfied_doubles.append(double_location)
            self.logger.debug(f"Added unsatisfied double on {train_type} train (owner: {train_owner})")
    
    def remove_unsatisfied_double(self, train_type: str, train_owner: Optional[str]):
        """Remove a satisfied double"""
        double_location = (train_type, train_owner or "")
        if double_location in self.unsatisfied_doubles:
            self.unsatisfied_doubles.remove(double_location)
            self.logger.debug(f"Satisfied double on {train_type} train (owner: {train_owner})")
    
    def must_satisfy_doubles(self, player_id: str) -> bool:
        """Check if player must satisfy doubles before making other moves"""
        return self.has_unsatisfied_doubles()
    
    def next_turn(self):
        """Move to the next player's turn"""
        # Reset the double-played flag for the new turn
        self.player_has_played_double = False
        self.current_player_index = (self.current_player_index + 1) % len(self.players)
        self.logger.debug(f"Turn passes to: {self.get_current_player()}")
    
    def draw_from_boneyard(self, player_id: str) -> Dict:
        if self.get_current_player() != player_id:
            return {"success": False, "error": "Not your turn"}
        
        if not self.boneyard:
            # No dominoes left to draw, player must pass
            self.logger.debug(f"Boneyard empty, {player_id} passes turn")
            if player_id in self.trains:
                self.trains[player_id].is_open = True
                self.logger.debug(f"{player_id}'s train is now OPEN (couldn't draw)")
            self.next_turn()
            return {
                "success": True, 
                "action": "passed_empty_boneyard",
                "message": "Boneyard is empty, turn passed",
                "train_opened": True,
                "turn_passed": True,
                "next_player": self.get_current_player()
            }
        
        # Check if player has valid moves (they shouldn't be able to draw if they can play)
        valid_moves = self.get_valid_moves(player_id)
        if valid_moves:
            return {"success": False, "error": f"You must play a domino - you have {len(valid_moves)} valid moves"}
        
        # Draw one domino from boneyard
        domino = self.boneyard.pop()
        self.player_hands[player_id].append(domino)
        self.logger.debug(f"{player_id} drew domino {domino.left}-{domino.right} from boneyard")
        
        # Check if the newly drawn domino can be played (respecting doubles rules)
        if self.has_unsatisfied_doubles():
            # There are unsatisfied doubles - check if drawn domino can satisfy them
            drawn_moves = self._get_moves_for_domino_doubles_only(player_id, domino)
        else:
            # Normal play - check all possible moves
            drawn_moves = self._get_moves_for_domino(player_id, domino)
        
        if drawn_moves:
            # Player can play the drawn domino - they get to continue their turn
            self.logger.debug(f"{player_id} can play the drawn domino")
            return {
                "success": True,
                "domino": {
                    "left": domino.left,
                    "right": domino.right,
                    "id": domino.id
                },
                "can_play_drawn": True,
                "valid_moves": len(drawn_moves),
                "message": "Drew domino - you can play it!",
                "must_satisfy_doubles": self.has_unsatisfied_doubles()
            }
        else:
            # Player cannot play the drawn domino - turn ends, train opens
            self.logger.debug(f"{player_id} cannot play drawn domino, turn passes")
            if player_id in self.trains:
                self.trains[player_id].is_open = True
                self.logger.debug(f"{player_id}'s train is now OPEN (couldn't play drawn domino)")
            
            self.next_turn()
            return {
                "success": True,
                "domino": {
                    "left": domino.left,
                    "right": domino.right,
                    "id": domino.id
                },
                "can_play_drawn": False,
                "train_opened": True,
                "turn_passed": True,
                "next_player": self.get_current_player(),
                "message": "Drew domino but couldn't play it - turn passed"
            }
    
    def _end_round(self, winner_id: str) -> Dict:
        # Calculate scores for this game
        game_scores = {}
        for player_id in self.players:
            score = sum(d.value() for d in self.player_hands[player_id])
            game_scores[player_id] = score
            self.round_scores[player_id].append(score)
        
        # In the new structure, each game is a single round, so end the game
        return self._end_game(game_scores)
    
    def is_game_over(self) -> bool:
        """Check if the game is over"""
        # Game is over if any player has no dominoes left
        for player_id in self.players:
            if len(self.player_hands.get(player_id, [])) == 0:
                return True
        
        # Game is over if no one can play and boneyard is empty
        if not self.boneyard:
            all_stuck = True
            for player_id in self.players:
                if self.get_valid_moves(player_id):
                    all_stuck = False
                    break
            if all_stuck:
                return True
        
        # Game is also over if there are unsatisfied doubles, boneyard is empty, and no one can satisfy them
        if self.has_unsatisfied_doubles() and not self.boneyard:
            can_satisfy = False
            for player_id in self.players:
                if self.get_valid_moves(player_id):  # This will check doubles-only moves if doubles exist
                    can_satisfy = True
                    break
            if not can_satisfy:
                self.logger.info("Game ending: unsatisfied doubles remain but boneyard is empty and no one can satisfy them")
                return True
        
        return False
    
    def _end_game(self, game_scores: Dict[str, int] = None) -> Dict:
        # Use provided scores or calculate from round_scores
        if game_scores is None:
            game_scores = {}
            for player_id in self.players:
                game_scores[player_id] = sum(self.round_scores[player_id])
        
        # Determine winner (lowest score)
        winner = min(game_scores.keys(), key=lambda p: game_scores[p])
        
        return {
            "success": True,
            "game_ended": True,
            "final_scores": game_scores,
            "winner": winner,
            "is_match_game": self.config.get("is_match_game", False),
            "match_id": self.config.get("match_id"),
            "game_number": self.config.get("game_number", 1)
        }
    
    def start_countdown(self):
        """Start the countdown timer for auto-start or deletion"""
        import time
        self.countdown_start_time = time.time()
        self.logger.info(f"Game {self.game_id} countdown started: {self.countdown_minutes} minutes")
    
    def get_countdown_remaining(self) -> Optional[int]:
        """Get remaining countdown time in seconds"""
        if not self.countdown_start_time:
            return None
        
        import time
        elapsed = time.time() - self.countdown_start_time
        remaining = (self.countdown_minutes * 60) - elapsed
        return max(0, int(remaining))
    
    def is_countdown_expired(self) -> bool:
        """Check if countdown has expired"""
        remaining = self.get_countdown_remaining()
        return remaining is not None and remaining <= 0
    
    def can_auto_start(self) -> bool:
        """Check if game can auto-start (has minimum players)"""
        total_players = len(self.players)
        return total_players >= self.min_players and not self.game_started
    
    def get_game_state(self, requesting_player: str = None) -> Dict:
        return {
            "game_id": self.game_id,
            "players": self.players,
            "current_player": self.get_current_player() if self.game_started and self.players else None,
            "current_round": self.current_round,
            "engine_value": self.current_round,
            "trains": {owner: {
                "dominoes": [{"left": d.left, "right": d.right, "id": d.id} for d in train.dominoes],
                "is_open": train.is_open,
                "needs_double_satisfaction": train.needs_double_satisfaction
            } for owner, train in self.trains.items()} if self.trains else {},
            "mexican_train": {
                "dominoes": [{"left": d.left, "right": d.right, "id": d.id} for d in self.mexican_train.dominoes] if self.mexican_train else [],
                "is_open": True,
                "needs_double_satisfaction": self.mexican_train.needs_double_satisfaction if self.mexican_train else False
            } if self.mexican_train else None,
            "boneyard_count": len(self.boneyard) if hasattr(self, 'boneyard') else 0,
            "player_hand_counts": {player: len(hand) for player, hand in self.player_hands.items()} if hasattr(self, 'player_hands') else {},
            "player_hands": {
                requesting_player: [
                    {"left": d.left, "right": d.right, "id": d.id} 
                    for d in self.player_hands.get(requesting_player, [])
                ]
            } if requesting_player and hasattr(self, 'player_hands') and requesting_player in self.players else {},
            "round_scores": self.round_scores,
            "started": self.game_started,  # True when game has actually started with multiple players
            "name": self.name,
            "description": self.description,
            "host": self.host,
            "max_players": self.max_players,
            "min_players": self.min_players,
            "allow_spectators": self.allow_spectators,
            "visibility": self.visibility,
            "spectators": self.spectators,
            "spectator_count": len(self.spectators),
            "ai_enabled": self.ai_enabled,
            "ai_skill_level": self.ai_skill_level,
            "ai_players": self.ai_players,
            "countdown_minutes": self.countdown_minutes,
            "countdown_remaining": self.get_countdown_remaining(),
            "can_auto_start": self.can_auto_start(),
            # Doubles tracking for traditional Mexican Train rules
            "unsatisfied_doubles": [
                {"train_type": train_type, "train_owner": train_owner if train_owner else None}
                for train_type, train_owner in self.unsatisfied_doubles
            ],
            "must_satisfy_doubles": self.has_unsatisfied_doubles(),
            "player_has_played_double": self.player_has_played_double
        }
    
    def get_spectator_game_state(self) -> Dict:
        """Get game state for spectators (without player hands or sensitive info)"""
        return {
            "game_id": self.game_id,
            "players": self.players,
            "current_player": self.get_current_player(),
            "current_round": self.current_round,
            "engine_value": self.current_round,
            "trains": {owner: {
                "dominoes": [{"left": d.left, "right": d.right, "id": d.id} for d in train.dominoes],
                "is_open": train.is_open,
                "needs_double_satisfaction": train.needs_double_satisfaction
            } for owner, train in self.trains.items()},
            "mexican_train": {
                "dominoes": [{"left": d.left, "right": d.right, "id": d.id} for d in self.mexican_train.dominoes] if self.mexican_train else [],
                "is_open": True,
                "needs_double_satisfaction": self.mexican_train.needs_double_satisfaction if self.mexican_train else False
            } if self.mexican_train else None,
            "boneyard_count": len(self.boneyard),
            "player_hand_counts": {player: len(hand) for player, hand in self.player_hands.items()},  # Only counts, not actual cards
            "round_scores": self.round_scores,
            "started": self.game_started,
            "name": self.name,
            "description": self.description,
            "host": self.host,
            "max_players": self.max_players,
            "min_players": self.min_players,
            "allow_spectators": self.allow_spectators,
            "visibility": self.visibility,
            "spectators": self.spectators,
            "spectator_count": len(self.spectators),
            "ai_enabled": self.ai_enabled,
            "ai_skill_level": self.ai_skill_level,
            "ai_players": self.ai_players,
            "countdown_minutes": self.countdown_minutes,
            "countdown_remaining": self.get_countdown_remaining(),
            "can_auto_start": self.can_auto_start(),
            # Doubles tracking for traditional Mexican Train rules
            "unsatisfied_doubles": [
                {"train_type": train_type, "train_owner": train_owner if train_owner else None}
                for train_type, train_owner in self.unsatisfied_doubles
            ],
            "must_satisfy_doubles": self.has_unsatisfied_doubles(),
            "player_has_played_double": self.player_has_played_double,
            "is_spectator_view": True  # Flag to indicate this is spectator-safe
        }
    
    def can_add_player(self, player_name: str) -> Tuple[bool, str]:
        """Check if a player can be added to the game"""
        if player_name in self.players:
            return False, f"Player '{player_name}' is already in this game"
        
        if len(self.players) >= self.max_players:
            return False, f"Game is full (maximum {self.max_players} players)"
        
        if self.game_started:  # Game has actually started - no new players allowed
            return False, "Cannot join game that has already started"
        
        return True, "Player can join"
    
    def add_player(self, player_name: str) -> Dict:
        """Add a player to the game if possible"""
        can_add, reason = self.can_add_player(player_name)
        
        if not can_add:
            return {
                "success": False,
                "error": reason
            }
        
        # Add player to the game
        self.players.append(player_name)
        self.round_scores[player_name] = []
        
        # If hands have been dealt (game setup already called), deal cards to new player
        if len(self.player_hands) > 0:
            self.logger.info(f"Dealing cards to new player '{player_name}'")
            # Deal the appropriate number of dominoes to the new player
            new_hand = []
            for _ in range(self.dominoes_per_player):
                if self.boneyard:
                    domino = self.boneyard.pop()
                    new_hand.append(domino)
            self.player_hands[player_name] = new_hand
            
            # Create a personal train for the new player
            self.trains[player_name] = Train(TrainType.PERSONAL, player_name, [])
        
        # Note: Game is no longer auto-started when 2nd player joins
        # Host must manually start the game when ready
        
        self.logger.info(f"Player '{player_name}' joined game {self.game_id}. Players: {self.players}")
        
        return {
            "success": True,
            "message": f"Player '{player_name}' joined the game",
            "players": self.players,
            "player_count": len(self.players),
            "game_started": self.game_started
        }
    
    def start_game(self, force_start: bool = False) -> Dict:
        """Mark the game as started - no new players can join after this
        
        Args:
            force_start: If True, allows host to start even without minimum players
        
        Returns:
            Dict with success status and message
        """
        if self.game_started:
            return {
                "success": False,
                "error": "Game has already started"
            }
        
        current_players = len(self.players)
        
        # Add AI players if enabled and fill_to_max is set
        if self.ai_enabled and self.ai_fill_to_max:
            self._add_ai_players_to_max()
            self.logger.info(f"Added AI players: {self.ai_players}")
        
        # Update player count after adding AIs
        current_players = len(self.players)
        
        # Check if we can start
        if not force_start and current_players < self.min_players:
            return {
                "success": False,
                "error": f"Need at least {self.min_players} players to start (currently have {current_players})"
            }
        
        # Rebuild round scores to include AI players
        self.round_scores = {player: [] for player in self.players}
        
        # Setup the round with all players (human + AI)
        self.setup_round()
        
        # Start the game
        self.game_started = True
        self.logger.info(f"Game {self.game_id} started manually by host with {current_players} players: {self.players}")
        
        return {
            "success": True,
            "message": f"Game started with {current_players} players",
            "players": self.players,
            "game_started": True
        }
    
    def can_add_spectator(self, spectator_name: str) -> Tuple[bool, str]:
        """Check if a spectator can be added to the game"""
        if spectator_name in self.players:
            return False, f"'{spectator_name}' is already a player in this game"
        
        if spectator_name in self.spectators:
            return False, f"'{spectator_name}' is already spectating this game"
        
        if not self.game_started:
            return False, "Cannot spectate a game that hasn't started yet - you can join as a player instead"
        
        # No limit on spectators for now
        return True, "Can spectate game"
    
    def add_spectator(self, spectator_name: str) -> Dict:
        """Add a spectator to the game"""
        can_add, reason = self.can_add_spectator(spectator_name)
        
        if not can_add:
            return {
                "success": False,
                "error": reason
            }
        
        self.spectators.append(spectator_name)
        self.logger.info(f"Spectator '{spectator_name}' joined game {self.game_id}. Spectators: {self.spectators}")
        
        return {
            "success": True,
            "message": f"'{spectator_name}' is now spectating the game",
            "spectators": self.spectators,
            "spectator_count": len(self.spectators)
        }
    
    def remove_spectator(self, spectator_name: str) -> bool:
        """Remove a spectator from the game"""
        if spectator_name in self.spectators:
            self.spectators.remove(spectator_name)
            self.logger.info(f"Spectator '{spectator_name}' left game {self.game_id}")
            return True
        return False