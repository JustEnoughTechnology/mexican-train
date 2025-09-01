import React, { useState } from 'react';
import Domino from './Domino';

interface DominoData {
  left: number;
  right: number;
  id: string;
}

interface PlayerHandProps {
  dominos: DominoData[];
  isCurrentPlayer: boolean;
  playerName: string;
  isMyHand: boolean;
  onDominoClick?: (domino: DominoData) => void;
  selectedDomino?: string | null;
}

export const PlayerHand: React.FC<PlayerHandProps> = ({
  dominos,
  isCurrentPlayer,
  playerName,
  isMyHand,
  onDominoClick,
  selectedDomino
}) => {
  const [hoveredDomino, setHoveredDomino] = useState<string | null>(null);

  // Sort dominos by total pip value for better organization
  const sortedDominos = [...dominos].sort((a, b) => {
    const aTotal = a.left + a.right;
    const bTotal = b.left + b.right;
    return bTotal - aTotal; // Highest value first
  });

  return (
    <div className={`
      player-hand p-4 rounded-lg
      ${isCurrentPlayer ? 'bg-yellow-50 border-2 border-yellow-400' : 'bg-gray-50 border border-gray-300'}
      ${isMyHand ? 'shadow-lg' : 'shadow'}
    `}>
      {/* Header */}
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-semibold text-lg">
          {playerName}
          {isMyHand && " (You)"}
        </h3>
        <div className="flex items-center gap-2">
          {isCurrentPlayer && (
            <span className="px-2 py-1 bg-yellow-200 text-yellow-800 text-xs rounded-full">
              Current Turn
            </span>
          )}
          <span className="px-2 py-1 bg-gray-200 text-gray-700 text-xs rounded-full">
            {dominos.length} tiles
          </span>
        </div>
      </div>

      {/* Dominos Container */}
      <div className="dominos-container">
        {isMyHand ? (
          // Show actual dominos for player's own hand
          <div className="flex flex-wrap gap-2">
            {sortedDominos.map((domino) => (
              <div
                key={domino.id}
                onMouseEnter={() => setHoveredDomino(domino.id)}
                onMouseLeave={() => setHoveredDomino(null)}
                className={`
                  transition-all duration-200
                  ${hoveredDomino === domino.id ? 'transform -translate-y-2' : ''}
                `}
              >
                <Domino
                  left={domino.left}
                  right={domino.right}
                  id={domino.id}
                  isClickable={isCurrentPlayer && !!onDominoClick}
                  isSelected={selectedDomino === domino.id}
                  onClick={() => {
                    console.log('🤚 PLAYER HAND CLICKED:', domino);
                    onDominoClick?.(domino);
                  }}
                  size="medium"
                />
              </div>
            ))}
          </div>
        ) : (
          // Show backs of dominos for other players
          <div className="flex flex-wrap gap-1">
            {sortedDominos.map((domino, index) => (
              <div key={domino.id || index} className="inline-block">
                <Domino
                  left={0}
                  right={0}
                  showBack={true}
                  size="small"
                />
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Instructions for current player */}
      {isMyHand && isCurrentPlayer && (
        <div className="mt-3 p-2 bg-blue-50 rounded text-sm text-blue-700">
          Click a domino to select it, then click where you want to play it.
        </div>
      )}
    </div>
  );
};

export default PlayerHand;