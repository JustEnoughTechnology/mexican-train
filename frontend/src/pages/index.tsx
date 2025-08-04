import React, { useState } from 'react';
import { useRouter } from 'next/router';
import { signIn, useSession } from 'next-auth/react';

function generateGuestUsername(): string {
  const randomNum = Math.floor(1000 + Math.random() * 9000);
  return `Guest_${randomNum}`;
}

export default function HomePage() {
  const router = useRouter();
  const { data: session } = useSession();
  const [isLoading, setIsLoading] = useState(false);

  // If already signed in, go to lobby
  React.useEffect(() => {
    if (session) {
      router.push('/lobby');
    }
  }, [session, router]);

  const handlePlayAsGuest = () => {
    setIsLoading(true);
    
    // Check if user already has a session
    let username = localStorage.getItem('username');
    
    if (!username) {
      // Generate guest username
      username = generateGuestUsername();
      localStorage.setItem('username', username);
      localStorage.setItem('userType', 'guest');
    }
    
    // Redirect to lobby
    router.push('/lobby');
  };

  const handleGoogleSignIn = () => {
    signIn('google', { callbackUrl: '/lobby' });
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
            
            <button 
              onClick={handleGoogleSignIn}
              className="block w-full bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Sign in with Google
            </button>
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