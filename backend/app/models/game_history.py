from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class GameHistory(Base):
    __tablename__ = "game_history"
    
    id = Column(Integer, primary_key=True, index=True)
    game_id = Column(String, ForeignKey("games.id"), nullable=False)
    round_number = Column(Integer, nullable=False)
    player_scores = Column(JSON)  # Store all player scores for this round
    winner_id = Column(Integer, ForeignKey("users.id"))
    completed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    game = relationship("Game", backref="history")
    winner = relationship("User", backref="won_games")