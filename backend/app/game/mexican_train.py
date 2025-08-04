from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
import random
import uuid

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

class MexicanTrainGame:
    def __init__(self, game_id: str, players: List[str], max_domino: int = 12):
        self.game_id = game_id
        self.players = players
        self.max_domino = max_domino
        self.current_round = max_domino
        self.current_player_index = 0
        
        # Game state
        self.dominoes_per_player = self._calculate_dominoes_per_player()
        self.boneyard: List[Domino] = []
        self.player_hands: Dict[str, List[Domino]] = {}
        self.trains: Dict[str, Train] = {}
        self.mexican_train: Optional[Train] = None
        self.engine_domino: Optional[Domino] = None
        
        # Round tracking
        self.round_scores: Dict[str, List[int]] = {player: [] for player in players}
        
        self.setup_round()
    
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
        
        # Find and set engine domino
        engine_value = self.current_round
        self.engine_domino = next(d for d in all_dominoes if d.left == engine_value and d.right == engine_value)
        all_dominoes.remove(self.engine_domino)
        
        # Deal to players
        self.player_hands = {}
        for i, player in enumerate(self.players):
            start_idx = i * self.dominoes_per_player
            end_idx = start_idx + self.dominoes_per_player
            self.player_hands[player] = all_dominoes[start_idx:end_idx]
        
        # Remaining dominoes go to boneyard
        dealt_count = len(self.players) * self.dominoes_per_player
        self.boneyard = all_dominoes[dealt_count:]
        
        # Initialize trains
        self.trains = {}
        for player in self.players:
            self.trains[player] = Train(TrainType.PERSONAL, player, [])
        
        self.mexican_train = None
        
        # Find starting player (player with highest double if any, otherwise first player)
        self.current_player_index = 0
    
    def get_current_player(self) -> str:
        return self.players[self.current_player_index]
    
    def get_valid_moves(self, player_id: str) -> List[Dict]:
        moves = []
        hand = self.player_hands.get(player_id, [])
        
        for domino in hand:
            # Check personal train
            if self._can_play_on_train(domino, self.trains[player_id], self.current_round):
                moves.append({
                    "domino": domino,
                    "train": "personal",
                    "train_owner": player_id
                })
            
            # Check other open trains
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
    
    def _can_play_on_train(self, domino: Domino, train: Train, engine_value: int) -> bool:
        if not train.dominoes:
            # Empty train - must match engine
            return domino.matches(engine_value)
        else:
            # Must match end of train
            return domino.matches(train.get_end_value())
    
    def make_move(self, player_id: str, domino: Domino, train_type: str, train_owner: Optional[str] = None) -> Dict:
        if self.get_current_player() != player_id:
            return {"success": False, "error": "Not your turn"}
        
        if domino not in self.player_hands[player_id]:
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
        
        # Validate move
        if not target_train.can_play_domino(domino, required_value):
            return {"success": False, "error": "Invalid move"}
        
        # Make the move
        target_train.add_domino(domino, required_value)
        self.player_hands[player_id].remove(domino)
        
        # Check for round end
        if not self.player_hands[player_id]:
            return self._end_round(player_id)
        
        # Handle doubles
        if domino.is_double() and not target_train.needs_double_satisfaction:
            # Player gets another turn
            pass
        else:
            # Next player's turn
            self.current_player_index = (self.current_player_index + 1) % len(self.players)
        
        return {
            "success": True,
            "game_state": self.get_game_state(),
            "next_player": self.get_current_player()
        }
    
    def draw_from_boneyard(self, player_id: str) -> Dict:
        if self.get_current_player() != player_id:
            return {"success": False, "error": "Not your turn"}
        
        if not self.boneyard:
            return {"success": False, "error": "Boneyard is empty"}
        
        domino = self.boneyard.pop()
        self.player_hands[player_id].append(domino)
        
        return {"success": True, "domino": domino}
    
    def _end_round(self, winner_id: str) -> Dict:
        # Calculate scores for this round
        round_scores = {}
        for player_id in self.players:
            score = sum(d.value() for d in self.player_hands[player_id])
            round_scores[player_id] = score
            self.round_scores[player_id].append(score)
        
        # Check if game is complete
        if self.current_round == 0:
            return self._end_game()
        
        # Setup next round
        self.current_round -= 1
        self.setup_round()
        
        return {
            "success": True,
            "round_ended": True,
            "round_scores": round_scores,
            "winner": winner_id,
            "next_round": self.current_round
        }
    
    def _end_game(self) -> Dict:
        # Calculate final scores
        final_scores = {}
        for player_id in self.players:
            final_scores[player_id] = sum(self.round_scores[player_id])
        
        # Determine winner (lowest score)
        winner = min(final_scores.keys(), key=lambda p: final_scores[p])
        
        return {
            "success": True,
            "game_ended": True,
            "final_scores": final_scores,
            "winner": winner
        }
    
    def get_game_state(self) -> Dict:
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
            "player_hand_counts": {player: len(hand) for player, hand in self.player_hands.items()},
            "round_scores": self.round_scores
        }