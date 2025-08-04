import React, { useState, useEffect } from 'react';
import { useSession, signIn, signOut } from 'next-auth/react';

interface Game {
  id: string;
  name: string;
  host: string;
  players: number;
  maxPlayers: number;
  status: 'waiting' | 'in-progress' | 'finished';
}

interface OnlineUser {
  id: string;
  username: string;
  status: 'lobby' | 'in-game';
}

export function GameLobby() {
  const { data: session } = useSession();
  const [games, setGames] = useState<Game[]>([]);
  const [onlineUsers, setOnlineUsers] = useState<OnlineUser[]>([]);
  const [backendVersion, setBackendVersion] = useState<string>('');
  const [frontendVersion] = useState<string>('0.1.2');
  const [currentUser, setCurrentUser] = useState<string>('');
  const [userType, setUserType] = useState<string>('');

  // Get current user from session or localStorage
  useEffect(() => {
    if (session?.user) {
      // Authenticated user
      setCurrentUser(session.user.name || session.user.email || 'User');
      setUserType('authenticated');
    } else {
      // Guest user
      const username = localStorage.getItem('username');
      const storedUserType = localStorage.getItem('userType');
      if (username) {
        setCurrentUser(username);
        setUserType(storedUserType || 'guest');
      }
    }
  }, [session]);

  // Fetch data from backend API
  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch games
        const gamesResponse = await fetch('http://localhost:8000/api/games');
        const gamesData = await gamesResponse.json();
        setGames(gamesData.games || []);

        // Fetch online users
        const usersResponse = await fetch('http://localhost:8000/api/users/online');
        const usersData = await usersResponse.json();
        setOnlineUsers(usersData.users || []);

        // Fetch backend version
        const versionResponse = await fetch('http://localhost:8000/');
        const versionData = await versionResponse.json();
        setBackendVersion(versionData.version || '1.0.0');
      } catch (error) {
        console.error('Error fetching data:', error);
        // Keep empty arrays if API fails
      }
    };

    fetchData();
    
    // Refresh data every 5 seconds
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: Game['status']) => {
    switch (status) {
      case 'waiting': return 'text-green-600 bg-green-100';
      case 'in-progress': return 'text-yellow-600 bg-yellow-100';
      case 'finished': return 'text-gray-600 bg-gray-100';
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Mexican Train Lobby</h1>
        <div className="text-right">
          <div className="flex items-center space-x-4">
            <div>
              <p className="text-lg font-medium">Welcome, {currentUser}</p>
              {userType === 'guest' && (
                <button 
                  onClick={() => signIn('google', { callbackUrl: '/lobby' })}
                  className="text-sm text-blue-600 hover:text-blue-800"
                >
                  Sign in to save progress
                </button>
              )}
            </div>
            {session && (
              <button
                onClick={() => signOut({ callbackUrl: '/' })}
                className="text-sm bg-gray-200 hover:bg-gray-300 px-3 py-1 rounded"
              >
                Sign Out
              </button>
            )}
          </div>
        </div>
      </div>
      
      <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Available Games */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Available Games</h2>
            
            {games.length === 0 ? (
              <p className="text-gray-600">No games available. Create a new game to get started!</p>
            ) : (
              <div className="space-y-3">
                {games.map((game) => (
                  <div key={game.id} className="border rounded-lg p-4 hover:bg-gray-50">
                    <div className="flex justify-between items-center">
                      <div>
                        <h3 className="font-semibold">{game.name}</h3>
                        <p className="text-sm text-gray-600">Host: {game.host}</p>
                        <p className="text-sm text-gray-600">
                          Players: {game.players}/{game.maxPlayers}
                        </p>
                      </div>
                      <div className="text-right">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(game.status)}`}>
                          {game.status}
                        </span>
                        {game.status === 'waiting' && (
                          <button className="ml-2 bg-blue-500 hover:bg-blue-600 text-white text-sm px-3 py-1 rounded">
                            Join
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
            
            <div className="mt-6">
              <button className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded">
                Create New Game
              </button>
            </div>
          </div>
        </div>

        {/* Online Users */}
        <div>
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-lg font-semibold mb-4">Online Users ({onlineUsers.length})</h2>
            
            <div className="space-y-2">
              {onlineUsers.map((user) => (
                <div key={user.id} className="flex items-center justify-between">
                  <span className="text-sm">{user.username}</span>
                  <div className="flex items-center">
                    <div className={`w-2 h-2 rounded-full mr-2 ${
                      user.status === 'lobby' ? 'bg-green-400' : 'bg-yellow-400'
                    }`}></div>
                    <span className="text-xs text-gray-500">{user.status}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Version Info Footer */}
      <div className="mt-8 text-center text-xs text-gray-500">
        Frontend v{frontendVersion} | Backend v{backendVersion}
      </div>
    </div>
  );
}