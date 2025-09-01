import asyncio
import time
from typing import Dict, Set
from app.websockets.game_manager import game_manager

class GameTimerManager:
    def __init__(self):
        self.running = False
        self.task: asyncio.Task = None
    
    async def start(self):
        """Start the timer management background task"""
        if self.running:
            return
        
        self.running = True
        self.task = asyncio.create_task(self._timer_loop())
        print("🕒 Game timer manager started")
    
    async def stop(self):
        """Stop the timer management background task"""
        self.running = False
        if self.task:
            self.task.cancel()
            try:
                await self.task
            except asyncio.CancelledError:
                pass
        print("🕒 Game timer manager stopped")
    
    async def _timer_loop(self):
        """Main timer loop that checks game countdowns"""
        while self.running:
            try:
                await self._check_game_countdowns()
                await asyncio.sleep(30)  # Check every 30 seconds
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Error in timer loop: {e}")
                await asyncio.sleep(60)  # Wait longer if there's an error
    
    async def _check_game_countdowns(self):
        """Check all games for expired countdowns"""
        games_to_remove = []
        
        for game_id, game in game_manager.active_games.items():
            if not game.countdown_start_time:
                continue
            
            if game.is_countdown_expired():
                if game.can_auto_start():
                    # Game has minimum players - auto-start it
                    print(f"⏰ Auto-starting game {game_id} (countdown expired, has min players)")
                    game.start_game()
                    
                    # Notify all players that game auto-started
                    await game_manager.broadcast_to_game(game_id, {
                        "type": "game_auto_started",
                        "data": {
                            "message": f"Game auto-started! Countdown expired and minimum players ({game.min_players}) reached.",
                            "game_state": game.get_game_state()
                        }
                    })
                    
                else:
                    # Game doesn't have minimum players - mark for deletion
                    print(f"⏰ Marking game {game_id} for deletion (countdown expired, insufficient players)")
                    games_to_remove.append(game_id)
                    
                    # Notify any connected players that game is being deleted
                    await game_manager.broadcast_to_game(game_id, {
                        "type": "game_deleted",
                        "data": {
                            "reason": f"Game deleted: countdown expired without reaching minimum players ({game.min_players})",
                            "redirect_to_lobby": True
                        }
                    })
            
            else:
                # Send countdown updates to players
                remaining = game.get_countdown_remaining()
                if remaining and remaining % 60 == 0:  # Every minute
                    minutes_left = remaining // 60
                    await game_manager.broadcast_to_game(game_id, {
                        "type": "countdown_update",
                        "data": {
                            "minutes_remaining": minutes_left,
                            "seconds_remaining": remaining,
                            "can_auto_start": game.can_auto_start(),
                            "message": f"{minutes_left} minute(s) until auto-start or deletion"
                        }
                    })
        
        # Remove expired games
        for game_id in games_to_remove:
            if game_id in game_manager.active_games:
                del game_manager.active_games[game_id]
            
            # Clean up connections
            if game_id in game_manager.game_connections:
                del game_manager.game_connections[game_id]
            
            if game_id in game_manager.spectator_connections:
                del game_manager.spectator_connections[game_id]

# Global timer manager instance
timer_manager = GameTimerManager()