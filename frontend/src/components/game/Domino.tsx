import React from 'react';
import Image from 'next/image';

interface DominoProps {
  left: number;
  right: number;
  id?: string;
  isDouble?: boolean;
  isClickable?: boolean;
  isSelected?: boolean;
  orientation?: 'horizontal' | 'vertical';
  size?: 'small' | 'medium' | 'large';
  onClick?: () => void;
  showBack?: boolean; // For showing back of domino (in boneyard or opponent hands)
}

export const Domino: React.FC<DominoProps> = ({
  left,
  right,
  id,
  isDouble,
  isClickable = false,
  isSelected = false,
  orientation = 'horizontal',
  size = 'medium',
  onClick,
  showBack = false
}) => {
  // Size configurations
  const sizeConfig = {
    small: { width: 60, height: 30, halfWidth: 30 },
    medium: { width: 80, height: 40, halfWidth: 40 },
    large: { width: 100, height: 50, halfWidth: 50 }
  };

  const config = sizeConfig[size];
  
  // For vertical orientation, swap width and height
  const displayWidth = orientation === 'vertical' ? config.height : config.width;
  const displayHeight = orientation === 'vertical' ? config.width : config.height;

  const renderDominoBack = () => (
    <svg
      width={displayWidth}
      height={displayHeight}
      viewBox={`0 0 ${displayWidth} ${displayHeight}`}
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect
        x="0"
        y="0"
        width={displayWidth}
        height={displayHeight}
        fill="#2c5530"
        stroke="#1a3d1f"
        strokeWidth="2"
        rx="4"
      />
      {/* Decorative pattern for back */}
      <rect
        x="4"
        y="4"
        width={displayWidth - 8}
        height={displayHeight - 8}
        fill="none"
        stroke="#4a7c4e"
        strokeWidth="1"
        rx="2"
      />
      {/* Center line for back */}
      {orientation === 'horizontal' ? (
        <line
          x1={displayWidth / 2}
          y1="4"
          x2={displayWidth / 2}
          y2={displayHeight - 4}
          stroke="#4a7c4e"
          strokeWidth="1"
        />
      ) : (
        <line
          x1="4"
          y1={displayHeight / 2}
          x2={displayWidth - 4}
          y2={displayHeight / 2}
          stroke="#4a7c4e"
          strokeWidth="1"
        />
      )}
    </svg>
  );

  const renderDominoFront = () => {
    if (orientation === 'horizontal') {
      return (
        <div 
          className="flex" 
          style={{ 
            width: displayWidth, 
            height: displayHeight,
            border: '1px solid black',
            borderRadius: '4px',
            backgroundColor: 'white'
          }}
        >
          {/* Left half */}
          <div 
            style={{ 
              width: config.halfWidth, 
              height: displayHeight,
              overflow: 'hidden'
            }}
          >
            <img
              src={`/dominos/half-${left}.svg`}
              alt={`${left} pips`}
              width={config.halfWidth}
              height={displayHeight}
              style={{ 
                objectFit: 'cover',
                display: 'block'
              }}
            />
          </div>
          
          {/* Separator line */}
          <div 
            style={{ 
              width: '2px', 
              height: displayHeight, 
              backgroundColor: 'black' 
            }} 
          />
          
          {/* Right half */}
          <div 
            style={{ 
              width: config.halfWidth, 
              height: displayHeight,
              overflow: 'hidden'
            }}
          >
            <img
              src={`/dominos/half-${right}.svg`}
              alt={`${right} pips`}
              width={config.halfWidth}
              height={displayHeight}
              style={{ 
                objectFit: 'cover',
                display: 'block'
              }}
            />
          </div>
        </div>
      );
    } else {
      // Vertical orientation
      return (
        <div 
          className="flex flex-col" 
          style={{ 
            width: displayWidth, 
            height: displayHeight,
            border: '1px solid black',
            borderRadius: '4px',
            backgroundColor: 'white'
          }}
        >
          {/* Top half */}
          <div 
            style={{ 
              width: displayWidth, 
              height: config.halfWidth,
              overflow: 'hidden'
            }}
          >
            <img
              src={`/dominos/half-${left}.svg`}
              alt={`${left} pips`}
              width={displayWidth}
              height={config.halfWidth}
              style={{ 
                objectFit: 'cover',
                display: 'block',
                transform: 'rotate(90deg)',
                transformOrigin: 'center'
              }}
            />
          </div>
          
          {/* Separator line */}
          <div 
            style={{ 
              width: displayWidth, 
              height: '2px', 
              backgroundColor: 'black' 
            }} 
          />
          
          {/* Bottom half */}
          <div 
            style={{ 
              width: displayWidth, 
              height: config.halfWidth,
              overflow: 'hidden'
            }}
          >
            <img
              src={`/dominos/half-${right}.svg`}
              alt={`${right} pips`}
              width={displayWidth}
              height={config.halfWidth}
              style={{ 
                objectFit: 'cover',
                display: 'block',
                transform: 'rotate(90deg)',
                transformOrigin: 'center'
              }}
            />
          </div>
        </div>
      );
    }
  };

  return (
    <div
      className={`
        domino-container inline-block
        ${isClickable ? 'cursor-pointer hover:transform hover:scale-110 transition-transform' : ''}
        ${isSelected ? 'ring-2 ring-blue-500 ring-offset-2 rounded' : ''}
      `}
      onClick={isClickable ? () => {
        console.log('🎲 DOMINO COMPONENT CLICKED:', left, right, id);
        onClick?.();
      } : undefined}
      style={{ margin: '2px' }}
    >
      {showBack ? renderDominoBack() : renderDominoFront()}
      
      {/* Optional ID label for debugging */}
      {id && !showBack && process.env.NODE_ENV === 'development' && (
        <div className="text-xs text-gray-500 text-center mt-1">
          {left}-{right}
        </div>
      )}
    </div>
  );
};

export default Domino;