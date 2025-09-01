"""
AI Match Testing Framework
Runs headless AI-only matches for strategy evaluation and performance analysis
"""

import asyncio
import json
import time
import uuid
import logging
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from pathlib import Path
import statistics

from app.game.mexican_train import MexicanTrainMatch
from app.core.ai_config import ai_config

class AIMatchRunner:
    def __init__(self, results_dir: str = "ai_test_results"):
        self.results_dir = Path(results_dir)
        self.results_dir.mkdir(exist_ok=True)
        self.current_session_id = None
        self.logger = logging.getLogger("AIMatchRunner")
        
    def create_test_session(self, description: str = "") -> str:
        """Create a new testing session"""
        self.current_session_id = f"session_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        session_info = {
            "session_id": self.current_session_id,
            "created_at": datetime.now().isoformat(),
            "description": description,
            "matches": []
        }
        
        session_file = self.results_dir / f"{self.current_session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_info, f, indent=2)
        
        self.logger.info(f"Created test session: {self.current_session_id}")
        return self.current_session_id
    
    def run_single_match(
        self, 
        ai_configs: List[Dict[str, any]], 
        games_to_play: int = 13,
        match_id: str = None
    ) -> Dict:
        """Run a single AI-only match and return results"""
        
        if not match_id:
            match_id = f"test_match_{uuid.uuid4().hex[:8]}"
        
        # Validate AI configurations
        for config in ai_configs:
            if 'strategy' in config:
                strategy_name = config['strategy']
                if strategy_name not in ai_config.strategies:
                    raise ValueError(f"Strategy '{strategy_name}' not found")
        
        # Create player names and configurations
        players = []
        ai_players = {}
        
        for i, config in enumerate(ai_configs):
            player_name = config.get('name', f"AI_{i+1}")
            players.append(player_name)
            
            # Configure AI
            if 'strategy' in config:
                ai_players[player_name] = {
                    'strategy': config['strategy'],
                    'skill_level': config.get('level', 3)
                }
            else:
                ai_players[player_name] = {
                    'skill_level': config.get('level', 3)
                }
        
        self.logger.info(f"Starting match {match_id}: {players}")
        self.logger.info(f"Games to play: {games_to_play}")
        
        # Create and run match
        match = MexicanTrainMatch(
            match_id=match_id,
            players=players,
            config={
                'games_to_play': games_to_play,
                'max_players': len(players),
                'ai_enabled': True,
                'ai_skill_level': 3,  # Default, individual AIs can override
                'name': f'AI Test Match {match_id}'
            }
        )
        
        # Set custom AI configurations
        match.ai_players = ai_players
        
        # Run match synchronously
        match_start_time = time.time()
        match_results = self._run_match_headless(match)
        match_duration = time.time() - match_start_time
        
        # Collect detailed results
        final_state = match.get_match_state()
        
        # Determine match winner if match is complete
        match_winner = None
        if final_state.get('match_completed', False):
            # Match is complete, get winner from match scores
            match_scores = final_state.get('match_scores', {})
            if match_scores:
                match_winner = min(match_scores.keys(), key=lambda p: match_scores[p])
        
        result = {
            "match_id": match_id,
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": round(match_duration, 2),
            "games_played": final_state.get('games_played', 0),
            "games_to_play": games_to_play,
            "players": {
                player: {
                    "strategy": ai_players.get(player, {}).get('strategy', 'default'),
                    "skill_level": ai_players.get(player, {}).get('skill_level', 3),
                    "total_score": final_state.get('match_scores', {}).get(player, 0),
                    "games_won": len([g for g in final_state.get('game_results', []) 
                                    if g.get('winner') == player]),
                    "average_game_score": 0,
                    "best_game_score": 0,
                    "worst_game_score": 0
                } for player in players
            },
            "winner": match_winner,
            "game_results": final_state.get('game_results', []),
            "match_completed": final_state.get('match_completed', False)
        }
        
        # Calculate per-player statistics
        for player in players:
            player_scores = [g.get('scores', {}).get(player, 0) 
                           for g in result['game_results']]
            if player_scores:
                result['players'][player]['average_game_score'] = round(statistics.mean(player_scores), 1)
                result['players'][player]['best_game_score'] = min(player_scores)
                result['players'][player]['worst_game_score'] = max(player_scores)
        
        self.logger.info(f"Match completed in {match_duration:.1f}s - Winner: {result['winner']}")
        
        return result
    
    def _run_match_headless(self, match: MexicanTrainMatch) -> Dict:
        """Run a match without WebSocket connections"""
        try:
            # Start the match
            match.start_next_game()
            
            # Run games until match is complete
            while not match.is_match_complete():
                current_game = match.current_game
                if not current_game:
                    break
                
                # Run current game to completion
                game_start_time = time.time()
                self._run_game_headless(current_game, match)
                game_duration = time.time() - game_start_time
                
                self.logger.debug(f"Game {match.games_played + 1} completed in {game_duration:.1f}s")
                
                # Move to next game
                if not match.is_match_complete():
                    match.start_next_game()
            
            return {"success": True, "final_state": match.get_match_state()}
        
        except Exception as e:
            self.logger.error(f"Error running match: {e}")
            return {"success": False, "error": str(e)}
    
    def _run_game_headless(self, game, match=None):
        """Run a single game without human interaction"""
        max_turns = 1000  # Safety limit
        turn_count = 0
        
        while not game.is_game_over() and turn_count < max_turns:
            current_player = game.get_current_player()
            if not current_player:
                break
            
            # Auto-play for AI players
            valid_moves = game.get_valid_moves(current_player)
            
            if valid_moves:
                # AI chooses move
                chosen_move = game._choose_ai_move(current_player, valid_moves)
                domino = chosen_move['domino']
                train_name = chosen_move['train']
                
                # Convert train name to train_type and owner
                # Use the train_owner from the chosen move data
                move_train_owner = chosen_move.get('train_owner')
                
                if train_name == 'mexican':
                    train_type = 'mexican'
                    train_owner = None
                elif train_name == 'personal':
                    train_type = 'personal'
                    # Use the train_owner from the move data, not current_player
                    train_owner = move_train_owner if move_train_owner else current_player
                else:
                    # Fallback case - treat as player name
                    train_type = 'personal' 
                    train_owner = train_name
                
                result = game.make_move(
                    current_player,
                    domino,
                    train_type,
                    train_owner
                )
                
                if not result.get('success'):
                    self.logger.debug(f"Invalid move by {current_player}: {result.get('error')}")
                    # Check if game should end after invalid move
                    if game.is_game_over():
                        self.logger.debug(f"Game ending due to invalid move and no valid moves remaining")
                        break
                    # Invalid move likely means AI logic error - try to draw instead
                    self.logger.debug(f"AI made invalid move, attempting to draw from boneyard instead")
                    if game.boneyard:
                        draw_result = game.draw_from_boneyard(current_player)
                        if not draw_result.get('success'):
                            self.logger.debug(f"Draw also failed: {draw_result.get('error', 'Unknown error')}")
                            # If still same player and has valid moves, AI might be broken
                            if game.get_current_player() == current_player and game.get_valid_moves(current_player):
                                self.logger.warning(f"AI appears broken for {current_player} - forcing turn advance")
                            # Force turn advance as last resort
                            game.next_turn()
                    else:
                        # No boneyard, check if game should end
                        if game.is_game_over():
                            self.logger.debug(f"Game ending - no valid moves and no boneyard")
                            break
                        # Force turn advance to prevent infinite loop
                        game.next_turn()
            else:
                # Player has no valid moves
                if game.boneyard:
                    # Try to draw from boneyard
                    draw_result = game.draw_from_boneyard(current_player)
                    if not draw_result.get('success'):
                        self.logger.debug(f"Draw failed for {current_player}: {draw_result.get('error', 'Unknown error')}")
                        break
                else:
                    # No moves and no boneyard - check if game is over
                    if game.is_game_over():
                        self.logger.debug(f"Game over: No moves available and boneyard is empty")
                        break
                    else:
                        # This shouldn't happen, but force turn advance to prevent infinite loop
                        self.logger.warning(f"No moves and no boneyard but game not over - forcing turn advance")
                        game.next_turn()
            
            turn_count += 1
        
        if turn_count >= max_turns:
            self.logger.warning(f"Game reached turn limit ({max_turns}), ending game")
        
        # Ensure game is properly completed
        if game.is_game_over():
            self.logger.debug(f"Game over detected - calculating final scores")
            # Calculate final scores for all players
            game_scores = {}
            for player_id in game.players:
                # Calculate score based on remaining dominoes in hand
                score = sum(d.value() for d in game.player_hands.get(player_id, []))
                game_scores[player_id] = score
            
            # End the game with calculated scores
            try:
                end_result = game._end_game(game_scores)
                self.logger.info(f"Game ended - Winner: {end_result.get('winner', 'Unknown')}")
                
                # Now notify the match that the game is complete
                if match:
                    match_result = match.complete_current_game(game_scores)
                    if not match_result.get('success', True):
                        self.logger.warning(f"Match completion failed: {match_result.get('error')}")
                
            except Exception as e:
                self.logger.error(f"Error ending game: {e}")
    
    def run_tournament(
        self,
        strategies: List[str],
        rounds_per_matchup: int = 5,
        games_per_match: int = 13
    ) -> Dict:
        """Run a round-robin tournament between strategies"""
        
        if not self.current_session_id:
            self.create_test_session("Round-robin tournament")
        
        tournament_results = {
            "tournament_id": f"tournament_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "strategies": strategies,
            "rounds_per_matchup": rounds_per_matchup,
            "games_per_match": games_per_match,
            "matches": [],
            "summary": {}
        }
        
        # Generate all possible matchups
        matchups = []
        for i in range(len(strategies)):
            for j in range(i + 1, len(strategies)):
                matchups.append((strategies[i], strategies[j]))
        
        self.logger.info(f"Starting tournament: {len(matchups)} unique matchups, {rounds_per_matchup} rounds each")
        self.logger.info(f"Total matches: {len(matchups) * rounds_per_matchup}")
        
        # Run all matchups
        for matchup in matchups:
            strategy1, strategy2 = matchup
            self.logger.info(f"--- {strategy1} vs {strategy2} ---")
            
            matchup_results = []
            for round_num in range(rounds_per_matchup):
                self.logger.info(f"Round {round_num + 1}/{rounds_per_matchup}")
                
                ai_configs = [
                    {"name": f"{strategy1}_AI", "strategy": strategy1},
                    {"name": f"{strategy2}_AI", "strategy": strategy2}
                ]
                
                match_result = self.run_single_match(
                    ai_configs, 
                    games_per_match,
                    f"tournament_{strategy1}_vs_{strategy2}_r{round_num + 1}"
                )
                
                matchup_results.append(match_result)
                tournament_results["matches"].append(match_result)
        
        # Calculate tournament summary
        strategy_stats = {strategy: {
            "matches_played": 0,
            "matches_won": 0,
            "total_games_won": 0,
            "total_games_played": 0,
            "average_score": 0,
            "scores": []
        } for strategy in strategies}
        
        for match in tournament_results["matches"]:
            for player_name, player_data in match["players"].items():
                # Extract strategy from player name
                strategy = player_data["strategy"]
                if strategy in strategy_stats:
                    stats = strategy_stats[strategy]
                    stats["matches_played"] += 1
                    if match["winner"] == player_name:
                        stats["matches_won"] += 1
                    stats["total_games_won"] += player_data["games_won"]
                    stats["total_games_played"] += match["games_played"]
                    stats["scores"].append(player_data["total_score"])
        
        # Calculate final statistics
        for strategy, stats in strategy_stats.items():
            if stats["scores"]:
                stats["average_score"] = round(statistics.mean(stats["scores"]), 1)
                stats["win_rate"] = round(stats["matches_won"] / stats["matches_played"] * 100, 1) if stats["matches_played"] > 0 else 0
                stats["game_win_rate"] = round(stats["total_games_won"] / stats["total_games_played"] * 100, 1) if stats["total_games_played"] > 0 else 0
        
        tournament_results["summary"] = strategy_stats
        
        # Save tournament results
        tournament_file = self.results_dir / f"tournament_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(tournament_file, 'w') as f:
            json.dump(tournament_results, f, indent=2)
        
        self.logger.info(f"=== TOURNAMENT RESULTS ===")
        for strategy, stats in sorted(strategy_stats.items(), key=lambda x: x[1]["win_rate"], reverse=True):
            self.logger.info(f"{strategy:20} | {stats['win_rate']:5.1f}% match wins | {stats['game_win_rate']:5.1f}% game wins | {stats['average_score']:5.1f} avg score")
        
        return tournament_results
    
    def save_match_result(self, match_result: Dict) -> None:
        """Save a single match result to the current session"""
        if not self.current_session_id:
            self.create_test_session()
        
        session_file = self.results_dir / f"{self.current_session_id}.json"
        
        # Load existing session
        with open(session_file, 'r') as f:
            session_data = json.load(f)
        
        # Add match result
        session_data["matches"].append(match_result)
        
        # Update session
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)
        
        self.logger.info(f"Saved match result to session {self.current_session_id}")