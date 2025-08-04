from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, JSON, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base

class GameStatus(enum.Enum):
    WAITING = "waiting"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class GameVisibility(enum.Enum):
    PUBLIC = "public"
    PRIVATE = "private"

class Game(Base):
    __tablename__ = "games"
    
    id = Column(String, primary_key=True)  # UUID
    name = Column(String, nullable=False)
    description = Column(String)
    host_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(GameStatus), default=GameStatus.WAITING)
    visibility = Column(Enum(GameVisibility), default=GameVisibility.PUBLIC)
    password_hash = Column(String)  # For private games
    
    # Game settings
    max_players = Column(Integer, default=8)
    ai_count = Column(Integer, default=0)
    ai_skill_level = Column(Integer, default=2)
    time_limit_seconds = Column(Integer)
    allow_spectators = Column(Boolean, default=True)
    
    # Game state
    current_round = Column(Integer, default=0)
    current_player_index = Column(Integer, default=0)
    game_state = Column(JSON)  # Store complete game state as JSON
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    started_at = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    
    # Relationships
    host = relationship("User", backref="hosted_games")
    players = relationship("GamePlayer", back_populates="game")

class GamePlayer(Base):
    __tablename__ = "game_players"
    
    id = Column(Integer, primary_key=True)
    game_id = Column(String, ForeignKey("games.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"))  # Null for AI players
    player_index = Column(Integer, nullable=False)
    is_ai = Column(Boolean, default=False)
    ai_name = Column(String)  # For AI players
    
    # Player state
    score = Column(Integer, default=0)
    is_connected = Column(Boolean, default=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    game = relationship("Game", back_populates="players")
    user = relationship("User", backref="game_participations")