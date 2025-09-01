import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { useSession } from 'next-auth/react';
import GameBoard from '../../components/game/GameBoard';

interface GamePageProps {}

export default function GamePage({}: GamePageProps) {
  const router = useRouter();
  const { gameId } = router.query;
  const { data: session } = useSession();
  
  const [gameState, setGameState] = useState<any>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [websocket, setWebsocket] = useState<WebSocket | null>(null);
  const [userHandle, setUserHandle] = useState<string>('');
  const [displayName, setDisplayName] = useState<string>('');
  const [userType, setUserType] = useState<string>('');
  const [joinResult, setJoinResult] = useState<{success?: boolean, message?: string, error?: string} | null>(null);
  const [isSpectator, setIsSpectator] = useState<boolean>(false);
  const [startGameLoading, setStartGameLoading] = useState<boolean>(false);
  const [validMoves, setValidMoves] = useState<any[]>([]);
  const [mustDraw, setMustDraw] = useState<boolean>(false);
  const [notification, setNotification] = useState<{message: string, type: 'success' | 'error' | 'info'} | null>(null);
  const [gameEndedData, setGameEndedData] = useState<{
    winner: string,
    final_scores: {[key: string]: number},
    is_match_game?: boolean,
    game_number?: number,
    match_id?: string
  } | null>(null);
  const [matchEndedData, setMatchEndedData] = useState<{
    winner: string,
    final_scores: {[key: string]: number},
    game_history: Array<{game_number: number, winner: string, scores: {[key: string]: number}}>,
    total_games: number
  } | null>(null);

  // Helper function to show notifications
  const showNotification = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 4000); // Auto-dismiss after 4 seconds
  };

  // Function to start the game (for host only)
  const handleStartGame = (forceStart: boolean = false) => {
    if (!websocket || !gameState || gameState.host !== displayName) {
      console.error('Cannot start game: not connected or not host');
      return;
    }

    setStartGameLoading(true);
    console.log('🚀 Sending start game request...');
    
    websocket.send(JSON.stringify({
      type: 'start_game',
      player_name: displayName,
      force: forceStart
    }));
  };

  // Get current user identity from sessionStorage
  useEffect(() => {
    const handle = sessionStorage.getItem('userHandle');
    const tabDisplayName = sessionStorage.getItem('displayName');
    const storedUserType = sessionStorage.getItem('userType');
    
    if (handle && tabDisplayName && storedUserType) {
      setUserHandle(handle);
      setDisplayName(tabDisplayName);
      setUserType(storedUserType);
    } else {
      // Redirect to home if no user identity for this tab
      router.push('/');
      return;
    }
  }, [router]);

  // Update browser title with match info (everything is a match now)
  useEffect(() => {
    const serverHost = window.location.host;
    let title = `Mexican Train - ${serverHost}`;
    
    if (gameId) {
      if (gameState) {
        // Everything is a match now
        const matchId = gameState.match_id || gameId;
        const gameNumber = gameState.game_number || gameState.current_game_number || 1;
        const totalGames = gameState.games_to_play || 1;
        
        if (totalGames === 1) {
          title += ` - Match ${matchId}`;
        } else {
          title += ` - Match ${matchId} - Game ${gameNumber}/${totalGames}`;
        }
        
        if (displayName) {
          title += ` - ${displayName}`;
        }
      } else {
        title += ` - Match ${gameId}`;
        if (displayName) {
          title += ` - ${displayName}`;
        }
      }
    }
    
    document.title = title;
  }, [gameId, gameState, displayName]);

  // WebSocket connection
  useEffect(() => {
    if (!gameId || !userHandle || !displayName) {
      console.log('Game WebSocket: waiting for gameId, userHandle, and displayName', {gameId, userHandle, displayName});
      return;
    }

    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${wsProtocol}//${window.location.host}/ws/game/${gameId}?user_id=${encodeURIComponent(userHandle)}&display_name=${encodeURIComponent(displayName)}`;
    
    console.log('=== GAME WEBSOCKET CONNECTING ===');
    console.log('Game ID:', gameId);
    console.log('User Handle:', userHandle);
    console.log('Display Name:', displayName);
    console.log('WebSocket URL:', wsUrl);
    
    const ws = new WebSocket(wsUrl);
    
    // Override send to log all outgoing messages
    const originalSend = ws.send.bind(ws);
    ws.send = function(data: string | ArrayBuffer | Blob | ArrayBufferView) {
      console.log('📤 SENDING WebSocket message:', typeof data === 'string' ? JSON.parse(data) : data);
      return originalSend(data);
    };
    
    ws.onopen = () => {
      console.log('✅ Connected to game:', gameId, 'as', displayName, `(${userHandle})`);
      console.log('📡 WebSocket opened - ready to send/receive messages');
      setIsConnected(true);
      
      // Check if this is a join or spectate action
      const urlParams = new URLSearchParams(window.location.search);
      const action = urlParams.get('action');
      
      if (action === 'join') {
        console.log('🔗 Attempting to join game...');
        ws.send(JSON.stringify({
          type: 'join_game',
          player_name: displayName
        }));
      } else if (action === 'spectate') {
        console.log('👀 Attempting to spectate game...');
        setIsSpectator(true);
        ws.send(JSON.stringify({
          type: 'spectate_game',
          spectator_name: displayName
        }));
      }
      
      if (action) {
        // Clean up URL
        const newUrl = new URL(window.location.href);
        newUrl.searchParams.delete('action');
        window.history.replaceState({}, '', newUrl.toString());
      }
    };
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      console.log('📥 RECEIVED WebSocket message:', message.type);
      console.log('   Full message:', message);
      console.log('   Message type check: message.type === "valid_moves"?', message.type === 'valid_moves');
      
      switch (message.type) {
        case 'game_state':
          setGameState(message.data);
          break;
          
        case 'join_result':
          setJoinResult(message);
          if (message.success) {
            if (message.already_in_game) {
              console.log('🔄 Reconnected to game:', message.message);
            } else {
              console.log('✅ Successfully joined game:', message.message);
            }
          } else {
            console.error('❌ Failed to join game:', message.error);
          }
          break;
          
        case 'spectate_result':
          setJoinResult(message);
          if (message.success) {
            console.log('👀 Successfully started spectating:', message.message);
            setIsSpectator(true);
          } else {
            console.error('❌ Failed to spectate game:', message.error);
          }
          break;
          
        case 'player_joined':
          console.log('👤 Player joined:', message.data.player_name);
          if (message.data.game_started) {
            console.log('🎯 Game has started with multiple players!');
          }
          break;
          
        case 'game_started':
          console.log('🎮 Game Started:', message.data.message);
          setStartGameLoading(false);
          // Update game state if provided
          if (message.data.game_state) {
            setGameState(message.data.game_state);
          }
          break;
          
        case 'start_game_result':
          setStartGameLoading(false);
          if (message.success) {
            console.log('✅ Game start successful:', message.message);
          } else {
            console.error('❌ Failed to start game:', message.error);
            alert(`Failed to start game: ${message.error}`);
          }
          break;
          
        case 'spectator_joined':
          console.log('👀 Spectator joined:', message.data.spectator_name);
          break;
          
        case 'spectator_left':
          console.log('👋 Spectator left:', message.data.spectator_name);
          break;
          
        case 'move_result':
          console.log('🎲 Move result:', message.data);
          if (!message.data.success) {
            alert(`Move failed: ${message.data.error}`);
          }
          break;
          
        case 'valid_moves':
          console.log('✅ Valid moves:', message.moves);
          console.log('🔄 SETTING VALID MOVES STATE:', message.moves || []);
          setValidMoves(message.moves || []);
          // Clear mustDraw when specific valid moves are received (domino selected)
          setMustDraw(false);
          break;
          
        case 'draw_result':
          console.log('📦 Draw result:', message.data);
          if (message.data.success && message.data.domino) {
            const drewDomino = `${message.data.domino.left}-${message.data.domino.right}`;
            console.log('   Drew domino:', drewDomino);
            
            // Handle different draw outcomes
            if (message.data.can_play_drawn) {
              console.log('   ✅ Can play the drawn domino - turn continues');
              showNotification(`Drew ${drewDomino} - you can play it!`, 'success');
            } else if (message.data.turn_passed) {
              console.log('   ⏭️ Cannot play drawn domino - turn passed to:', message.data.next_player);
              showNotification(
                `Drew ${drewDomino} but couldn't play it. Turn passed to ${message.data.next_player}`, 
                'info'
              );
            }
            
            if (message.data.train_opened && message.data.player_id === displayName) {
              console.log('   🚂 Your train is now open');
              showNotification('Your train is now marked as open', 'info');
            }
          } else if (!message.data.success) {
            console.log('   ❌ Draw failed:', message.data.error);
            showNotification(message.data.error || 'Failed to draw domino', 'error');
          }
          break;
          
        case 'ai_move':
          console.log('🤖 AI Move:', message.data.player, message.data.result);
          break;

        case 'ai_move_result':
          console.log('🤖 AI Move Result:', message.data);
          if (message.data.action === 'drew_and_passed') {
            showNotification(`${message.data.message}`, 'info');
          } else if (message.data.action === 'passed_empty_boneyard') {
            showNotification(`${message.data.message}`, 'info');
          }
          break;
          
        case 'ai_error':
          console.error('❌ AI Error:', message.data.player, message.data.error);
          showNotification(`AI Error (${message.data.player}): ${message.data.error}`, 'error');
          break;
          
        case 'game_error':
          console.error('❌ Game Error:', message.data.error);
          alert(`Game Error: ${message.data.error}`);
          break;
          
        case 'game_ended':
          console.log('🎉 Game Ended:', message.data);
          setGameEndedData({
            winner: message.data.winner,
            final_scores: message.data.final_scores,
            is_match_game: message.data.is_match_game,
            game_number: message.data.game_number,
            match_id: message.data.match_id
          });
          break;
          
        case 'match_ended':
          console.log('🏆 Match Ended:', message.data);
          setMatchEndedData({
            winner: message.data.winner,
            final_scores: message.data.final_scores,
            game_history: message.data.game_history,
            total_games: message.data.total_games || message.data.game_history?.length || 0
          });
          // Clear any game-ended modal if it's showing
          setGameEndedData(null);
          break;
          
        case 'all_valid_moves':
          console.log('📋 All valid moves check:', {
            canPlay: message.can_play,
            mustDraw: message.must_draw,
            moveCount: message.moves?.length || 0
          });
          
          // If player must draw, show a notification
          if (message.must_draw && message.message) {
            console.log('⚠️ ' + message.message);
            // Could also show a toast/alert here
          }
          
          // Store all valid moves for reference
          setValidMoves(message.moves || []);
          setMustDraw(message.must_draw || false);
          break;
          
        default:
          console.log('⚠️ Unhandled message type:', message.type);
      }
      // Handle other message types as needed
    };
    
    ws.onclose = () => {
      console.log('Disconnected from game:', gameId);
      setIsConnected(false);
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
      setIsConnected(false);
    };
    
    setWebsocket(ws);
    
    return () => {
      ws.close();
    };
  }, [gameId, userHandle, displayName]);

  if (!gameId) {
    return <div className="p-4">Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-100 p-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold">
                {typeof gameId === 'string' && gameId.match(/^\d+$/) 
                  ? `Game #${gameId}` 
                  : `Game: ${gameId}`}
              </h1>
              <div className="text-gray-600">
                <p>
                  {isSpectator ? 'Spectating as:' : 'Playing as:'} 
                  <span className="font-medium">{displayName}</span>
                  {isSpectator && (
                    <span className="ml-2 px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded-full">
                      👀 Spectator
                    </span>
                  )}
                </p>
                {userType === 'authenticated' && (
                  <p className="text-xs">Account: @{userHandle}</p>
                )}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className={`px-3 py-1 rounded-full text-sm ${
                isConnected ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {isConnected ? 'Connected' : 'Disconnected'}
              </div>
              <button
                onClick={() => router.push('/lobby')}
                className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
              >
                Back to Lobby
              </button>
            </div>
          </div>
        </div>

        {/* Join Result Notification */}
        {joinResult && (
          <div className={`mb-6 p-4 rounded-lg ${
            joinResult.success 
              ? 'bg-green-100 border border-green-300 text-green-800'
              : 'bg-red-100 border border-red-300 text-red-800'
          }`}>
            {joinResult.success 
              ? (joinResult.already_in_game ? '🔄' : '✅') 
              : '❌'
            } {joinResult.message || joinResult.error}
          </div>
        )}

        {/* Game Content */}
        {gameState && gameState.started ? (
          // Show full game board if game has started
          <GameBoard
            gameState={gameState}
            playerName={displayName}
            websocket={websocket}
            isSpectator={isSpectator}
            validMoves={validMoves}
            mustDraw={mustDraw}
          />
        ) : (
          // Show waiting room if game hasn't started
          <div className="bg-white rounded-lg shadow-md p-6">
            {gameState ? (
              <div>
              <h2 className="text-xl font-semibold mb-4">
                Game State 
                {gameState.players && (
                  <span className="text-sm text-gray-600 ml-2">
                    ({gameState.players.length}/{gameState.max_players || 4} players)
                  </span>
                )}
                {gameState.started && (
                  <span className="ml-2 px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                    🎯 Active
                  </span>
                )}
                {!gameState.started && gameState.players && gameState.players.length > 1 && (
                  <span className="ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full">
                    ⏳ Ready to Start
                  </span>
                )}
              </h2>
              {gameState.players && (
                <div className="mb-4 p-3 bg-blue-50 rounded">
                  <h3 className="font-medium text-blue-900 mb-2">Players:</h3>
                  <div className="flex flex-wrap gap-2">
                    {gameState.players.map((player: string, index: number) => (
                      <span 
                        key={player}
                        className={`px-3 py-1 rounded-full text-sm ${
                          player === displayName && !isSpectator
                            ? 'bg-blue-200 text-blue-900 font-medium' 
                            : 'bg-gray-200 text-gray-700'
                        }`}
                      >
                        {player} {index === 0 && '👑'} {player === displayName && !isSpectator && '(You)'}
                      </span>
                    ))}
                  </div>
                  {gameState.spectators && gameState.spectators.length > 0 && (
                    <div className="mt-3">
                      <h4 className="font-medium text-purple-900 mb-2">
                        Spectators ({gameState.spectators.length}):
                      </h4>
                      <div className="flex flex-wrap gap-2">
                        {gameState.spectators.map((spectator: string) => (
                          <span 
                            key={spectator}
                            className={`px-3 py-1 rounded-full text-sm ${
                              spectator === displayName && isSpectator
                                ? 'bg-purple-200 text-purple-900 font-medium'
                                : 'bg-purple-100 text-purple-700'
                            }`}
                          >
                            👀 {spectator} {spectator === displayName && isSpectator && '(You)'}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
              
              {/* Host Controls */}
              {gameState && gameState.host === displayName && !gameState.started && !isSpectator && (
                <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
                  <h3 className="font-semibold text-green-900 mb-3">Host Controls</h3>
                  
                  {/* Game Info */}
                  <div className="mb-3 text-sm text-green-800">
                    <p>Players: {gameState.players?.length || 0} / {gameState.max_players || 4}</p>
                    <p>Minimum players required: {gameState.min_players || 2}</p>
                    {gameState.countdown_remaining && (
                      <p>Auto-start in: {Math.ceil(gameState.countdown_remaining / 60)} minutes</p>
                    )}
                    {gameState.ai_players && gameState.ai_players.length > 0 && (
                      <p>AI Players: {gameState.ai_players.join(', ')}</p>
                    )}
                  </div>
                  
                  {/* Start Game Buttons */}
                  <div className="flex gap-2">
                    {gameState.players?.length >= (gameState.min_players || 2) ? (
                      <button
                        onClick={() => handleStartGame(false)}
                        disabled={startGameLoading}
                        className={`px-4 py-2 rounded font-medium text-white ${
                          startGameLoading 
                            ? 'bg-gray-400 cursor-not-allowed' 
                            : 'bg-green-600 hover:bg-green-700'
                        }`}
                      >
                        {startGameLoading ? 'Starting...' : '🚀 Start Game'}
                      </button>
                    ) : (
                      <>
                        <button
                          onClick={() => handleStartGame(true)}
                          disabled={startGameLoading}
                          className={`px-4 py-2 rounded font-medium text-white ${
                            startGameLoading 
                              ? 'bg-gray-400 cursor-not-allowed' 
                              : 'bg-orange-600 hover:bg-orange-700'
                          }`}
                        >
                          {startGameLoading ? 'Starting...' : '⚡ Force Start'}
                        </button>
                        <span className="text-sm text-orange-700 self-center">
                          (Need {gameState.min_players || 2} players, have {gameState.players?.length || 0})
                        </span>
                      </>
                    )}
                  </div>
                </div>
              )}
              
              <pre className="bg-gray-100 p-4 rounded text-sm overflow-auto">
                {JSON.stringify(gameState, null, 2)}
              </pre>
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-600">Connecting to game...</p>
              </div>
            )}
          </div>
        )}

        {/* Multi-tab notice */}
        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-blue-800">
                Multi-Game Support
              </h3>
              <div className="mt-2 text-sm text-blue-700">
                <p>
                  You can open multiple browser tabs to play different games simultaneously! 
                  Each tab maintains its own connection to a specific game.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Match Ended Celebration Modal */}
        {matchEndedData && (
          <div className="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl p-8 max-w-lg mx-4 text-center shadow-2xl transform animate-pulse">
              {/* Grand Celebration Header */}
              <div className="mb-6">
                <div className="text-8xl mb-4">🏆</div>
                <h2 className="text-4xl font-bold text-gray-800 mb-2">
                  Match Champion!
                </h2>
                <div className="text-2xl font-bold text-purple-600 mb-2">
                  👑 {matchEndedData.winner} 👑
                </div>
                {matchEndedData.winner === displayName && (
                  <div className="text-xl text-gold-600 font-bold mt-3 animate-bounce">
                    🎊 VICTORY IS YOURS! 🎊
                  </div>
                )}
                <div className="text-sm text-gray-600 mt-2">
                  {matchEndedData.total_games} games completed
                </div>
              </div>

              {/* Final Match Scores */}
              <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg p-4 mb-6">
                <h3 className="font-bold text-gray-700 mb-4 text-lg">Final Match Standings</h3>
                <div className="space-y-3">
                  {Object.entries(matchEndedData.final_scores)
                    .sort(([,a], [,b]) => a - b) // Sort by total score (lowest first)
                    .map(([player, totalScore], index) => (
                    <div key={player} className={`flex justify-between items-center py-3 px-4 rounded-lg ${
                      index === 0 ? 'bg-gradient-to-r from-yellow-100 to-yellow-200 border-2 border-yellow-400' :
                      index === 1 ? 'bg-gray-100 border border-gray-300' :
                      index === 2 ? 'bg-orange-50 border border-orange-200' :
                      'bg-white border border-gray-200'
                    }`}>
                      <span className="font-bold text-lg">
                        {index === 0 && '🥇 '}
                        {index === 1 && '🥈 '}
                        {index === 2 && '🥉 '}
                        {player} {player === displayName && '(You)'}
                      </span>
                      <span className={`font-bold text-xl ${
                        index === 0 ? 'text-yellow-700' : 'text-gray-600'
                      }`}>
                        {totalScore}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Game History Summary */}
              <div className="bg-gray-50 rounded-lg p-4 mb-6">
                <h4 className="font-semibold text-gray-700 mb-3">Game Results</h4>
                <div className="grid grid-cols-2 gap-2 max-h-32 overflow-y-auto">
                  {matchEndedData.game_history.map((game, idx) => (
                    <div key={idx} className="text-xs bg-white rounded p-2 flex justify-between">
                      <span>Game {game.game_number}</span>
                      <span className="font-medium">{game.winner}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex space-x-3">
                <button
                  onClick={() => setMatchEndedData(null)}
                  className="flex-1 bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded-lg transition-colors"
                >
                  🎉 Celebrate!
                </button>
                <button
                  onClick={() => router.push('/lobby')}
                  className="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-4 rounded-lg transition-colors"
                >
                  Back to Lobby
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Game Ended Celebration Modal */}
        {gameEndedData && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl p-8 max-w-md mx-4 text-center shadow-2xl transform animate-bounce">
              {/* Celebration Header */}
              <div className="mb-6">
                <div className="text-6xl mb-4">🎉</div>
                <h2 className="text-3xl font-bold text-gray-800 mb-2">
                  Game Complete!
                </h2>
                <div className="text-xl font-semibold text-blue-600">
                  🏆 Winner: <span className="text-purple-600">{gameEndedData.winner}</span>
                </div>
                {gameEndedData.winner === displayName && (
                  <div className="text-lg text-green-600 font-medium mt-2">
                    🎊 Congratulations! 🎊
                  </div>
                )}
              </div>

              {/* Scores Display */}
              <div className="bg-gray-50 rounded-lg p-4 mb-6">
                <h3 className="font-semibold text-gray-700 mb-3">Final Scores</h3>
                <div className="space-y-2">
                  {Object.entries(gameEndedData.final_scores)
                    .sort(([,a], [,b]) => a - b) // Sort by score (lowest first)
                    .map(([player, score], index) => (
                    <div key={player} className={`flex justify-between items-center py-2 px-3 rounded ${
                      index === 0 ? 'bg-yellow-100 border border-yellow-300' : 'bg-white'
                    }`}>
                      <span className="font-medium">
                        {index === 0 && '🥇 '}{player} {player === displayName && '(You)'}
                      </span>
                      <span className={`font-bold ${
                        index === 0 ? 'text-yellow-600' : 'text-gray-600'
                      }`}>
                        {score}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Match Info (if this is part of a match) */}
              {gameEndedData.is_match_game && (
                <div className="bg-blue-50 rounded-lg p-3 mb-6">
                  <p className="text-sm text-blue-700">
                    <strong>Match Progress:</strong> Game {gameEndedData.game_number} completed
                  </p>
                  <p className="text-xs text-blue-600 mt-1">
                    Continue to the next game in this match!
                  </p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex space-x-3">
                <button
                  onClick={() => setGameEndedData(null)}
                  className="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                >
                  Continue Playing
                </button>
                <button
                  onClick={() => router.push('/lobby')}
                  className="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                >
                  Back to Lobby
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Notification Toast */}
        {notification && (
          <div className={`fixed bottom-4 right-4 p-4 rounded-lg shadow-lg border-l-4 max-w-sm z-40 animate-fade-in ${
            notification.type === 'success' ? 'bg-green-100 border-green-500 text-green-800' :
            notification.type === 'error' ? 'bg-red-100 border-red-500 text-red-800' :
            'bg-blue-100 border-blue-500 text-blue-800'
          }`}>
            <div className="flex">
              <div className="flex-shrink-0">
                {notification.type === 'success' ? '✅' : 
                 notification.type === 'error' ? '❌' : 'ℹ️'}
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium">{notification.message}</p>
              </div>
              <div className="ml-auto pl-3">
                <button 
                  onClick={() => setNotification(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}