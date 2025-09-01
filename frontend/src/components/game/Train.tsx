import React, { useState } from 'react';
import Domino from './Domino';

interface DominoData {
  left: number;
  right: number;
  id: string;
}

interface TrainProps {
  dominos: DominoData[];
  trainType: 'personal' | 'mexican';
  ownerName?: string;
  isOpen: boolean;
  needsDoubleSatisfaction: boolean;
  canPlayHere: boolean;
  onPlayDomino?: () => void;
  engineValue?: number;
  isCurrentPlayerTrain?: boolean;
}

export const Train: React.FC<TrainProps> = ({
  dominos,
  trainType,
  ownerName,
  isOpen,
  needsDoubleSatisfaction,
  canPlayHere,
  onPlayDomino,
  engineValue,
  isCurrentPlayerTrain = false
}) => {
  const [isHoveredEnd, setIsHoveredEnd] = useState(false);

  // Calculate the required value for the next domino
  const getRequiredValue = (): number => {
    if (dominos.length === 0) {
      return engineValue || 12; // Default to 12 if no engine specified
    }
    return dominos[dominos.length - 1].right;
  };

  // Render dominos in a line with slight overlap
  const renderTrainDominos = () => {
    return dominos.map((domino, index) => {
      const isDouble = domino.left === domino.right;
      
      return (
        <div
          key={domino.id}
          className="inline-block"
          style={{
            marginLeft: index === 0 ? '0' : '-1px',  // 1px overlap to share borders
            zIndex: index,
            transform: isDouble ? 'rotate(90deg) translateY(-10px)' : 'none'
          }}
        >
          <Domino
            left={domino.left}
            right={domino.right}
            id={domino.id}
            orientation="horizontal"
            size="small"
            isDouble={isDouble}
          />
        </div>
      );
    });
  };

  const trainColor = trainType === 'mexican' 
    ? 'bg-red-50 border-red-400' 
    : isCurrentPlayerTrain 
      ? 'bg-blue-50 border-blue-400'
      : 'bg-gray-50 border-gray-400';

  const trainStatusColor = isOpen
    ? 'bg-green-100 text-green-800'
    : 'bg-gray-100 text-gray-600';

  return (
    <div className={`
      train-container p-4 rounded-lg border-2 ${trainColor}
      ${canPlayHere ? 'shadow-lg ring-2 ring-green-400' : 'shadow'}
      transition-all duration-300
    `}>
      {/* Train Header */}
      <div className="flex justify-between items-center mb-3">
        <div>
          <h4 className="font-semibold text-sm">
            {trainType === 'mexican' ? '🚂 Mexican Train' : `🚃 ${ownerName}'s Train`}
          </h4>
          {needsDoubleSatisfaction && (
            <p className="text-xs text-orange-600 mt-1">
              ⚠️ Must satisfy double
            </p>
          )}
        </div>
        
        <div className="flex gap-2">
          {isOpen && trainType !== 'mexican' && (
            <span className="px-2 py-1 text-xs rounded-full bg-orange-100 text-orange-800">
              🔓 Open
            </span>
          )}
          <span className={`px-2 py-1 text-xs rounded-full ${trainStatusColor}`}>
            {dominos.length} tiles
          </span>
        </div>
      </div>

      {/* Engine/Starting Point */}
      {engineValue !== undefined && (
        <div className="mb-2 flex items-center gap-2">
          <div className="px-3 py-2 bg-yellow-100 border-2 border-yellow-400 rounded">
            <span className="font-bold text-lg">{engineValue}-{engineValue}</span>
            <span className="text-xs ml-2 text-yellow-700">Engine</span>
          </div>
          {dominos.length === 0 && (
            <span className="text-gray-400">→</span>
          )}
        </div>
      )}

      {/* Train Dominos */}
      <div className="train-line flex items-center overflow-x-auto py-2">
        {dominos.length > 0 ? (
          <>
            {renderTrainDominos()}
            
            {/* Play area at the end */}
            {canPlayHere && (
              <div
                className={`
                  inline-block ml-2 p-2 border-2 border-dashed rounded
                  ${isHoveredEnd ? 'border-green-500 bg-green-50' : 'border-green-400 bg-green-50'}
                  cursor-pointer transition-all duration-200
                `}
                style={{ minWidth: '60px', minHeight: '40px' }}
                onMouseEnter={() => setIsHoveredEnd(true)}
                onMouseLeave={() => setIsHoveredEnd(false)}
                onClick={() => {
                  console.log('🚃 TRAIN PLAY AREA CLICKED!', trainType, ownerName);
                  onPlayDomino?.();
                }}
              >
                <div className="text-center text-xs text-gray-600">
                  <div className="font-semibold">Play Here</div>
                  <div className="text-gray-500">Need: {getRequiredValue()}</div>
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="flex items-center">
            {/* Empty train - show play area */}
            {canPlayHere ? (
              <div
                className={`
                  p-4 border-2 border-dashed rounded cursor-pointer
                  ${isHoveredEnd ? 'border-green-500 bg-green-50' : 'border-green-400 bg-green-50'}
                  transition-all duration-200
                `}
                onMouseEnter={() => setIsHoveredEnd(true)}
                onMouseLeave={() => setIsHoveredEnd(false)}
                onClick={() => {
                  console.log('🚃 TRAIN PLAY AREA CLICKED!', trainType, ownerName);
                  onPlayDomino?.();
                }}
              >
                <div className="text-center">
                  <p className="text-sm text-gray-600 font-semibold">Start Train</p>
                  <p className="text-xs text-gray-500">Need: {getRequiredValue()}</p>
                </div>
              </div>
            ) : (
              <div className="p-4 text-gray-400 text-sm">
                No dominos played yet
              </div>
            )}
          </div>
        )}
      </div>

      {/* Train Status/Rules */}
      {trainType === 'personal' && !isCurrentPlayerTrain && !isOpen && (
        <div className="mt-2 text-xs text-gray-500">
          🔒 This train is closed (owner can play only)
        </div>
      )}
      
      {trainType === 'mexican' && (
        <div className="mt-2 text-xs text-gray-500">
          Anyone can play on the Mexican Train
        </div>
      )}
    </div>
  );
};

export default Train;