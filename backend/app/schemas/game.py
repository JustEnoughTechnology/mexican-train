from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class GameVisibility(str, Enum):
    PUBLIC = "public"
    PRIVATE = "private"

class GameStatus(str, Enum):
    WAITING = "waiting"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class CreateGameRequest(BaseModel):
    name: str
    description: Optional[str] = ""
    host: str  # Host display name
    visibility: GameVisibility = GameVisibility.PUBLIC
    password: Optional[str] = None
    max_players: int = 4  # 1-8 players allowed
    min_players: int = 2  # Minimum players needed to start
    ai_enabled: bool = True  # Whether to add AI players
    ai_skill_level: int = 1  # 1=Easy, 2=Medium, 3=Hard, 4=Expert, 5=Legendary
    ai_fill_to_max: bool = True  # Fill with AI to reach max_players
    countdown_minutes: int = 10  # Minutes before auto-start or deletion
    time_limit_seconds: Optional[int] = None  # Per-turn time limit
    allow_spectators: bool = True
    games_to_play: int = 13  # Number of games in this match

class JoinGameRequest(BaseModel):
    password: Optional[str] = None

class PlayerInfo(BaseModel):
    id: str
    username: str
    is_ai: bool = False
    ai_name: Optional[str] = None
    score: int = 0
    is_connected: bool = False

class GameInfo(BaseModel):
    id: str
    name: str
    description: Optional[str]
    host: PlayerInfo
    status: GameStatus
    visibility: GameVisibility
    players: List[PlayerInfo]
    max_players: int
    ai_count: int
    current_round: int
    created_at: datetime
    started_at: Optional[datetime] = None

class DominoResponse(BaseModel):
    left: int
    right: int
    id: str

class TrainResponse(BaseModel):
    dominoes: List[DominoResponse]
    is_open: bool
    needs_double_satisfaction: bool

class GameStateResponse(BaseModel):
    game_id: str
    players: List[str]
    current_player: str
    current_round: int
    engine_value: int
    trains: Dict[str, TrainResponse]
    mexican_train: Optional[TrainResponse]
    boneyard_count: int
    player_hand_counts: Dict[str, int]
    round_scores: Dict[str, List[int]]

class MakeMoveRequest(BaseModel):
    domino_id: str
    train_type: str  # "personal" or "mexican"
    train_owner: Optional[str] = None

class MoveResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    game_state: Optional[GameStateResponse] = None
    next_player: Optional[str] = None
    round_ended: bool = False
    game_ended: bool = False
    round_scores: Optional[Dict[str, int]] = None
    final_scores: Optional[Dict[str, int]] = None
    winner: Optional[str] = None