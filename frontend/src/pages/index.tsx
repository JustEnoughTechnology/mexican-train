import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { signIn, useSession } from 'next-auth/react';

function generateTrainThemedUsername(): string {
  // Family-friendly train titles
  const trainTitles = [
    'Conductor', 'Engineer', 'Brakeman', 'Fireman', 'Dispatcher', 'Yardmaster',
    'Switchman', 'Signalman', 'Trainmaster', 'Caboose', 'Locomotive', 'Freight',
    'Express', 'Local', 'Passenger', 'Cargo', 'Steam', 'Diesel', 'Electric',
    'Whistle', 'Station', 'Track', 'Bridge', 'Tunnel', 'Signal', 'Platform'
  ];
  
  // Positive, family-friendly adjectives
  const trainAdjectives = [
    'Swift', 'Mighty', 'Thunder', 'Lightning', 'Golden', 'Silver', 'Iron',
    'Steel', 'Copper', 'Diamond', 'Ruby', 'Emerald', 'Turbo', 'Super', 'Mega',
    'Epic', 'Legend', 'Champion', 'Master', 'Chief', 'Royal', 'Noble', 'Grand',
    'Brave', 'Bright', 'Smart', 'Fast', 'Strong', 'Clever', 'Happy', 'Lucky',
    'Speedy', 'Shiny', 'Mighty', 'Gentle', 'Kind', 'Wise', 'Bold', 'Proud'
  ];
  
  const title = trainTitles[Math.floor(Math.random() * trainTitles.length)];
  const adjective = trainAdjectives[Math.floor(Math.random() * trainAdjectives.length)];
  const number = Math.floor(10 + Math.random() * 90);
  
  // Mix up the formats for variety
  const formats = [
    `${adjective}${title}${number}`,
    `${title}${number}`,
    `${adjective}${title}`,
    `${title}_${adjective}`,
    `${adjective}_${number}`
  ];
  
  return formats[Math.floor(Math.random() * formats.length)];
}

async function generateUniqueTrainUsername(): Promise<string> {
  let attempts = 0;
  const maxAttempts = 10;
  
  while (attempts < maxAttempts) {
    const username = generateTrainThemedUsername();
    
    try {
      // Check if username is available
      const response = await fetch(`http://localhost:8082/api/auth/check-username/${encodeURIComponent(username)}`);
      const data = await response.json();
      
      if (data.available) {
        return username;
      }
    } catch (error) {
      console.error('Error checking username availability:', error);
    }
    
    attempts++;
  }
  
  // Fallback: add random numbers to ensure uniqueness
  return `${generateTrainThemedUsername()}${Math.floor(1000 + Math.random() * 9000)}`;
}

export default function HomePage() {
  const router = useRouter();
  const { data: session } = useSession();
  const [isLoading, setIsLoading] = useState(false);

  // Note: Removed auto-redirect to lobby to allow users to stay on landing page
  
  console.log('HomePage rendering, session:', session);

  const handlePlayAsGuest = async (forceNew = false) => {
    setIsLoading(true);
    
    try {
      // Check if user already has a session identity for this tab
      let userHandle = sessionStorage.getItem('userHandle');
      let displayName = sessionStorage.getItem('displayName');
      
      if (!userHandle || !displayName || forceNew) {
        // Generate new guest identity for this tab
        userHandle = `guest_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
        displayName = await generateUniqueTrainUsername();
        
        console.log('🆕 Created new guest identity:', { userHandle, displayName });
        
        // Store per-tab identity
        sessionStorage.setItem('userHandle', userHandle);
        sessionStorage.setItem('displayName', displayName);
        sessionStorage.setItem('userType', 'guest');
        
        // Also keep backup for cross-tab reference
        localStorage.setItem('lastDisplayName', displayName);
        localStorage.setItem('lastUserHandle', userHandle);
      } else {
        console.log('🔄 Reusing existing guest identity:', { userHandle, displayName });
      }
      
      // Redirect to lobby
      router.push('/lobby');
    } catch (error) {
      console.error('Error generating guest identity:', error);
      setIsLoading(false);
    }
  };

  // Check if we should force a new identity
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('forceNewIdentity') === 'true') {
      console.log('🆕 Forcing new identity creation');
      
      // Clear the URL parameter
      const newUrl = new URL(window.location.href);
      newUrl.searchParams.delete('forceNewIdentity');
      window.history.replaceState({}, '', newUrl.toString());
      
      // Automatically trigger guest play to create new identity
      handlePlayAsGuest(true); // Pass true to force new identity
    }
  }, [router]);

  const handleGitHubSignIn = () => {
    signIn('github', { callbackUrl: '/lobby' });
  };

  const handleFacebookSignIn = () => {
    signIn('facebook', { callbackUrl: '/lobby' });
  };

  const handleMicrosoftSignIn = () => {
    signIn('azure-ad', { callbackUrl: '/lobby' });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-800 to-green-900 flex items-center justify-center">
      <div className="bg-white rounded-lg shadow-2xl p-8 max-w-md w-full mx-4">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">🚂</h1>
          <h1 className="text-3xl font-bold text-gray-800 mb-4">Mexican Train</h1>
          <p className="text-gray-600 mb-8">
            Join the ultimate domino game experience with friends and AI players
          </p>
          
          <div className="space-y-4">
            <button
              onClick={handlePlayAsGuest}
              disabled={isLoading}
              className="block w-full bg-green-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-green-700 disabled:bg-green-400 transition-colors"
            >
              {isLoading ? 'Entering...' : 'Play as Guest'}
            </button>
            
            <div className="space-y-3">
              <p className="text-sm text-gray-600 text-center">Or sign in with:</p>
              
              <button 
                onClick={handleFacebookSignIn}
                className="block w-full bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors"
              >
                📘 Facebook
              </button>
              
              <button 
                onClick={handleMicrosoftSignIn}
                className="block w-full bg-blue-500 text-white font-semibold py-3 px-6 rounded-lg hover:bg-blue-600 transition-colors"
              >
                🪟 Microsoft
              </button>
              
              <button 
                onClick={handleGitHubSignIn}
                className="block w-full bg-gray-800 text-white font-semibold py-3 px-6 rounded-lg hover:bg-gray-900 transition-colors"
              >
                🐙 GitHub
              </button>
              
              <button 
                onClick={() => router.push('/auth')}
                className="block w-full bg-purple-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-purple-700 transition-colors"
              >
                📧 Email / Password
              </button>
            </div>
          </div>
          
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              Start playing immediately as a guest, or sign in to save your progress
            </p>
          </div>
          
          <div className="mt-8 text-sm text-gray-500">
            <p>Play against AI with 5 different skill levels</p>
            <p>From "Sleepy Caboose" to "Locomotive Legend"</p>
          </div>
        </div>
      </div>
    </div>
  );
}