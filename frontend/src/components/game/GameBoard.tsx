import React, { useState, useEffect } from 'react';
import PlayerHand from './PlayerHand';
import Boneyard from './Boneyard';
import Train from './Train';

interface DominoData {
  left: number;
  right: number;
  id: string;
}

interface TrainData {
  dominoes: DominoData[];
  is_open: boolean;
  needs_double_satisfaction: boolean;
}

interface GameBoardProps {
  gameState: any;
  playerName: string;
  websocket: WebSocket | null;
  isSpectator: boolean;
  validMoves?: any[];
  mustDraw?: boolean;
}

export const GameBoard: React.FC<GameBoardProps> = ({
  gameState,
  playerName,
  websocket,
  isSpectator,
  validMoves = [],
  mustDraw: mustDrawProp = false
}) => {
  const [selectedDomino, setSelectedDomino] = useState<DominoData | null>(null);
  const [playerHand, setPlayerHand] = useState<DominoData[]>([]);
  const [moveInProgress, setMoveInProgress] = useState<boolean>(false);
  
  // Check if it's the current player's turn (moved before useEffects)
  const isMyTurn = gameState?.current_player === playerName && !isSpectator;
  
  console.log('🎮 GAMEBOARD RENDERED - playerName:', playerName, 'isMyTurn:', isMyTurn);
  console.log('🎮 GAME STATE TRAINS:', gameState?.trains);
  console.log('🎮 SELECTED DOMINO:', selectedDomino);
  console.log('🎮 VALID MOVES COUNT:', validMoves.length);

  // Parse player hand from game state
  useEffect(() => {
    if (gameState?.player_hands && gameState.player_hands[playerName]) {
      const newHand = gameState.player_hands[playerName];
      console.log('📋 UPDATING PLAYER HAND:', {
        oldCount: playerHand.length,
        newCount: newHand.length,
        newDominos: newHand.map((d: any) => `${d.left}-${d.right}`)
      });
      setPlayerHand(newHand);
    }
  }, [gameState, playerName]);

  // Track validMoves updates
  useEffect(() => {
    console.log('🔄 VALID MOVES UPDATED (via prop):', validMoves.length, validMoves);
  }, [validMoves]);

  // Track selectedDomino updates  
  useEffect(() => {
    console.log('🔄 SELECTED DOMINO UPDATED:', selectedDomino);
  }, [selectedDomino]);

  // Check for valid moves when it becomes player's turn
  useEffect(() => {
    if (isMyTurn && websocket && !isSpectator) {
      console.log('🎮 MY TURN! Checking for valid moves...');
      
      // Request all valid moves for this player
      websocket.send(JSON.stringify({
        type: 'get_all_valid_moves',
        player_id: playerName
      }));
    }
  }, [isMyTurn, websocket, playerName, isSpectator]);

  // Handle domino selection
  const handleDominoSelect = (domino: DominoData) => {
    console.log('🎯 DOMINO CLICKED:', domino);
    console.log('   Is my turn?', isMyTurn);
    console.log('   Current player:', gameState?.current_player);
    console.log('   My name:', playerName);
    
    if (!isMyTurn) {
      console.log('   ❌ Not my turn, ignoring click');
      return;
    }
    
    if (selectedDomino?.id === domino.id) {
      console.log('   Deselecting domino');
      setSelectedDomino(null);
      console.log('   State after deselection:', null);
    } else {
      console.log('   ✅ Selecting domino:', domino.left + '-' + domino.right);
      setSelectedDomino(domino);
      console.log('   State should now be:', domino);
      // Request valid moves for this domino
      if (websocket) {
        console.log('   📤 Requesting valid moves for this domino');
        websocket.send(JSON.stringify({
          type: 'get_valid_moves',
          domino: domino
        }));
      }
    }
  };

  // Handle playing a domino on a train
  const handlePlayDomino = (trainType: string, trainOwner?: string) => {
    console.log('🚂 TRAIN CLICKED!');
    console.log('   Train type:', trainType);
    console.log('   Train owner:', trainOwner);
    console.log('   Selected domino:', selectedDomino);
    console.log('   Is my turn?', isMyTurn);
    console.log('   WebSocket connected?', !!websocket);
    console.log('   Move in progress?', moveInProgress);
    
    if (!selectedDomino || !isMyTurn || !websocket || moveInProgress) {
      console.log('   ❌ Cannot play - missing requirements');
      console.log('      - Selected domino:', !!selectedDomino);
      console.log('      - Is my turn:', isMyTurn);
      console.log('      - WebSocket:', !!websocket);
      console.log('      - Not busy:', !moveInProgress);
      return;
    }

    console.log('   ✅ Sending move to server...');
    console.log('   Move details:', {
      type: 'make_move',
      player_id: playerName,
      domino: selectedDomino,
      train_type: trainType,
      train_owner: trainOwner
    });
    
    setMoveInProgress(true);
    
    websocket.send(JSON.stringify({
      type: 'make_move',
      player_id: playerName,
      domino: selectedDomino,
      train_type: trainType,
      train_owner: trainOwner
    }));

    // Don't clear selection immediately - wait for response
    setTimeout(() => {
      setMoveInProgress(false);
      setSelectedDomino(null);
      console.log('   Move timeout - clearing selection');
    }, 1000);
  };

  // Handle drawing from boneyard
  const handleDrawDomino = () => {
    if (!isMyTurn || !websocket) return;

    console.log('🎲 DRAWING FROM BONEYARD...');
    websocket.send(JSON.stringify({
      type: 'draw_domino',
      player_id: playerName
    }));
  };

  // Check if a train is potentially playable (before domino selection)
  const isTrainOpen = (trainType: string, trainOwner?: string, isOpen?: boolean): boolean => {
    if (!isMyTurn) return false;
    
    // Mexican train is always open
    if (trainType === 'mexican') return true;
    
    // Your own train is always playable
    if (trainType === 'personal' && trainOwner === playerName) return true;
    
    // Other players' trains only if open
    if (trainType === 'personal' && trainOwner !== playerName) return isOpen || false;
    
    return false;
  };
  
  // Check if a specific domino can be played on a train
  const canPlayOnTrain = (trainType: string, trainOwner?: string): boolean => {
    // If no domino selected, show if train is open for play
    if (!selectedDomino) {
      return isTrainOpen(trainType, trainOwner, 
        trainType === 'personal' ? gameState?.trains?.[trainOwner as string]?.is_open : true);
    }
    
    // If domino selected, check valid moves for that specific domino
    console.log('🚂 CAN PLAY ON TRAIN CHECK:', {
      trainType,
      trainOwner,
      isMyTurn,
      selectedDomino: selectedDomino ? `${selectedDomino.left}-${selectedDomino.right}` : null,
      validMovesCount: validMoves.length,
      validMoves: validMoves.map(m => `${m.train}(${m.train_owner || 'none'})`)
    });
    
    if (!isMyTurn) return false;
    
    // Check valid moves
    const canPlay = validMoves.some(move => {
      // For Mexican train, check both undefined and null
      if (trainType === 'mexican') {
        return move.train === 'mexican' && (move.train_owner === null || move.train_owner === undefined);
      }
      // For personal trains
      return move.train === trainType && move.train_owner === trainOwner;
    });
    
    console.log('🚂 RESULT:', canPlay);
    return canPlay;
  };

  // Get other players (excluding current player)
  const otherPlayers = gameState?.players?.filter((p: string) => p !== playerName) || [];

  return (
    <div className="game-board min-h-screen bg-gradient-to-br from-green-50 to-blue-50 p-4">
      {/* Game Header */}
      <div className="mb-4 bg-white rounded-lg shadow p-4">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold">Mexican Train Game</h2>
            <p className="text-gray-600">
              Round {gameState?.current_round || 12} • Engine: {gameState?.engine_value || 12}-{gameState?.engine_value || 12}
            </p>
          </div>
          <div className="text-right">
            <p className="text-sm text-gray-600">Current Turn:</p>
            <p className="text-lg font-semibold">
              {gameState?.current_player || 'Loading...'}
              {gameState?.current_player === playerName && ' (You)'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-4">
        {/* Left Side - Boneyard and Score */}
        <div className="col-span-2">
          <Boneyard
            count={gameState?.boneyard_count || 0}
            isCurrentPlayerTurn={isMyTurn}
            canDraw={isMyTurn && validMoves.length === 0}
            onDrawDomino={handleDrawDomino}
          />
          
          {/* Round Scores */}
          {gameState?.round_scores && (
            <div className="mt-4 bg-white rounded-lg shadow p-4">
              <h3 className="font-semibold mb-2">Scores</h3>
              <div className="text-sm space-y-1">
                {Object.entries(gameState.round_scores).map(([player, scores]: [string, any]) => (
                  <div key={player} className="flex justify-between">
                    <span>{player}:</span>
                    <span className="font-medium">
                      {(scores as number[]).reduce((a: number, b: number) => a + b, 0)}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Center - Game Trains */}
        <div className="col-span-7 space-y-3">
          {/* Personal Trains */}
          {gameState?.trains && Object.entries(gameState.trains).map(([owner, train]: [string, any]) => {
            const canPlay = canPlayOnTrain('personal', owner);
            console.log(`🚃 RENDERING TRAIN for ${owner}:`, {
              canPlayHere: canPlay,
              isOpen: train.is_open,
              dominoes: train.dominoes?.length || 0
            });
            return (
              <Train
                key={owner}
                dominos={train.dominoes || []}
                trainType="personal"
                ownerName={owner}
                isOpen={train.is_open}
                needsDoubleSatisfaction={train.needs_double_satisfaction}
                canPlayHere={canPlay}
                onPlayDomino={() => handlePlayDomino('personal', owner)}
                engineValue={gameState.engine_value}
                isCurrentPlayerTrain={owner === playerName}
              />
            );
          })}

          {/* Mexican Train */}
          {gameState?.mexican_train && (
            <Train
              dominos={gameState.mexican_train.dominoes || []}
              trainType="mexican"
              isOpen={true}
              needsDoubleSatisfaction={gameState.mexican_train.needs_double_satisfaction}
              canPlayHere={canPlayOnTrain('mexican')}
              onPlayDomino={() => handlePlayDomino('mexican')}
              engineValue={gameState.engine_value}
            />
          )}
        </div>

        {/* Right Side - Other Players' Hands */}
        <div className="col-span-3 space-y-3">
          {/* Other Players */}
          {otherPlayers.map((player: string) => (
            <div key={player} className="bg-white rounded-lg shadow p-3">
              <div className="flex justify-between items-center">
                <span className="font-medium">{player}</span>
                <span className="text-sm text-gray-600">
                  {gameState?.player_hand_counts?.[player] || 0} tiles
                </span>
              </div>
              {gameState?.ai_players?.includes(player) && (
                <span className="text-xs text-blue-600">🤖 AI Player</span>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Bottom - Player's Hand */}
      {!isSpectator && playerHand && (
        <div className="mt-6">
          <PlayerHand
            dominos={playerHand}
            isCurrentPlayer={isMyTurn}
            playerName={playerName}
            isMyHand={true}
            onDominoClick={handleDominoSelect}
            selectedDomino={selectedDomino?.id}
          />
        </div>
      )}

      {/* Spectator Notice */}
      {isSpectator && (
        <div className="mt-6 bg-purple-50 border border-purple-200 rounded-lg p-4 text-center">
          <p className="text-purple-800">
            👀 You are spectating this game. Player hands are hidden.
          </p>
        </div>
      )}

      {/* Must Draw Notification */}
      {isMyTurn && mustDrawProp && !selectedDomino && (
        <div className="fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-orange-500 text-white px-6 py-3 rounded-lg shadow-lg border-l-4 border-orange-400">
          <div className="flex items-center">
            <div className="text-2xl mr-3">⚠️</div>
            <div>
              <div className="font-semibold">No Valid Moves!</div>
              <div className="text-sm">Click the Boneyard to draw a domino</div>
            </div>
          </div>
        </div>
      )}

      {/* Game Status Messages */}
      {gameState?.message && (
        <div className="fixed bottom-4 right-4 bg-blue-500 text-white px-4 py-2 rounded-lg shadow-lg animate-pulse">
          {gameState.message}
        </div>
      )}
    </div>
  );
};

export default GameBoard;