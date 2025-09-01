import React, { useState } from 'react';
import Domino from './Domino';

interface BoneyardProps {
  count: number;
  isCurrentPlayerTurn: boolean;
  canDraw: boolean;
  onDrawDomino: () => void;
}

export const Boneyard: React.FC<BoneyardProps> = ({
  count,
  isCurrentPlayerTurn,
  canDraw,
  onDrawDomino
}) => {
  const [isHovered, setIsHovered] = useState(false);
  const [isDrawing, setIsDrawing] = useState(false);

  const handleDraw = async () => {
    console.log('🎯 BONEYARD CLICKED!', { canDraw, isDrawing, count });
    if (!canDraw || isDrawing) {
      console.log('   ❌ Cannot draw:', { canDraw, isDrawing });
      return;
    }
    
    console.log('   ✅ Drawing from boneyard...');
    setIsDrawing(true);
    try {
      await onDrawDomino();
    } finally {
      setTimeout(() => setIsDrawing(false), 500);
    }
  };

  // Create a stacked appearance for the boneyard
  const renderStackedDominos = () => {
    const maxVisible = Math.min(5, count);
    const dominos = [];
    
    for (let i = 0; i < maxVisible; i++) {
      const offset = i * 3;
      const rotation = (i - 2) * 3; // Slight rotation for visual interest
      
      dominos.push(
        <div
          key={i}
          className="absolute"
          style={{
            top: `${offset}px`,
            left: `${offset}px`,
            transform: `rotate(${rotation}deg)`,
            zIndex: maxVisible - i
          }}
        >
          <Domino
            left={0}
            right={0}
            showBack={true}
            size="medium"
          />
        </div>
      );
    }
    
    return dominos;
  };

  return (
    <div className="boneyard-container">
      <div className={`
        boneyard p-6 rounded-lg
        ${canDraw && isCurrentPlayerTurn ? 'bg-green-50 border-2 border-green-400' : 'bg-gray-100 border border-gray-300'}
        transition-all duration-300
      `}>
        {/* Header */}
        <div className="mb-4">
          <h3 className="font-bold text-lg">Boneyard</h3>
          <p className="text-sm text-gray-600">
            {count} {count === 1 ? 'domino' : 'dominos'} remaining
          </p>
        </div>

        {/* Domino Stack */}
        <div
          className={`
            relative inline-block
            ${canDraw && isCurrentPlayerTurn ? 'cursor-pointer' : 'cursor-not-allowed'}
          `}
          style={{ width: '100px', height: '65px' }}
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
          onClick={handleDraw}
        >
          {count > 0 ? (
            <div className={`
              transition-transform duration-200
              ${isHovered && canDraw && isCurrentPlayerTurn ? 'scale-105' : ''}
              ${isDrawing ? 'animate-pulse' : ''}
            `}>
              {renderStackedDominos()}
            </div>
          ) : (
            <div className="flex items-center justify-center h-full">
              <p className="text-gray-500 text-center">
                Boneyard<br />Empty
              </p>
            </div>
          )}
        </div>

        {/* Draw Button/Instructions */}
        {isCurrentPlayerTurn && (
          <div className="mt-4">
            {canDraw ? (
              <button
                onClick={handleDraw}
                disabled={isDrawing || count === 0}
                className={`
                  w-full px-4 py-2 rounded font-medium text-white
                  ${isDrawing || count === 0
                    ? 'bg-gray-400 cursor-not-allowed'
                    : 'bg-green-600 hover:bg-green-700 active:bg-green-800'
                  }
                  transition-colors duration-200
                `}
              >
                {isDrawing ? 'Drawing...' : count === 0 ? 'Empty - Will Pass Turn' : 'Draw One Domino'}
              </button>
            ) : (
              <p className="text-sm text-gray-600 text-center">
                You must play a domino if possible
              </p>
            )}
            {canDraw && count === 0 && (
              <p className="text-xs text-gray-500 text-center mt-2">
                No dominoes left. Your turn will be passed.
              </p>
            )}
          </div>
        )}

        {/* Visual feedback when hovering */}
        {isHovered && canDraw && isCurrentPlayerTurn && count > 0 && (
          <div className="mt-2 text-xs text-green-600 text-center animate-pulse">
            Click to draw a domino
          </div>
        )}
      </div>
    </div>
  );
};

export default Boneyard;