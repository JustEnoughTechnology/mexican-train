import React, { useState, useEffect } from 'react';
import { useSession, signIn, signOut } from 'next-auth/react';

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
  const [userHandle, setUserHandle] = useState<string>('');
  const [displayName, setDisplayName] = useState<string>('');
  const [userType, setUserType] = useState<string>('');
  const [isEditingName, setIsEditingName] = useState<boolean>(false);
  const [tempName, setTempName] = useState<string>('');
  const [nameError, setNameError] = useState<string>('');
  const [activeGames, setActiveGames] = useState<any[]>([]);
  const [lobbyWebSocket, setLobbyWebSocket] = useState<WebSocket | null>(null);
  const [isConnectedToLobby, setIsConnectedToLobby] = useState<boolean>(false);
  const [showCreateGameForm, setShowCreateGameForm] = useState<boolean>(false);
  const [gameForm, setGameForm] = useState({
    name: '',
    description: '',
    maxPlayers: 4,
    minPlayers: 2,
    allowSpectators: true,
    isPrivate: false,
    password: '',
    aiEnabled: true,
    aiSkillLevel: 1,
    aiFillToMax: true,
    countdownMinutes: 10,
    gamesToPlay: 13,  // Traditional: 12 down to 0 + bonus rounds
    gamesPreset: 'standard',  // 'short', 'standard', 'long', 'custom'
    customGameCount: 13
  });
  const [viewMode, setViewMode] = useState<'detailed' | 'compact'>(() => {
    // Load saved preference from localStorage, default to 'detailed'
    if (typeof window !== 'undefined') {
      return localStorage.getItem('gameListViewMode') as 'detailed' | 'compact' || 'detailed';
    }
    return 'detailed';
  });

  // Get current user identity from session or sessionStorage
  useEffect(() => {
    // Check if we're setting up a new identity from URL params
    const urlParams = new URLSearchParams(window.location.search);
    const isNewIdentity = urlParams.get('newIdentity') === 'true';
    const urlUserHandle = urlParams.get('userHandle');
    const urlDisplayName = urlParams.get('displayName');
    
    if (isNewIdentity && urlUserHandle && urlDisplayName) {
      console.log('🆕 Setting up new identity from URL params:', { urlUserHandle, urlDisplayName });
      
      // Set up the new identity
      setUserHandle(urlUserHandle);
      setDisplayName(urlDisplayName);
      setUserType('guest');
      
      // Store in sessionStorage
      sessionStorage.setItem('userHandle', urlUserHandle);
      sessionStorage.setItem('displayName', urlDisplayName);
      sessionStorage.setItem('userType', 'guest');
      
      // Clean up the URL
      const newUrl = new URL(window.location.href);
      newUrl.searchParams.delete('newIdentity');
      newUrl.searchParams.delete('userHandle');
      newUrl.searchParams.delete('displayName');
      window.history.replaceState({}, '', newUrl.toString());
      
      return;
    }

    if (session?.user) {
      // Authenticated user - check if they have a display name for this tab
      let handle = `auth_${session.user.email || session.user.name || 'user'}`;
      let tabDisplayName = sessionStorage.getItem('displayName');
      
      if (!tabDisplayName) {
        // First time in this tab - generate a display name
        tabDisplayName = generateTrainThemedUsername();
        sessionStorage.setItem('displayName', tabDisplayName);
        sessionStorage.setItem('userHandle', handle);
        sessionStorage.setItem('userType', 'authenticated');
      }
      
      setUserHandle(handle);
      setDisplayName(tabDisplayName);
      setUserType('authenticated');
    } else {
      // Guest user - use sessionStorage for per-tab identity
      const handle = sessionStorage.getItem('userHandle');
      const tabDisplayName = sessionStorage.getItem('displayName');
      const storedUserType = sessionStorage.getItem('userType');
      
      if (handle && tabDisplayName) {
        setUserHandle(handle);
        setDisplayName(tabDisplayName);
        setUserType(storedUserType || 'guest');
      } else {
        // If no session identity, redirect to home to get one
        window.location.href = '/';
      }
    }
  }, [session]);

  // Validate username availability
  const validateUsername = async (username: string): Promise<{valid: boolean, error?: string}> => {
    try {
      // Check against online users first
      const isOnlineUser = onlineUsers.some(user => 
        user.username.toLowerCase() === username.toLowerCase() && 
        user.username.toLowerCase() !== displayName.toLowerCase()
      );
      
      if (isOnlineUser) {
        return {valid: false, error: "This name is already in use by someone online"};
      }

      // Check against backend validation
      const response = await fetch(`/api/auth/check-username/${encodeURIComponent(username)}`);
      const data = await response.json();
      
      if (!data.available) {
        return {valid: false, error: data.reason};
      }
      
      return {valid: true};
    } catch (error) {
      console.error('Error validating username:', error);
      return {valid: false, error: "Unable to validate username. Please try again."};
    }
  };

  // Handle name editing for all users (guests and authenticated)
  const handleEditName = () => {
    setTempName(displayName);
    setNameError('');
    setIsEditingName(true);
  };

  const handleSaveName = async () => {
    const newName = tempName.trim();
    
    if (!newName) {
      setNameError("Name cannot be empty");
      return;
    }
    
    if (newName === displayName) {
      setIsEditingName(false);
      setNameError('');
      return;
    }

    // Validate the new display name
    const validation = await validateUsername(newName);
    if (!validation.valid) {
      setNameError(validation.error || "Name is not available");
      return;
    }

    console.log(`Updating display name from "${displayName}" to "${newName}"`);
    
    // Save the new display name to sessionStorage (per-tab identity)
    setDisplayName(newName);
    sessionStorage.setItem('displayName', newName);
    localStorage.setItem('lastDisplayName', newName); // Backup for reference
    
    // Close existing lobby WebSocket to force reconnection with new display name
    if (lobbyWebSocket) {
      console.log('Closing lobby WebSocket to reconnect with new display name');
      lobbyWebSocket.close();
      setLobbyWebSocket(null);
      setIsConnectedToLobby(false);
    }
    
    setIsEditingName(false);
    setNameError('');
  };

  const handleCancelEdit = () => {
    setTempName('');
    setNameError('');
    setIsEditingName(false);
  };

  const handleJoinGame = (gameId: string, gameName: string) => {
    if (!displayName || !userHandle) {
      console.error('Cannot join game: missing user identity');
      return;
    }

    console.log(`🎮 Joining game ${gameId} (${gameName}) as ${displayName}`);
    
    // Open the game in a new tab - the game page will handle the join logic
    const url = new URL(`/game/${gameId}`, window.location.origin);
    url.searchParams.set('action', 'join');
    window.open(url.toString(), '_blank');
  };

  const handleSpectateGame = (gameId: string, gameName: string) => {
    if (!displayName || !userHandle) {
      console.error('Cannot spectate game: missing user identity');
      return;
    }

    console.log(`👀 Spectating game ${gameId} (${gameName}) as ${displayName}`);
    
    // Open the game in a new tab - the game page will handle the spectate logic
    const url = new URL(`/game/${gameId}`, window.location.origin);
    url.searchParams.set('action', 'spectate');
    window.open(url.toString(), '_blank');
  };

  const handleCreateGame = async () => {
    if (!displayName || !userHandle) {
      console.error('Cannot create game: missing user identity');
      return;
    }

    // Validate custom game count
    if (gameForm.gamesPreset === 'custom') {
      if (gameForm.customGameCount < 1 || gameForm.customGameCount > 100) {
        alert('Number of games must be between 1 and 100');
        return;
      }
    }

    try {
      const gameData = {
        name: gameForm.name || `${displayName}'s Match`,
        description: gameForm.description,
        host: displayName,
        max_players: gameForm.maxPlayers,
        min_players: gameForm.minPlayers,
        allow_spectators: gameForm.allowSpectators,
        visibility: gameForm.isPrivate ? 'private' : 'public',
        password: gameForm.isPrivate ? gameForm.password : null,
        ai_enabled: gameForm.aiEnabled,
        ai_skill_level: gameForm.aiSkillLevel,
        ai_fill_to_max: gameForm.aiFillToMax,
        countdown_minutes: gameForm.countdownMinutes,
        games_to_play: gameForm.gamesToPlay
      };

      console.log('🎮 Creating game with options:', gameData);

      console.log('📤 Sending POST request to create game:', gameData);
      
      const response = await fetch('/api/games/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(gameData),
      });

      console.log('📥 Response status:', response.status, response.statusText);
      console.log('📥 Response headers:', Object.fromEntries(response.headers.entries()));

      if (response.ok) {
        const result = await response.json();
        console.log('✅ Game created:', result);
        
        // Close form and open the game
        setShowCreateGameForm(false);
        setGameForm({
          name: '',
          description: '',
          maxPlayers: 4,
          minPlayers: 2,
          allowSpectators: true,
          isPrivate: false,
          password: '',
          aiEnabled: true,
          aiSkillLevel: 1,
          aiFillToMax: true,
          countdownMinutes: 10,
          gamesToPlay: 13,
          gamesPreset: 'standard',
          customGameCount: 13
        });
        
        // Open the new match
        window.open(`/game/${result.match_id}`, '_blank');
      } else {
        const responseText = await response.text();
        console.error('❌ Failed to create game:');
        console.error('Status:', response.status, response.statusText);
        console.error('Response body:', responseText);
        
        // Check if we got HTML instead of JSON
        if (responseText.includes('<!DOCTYPE html>')) {
          console.error('🚨 Received HTML instead of JSON - API routing issue!');
        }
      }
    } catch (error) {
      console.error('Error creating game:', error);
    }
  };

  // Fetch data from backend API
  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch games
        const gamesResponse = await fetch('/api/games/list');
        if (!gamesResponse.ok) {
          console.error('Failed to fetch games:', gamesResponse.status, gamesResponse.statusText);
          const responseText = await gamesResponse.text();
          if (responseText.includes('<!DOCTYPE html>')) {
            console.error('🚨 Received HTML instead of JSON for games list - API routing issue!');
          }
          return;
        }
        const gamesData = await gamesResponse.json();
        setGames(gamesData.games || []);

        // Fetch online users
        const usersResponse = await fetch('/api/users/online');
        if (!usersResponse.ok) {
          console.error('Failed to fetch online users:', usersResponse.status);
          const responseText = await usersResponse.text();
          if (responseText.includes('<!DOCTYPE html>')) {
            console.error('🚨 Received HTML instead of JSON for online users - API routing issue!');
          }
        } else {
          const usersData = await usersResponse.json();
          setOnlineUsers(usersData.users || []);
        }

        // Fetch backend version from API endpoint
        const versionResponse = await fetch('/api/games/info');
        if (!versionResponse.ok) {
          console.error('Failed to fetch version:', versionResponse.status);
          // Don't crash, just set a default version
          setBackendVersion('unknown');
        } else {
          try {
            const versionData = await versionResponse.json();
            setBackendVersion(versionData.version || '1.0.0');
          } catch (err) {
            console.error('Failed to parse version response:', err);
            setBackendVersion('unknown');
          }
        }

        // Fetch user's active games if we have a user handle
        if (userHandle) {
          try {
            const activeGamesResponse = await fetch(`/api/games/user/${encodeURIComponent(userHandle)}/active`);
            if (!activeGamesResponse.ok) {
              console.error('Failed to fetch active games:', activeGamesResponse.status, activeGamesResponse.statusText);
              // Don't crash, just set empty active games
              setActiveGames([]);
            } else {
              try {
                const activeGamesData = await activeGamesResponse.json();
                setActiveGames(activeGamesData.active_matches || []);
              } catch (err) {
                console.error('Failed to parse active games response:', err);
                setActiveGames([]);
              }
            }
          } catch (error) {
            console.error('Error fetching active games:', error);
          }
        }
      } catch (error) {
        console.error('Error fetching data:', error);
        // Keep empty arrays if API fails
      }
    };

    fetchData();
    
    // Refresh data every 5 seconds
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, [userHandle]);

  // Connect to lobby WebSocket for presence tracking
  useEffect(() => {
    if (!userHandle || !displayName) {
      console.log('Lobby WebSocket: waiting for userHandle and displayName', {userHandle, displayName});
      return;
    }

    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${wsProtocol}//${window.location.host}/ws/lobby?user_id=${encodeURIComponent(userHandle)}&display_name=${encodeURIComponent(displayName)}`;
    
    console.log('=== LOBBY WEBSOCKET CONNECTING ===');
    console.log('User Handle:', userHandle);
    console.log('Display Name:', displayName);
    console.log('WebSocket URL:', wsUrl);
    
    const ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
      console.log('✅ Connected to lobby WebSocket as:', displayName, `(${userHandle})`);
      setIsConnectedToLobby(true);
      setLobbyWebSocket(ws);
    };
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      console.log('📨 Lobby WebSocket message:', message);
      
      if (message.type === 'lobby_connected') {
        console.log('✅ Lobby connection confirmed for:', message.display_name);
      } else if (message.type === 'display_name_updated') {
        console.log('✅ Display name update confirmed:', message.new_display_name);
      }
    };
    
    ws.onclose = () => {
      console.log('🔌 Disconnected from lobby WebSocket');
      setIsConnectedToLobby(false);
      setLobbyWebSocket(null);
    };
    
    ws.onerror = (error) => {
      console.error('❌ Lobby WebSocket error:', error);
      setIsConnectedToLobby(false);
    };
    
    return () => {
      console.log('🔄 Cleaning up lobby WebSocket connection');
      ws.close();
    };
  }, [userHandle, displayName]);

  // Update browser title with server info
  useEffect(() => {
    const serverHost = window.location.host;
    const baseTitle = `Mexican Train - ${serverHost} - Lobby`;
    
    if (displayName) {
      document.title = `${baseTitle} - ${displayName}`;
    } else {
      document.title = baseTitle;
    }
  }, [displayName]);

  // Save view mode preference whenever it changes
  const handleViewModeChange = (mode: 'detailed' | 'compact') => {
    setViewMode(mode);
    if (typeof window !== 'undefined') {
      localStorage.setItem('gameListViewMode', mode);
    }
  };

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
              {isEditingName ? (
                <div>
                  <div className="flex items-center space-x-2">
                    <input
                      type="text"
                      value={tempName}
                      onChange={(e) => {
                        setTempName(e.target.value);
                        setNameError(''); // Clear error when typing
                      }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') handleSaveName();
                        if (e.key === 'Escape') handleCancelEdit();
                      }}
                      className={`text-lg font-medium border rounded px-2 py-1 ${
                        nameError ? 'border-red-300' : 'border-gray-300'
                      }`}
                      placeholder="Enter your name"
                      autoFocus
                      maxLength={20}
                    />
                    <button
                      onClick={handleSaveName}
                      className="text-green-600 hover:text-green-800"
                    >
                      ✓
                    </button>
                    <button
                      onClick={handleCancelEdit}
                      className="text-red-600 hover:text-red-800"
                    >
                      ✗
                    </button>
                  </div>
                  {nameError && (
                    <p className="text-sm text-red-600 mt-1">{nameError}</p>
                  )}
                </div>
              ) : (
                <div className="flex items-center space-x-2">
                  <div>
                    <p className="text-lg font-medium">Welcome, {displayName}</p>
                    <div className="flex items-center space-x-2">
                      {userType === 'authenticated' && (
                        <p className="text-xs text-gray-500">@{userHandle}</p>
                      )}
                      <div className="flex items-center">
                        <div className={`w-2 h-2 rounded-full mr-1 ${
                          isConnectedToLobby ? 'bg-green-400' : 'bg-red-400'
                        }`}></div>
                        <span className="text-xs text-gray-500">
                          {isConnectedToLobby ? 'Online' : 'Offline'}
                        </span>
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={handleEditName}
                    className="text-sm text-gray-600 hover:text-gray-800"
                    title="Edit your display name"
                  >
                    ✏️
                  </button>
                </div>
              )}
              {userType === 'guest' && !isEditingName && (
                <div className="space-y-1">
                  <button 
                    onClick={() => window.open('/auth', '_blank')}
                    className="block text-sm text-purple-600 hover:text-purple-800"
                  >
                    📧 Sign in with Email
                  </button>
                  <button 
                    onClick={() => signIn('github', { callbackUrl: '/lobby' })}
                    className="block text-sm text-blue-600 hover:text-blue-800"
                  >
                    🐙 Sign in with GitHub
                  </button>
                </div>
              )}
              {displayName && (
                <div className="ml-4">
                  <button
                    onClick={async () => {
                      // Generate new identity directly
                      const newHandle = `guest_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
                      const newDisplayName = generateTrainThemedUsername();
                      
                      console.log('🆕 Creating new identity in new tab:', { newHandle, newDisplayName });
                      
                      // Open new tab with lobby URL and identity in URL params
                      const url = new URL('/lobby', window.location.origin);
                      url.searchParams.set('newIdentity', 'true');
                      url.searchParams.set('userHandle', newHandle);
                      url.searchParams.set('displayName', newDisplayName);
                      window.open(url.toString(), '_blank');
                    }}
                    className="bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700"
                    title="Open new tab with fresh identity"
                  >
                    👤 New Identity
                  </button>
                </div>
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
          {/* Active Games Section */}
          {activeGames.length > 0 && (
            <div className="bg-blue-50 rounded-lg shadow-md p-6 mb-6">
              <h2 className="text-xl font-semibold mb-4 text-blue-900">Your Active Games ({activeGames.length})</h2>
              <div className="space-y-3">
                {activeGames.map((activeGame) => (
                  <div 
                    key={activeGame.game_id} 
                    className="bg-white border border-blue-200 rounded-lg p-4"
                  >
                    <div className="flex justify-between items-center">
                      <div>
                        <h3 className="font-medium text-gray-900">
                          Match: {activeGame.match_id.substring(0, 8)}...
                        </h3>
                        <p className="text-sm text-blue-700">
                          🟢 Connected in another tab
                        </p>
                      </div>
                      <button
                        onClick={() => window.open(`/game/${activeGame.match_id}`, '_blank')}
                        className="bg-blue-600 text-white px-3 py-1 rounded text-sm hover:bg-blue-700"
                      >
                        🔗 Open Tab
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold">Available Matches ({games.length})</h2>
              <div className="flex items-center space-x-2">
                <span className="text-sm text-gray-600">View:</span>
                <div className="flex rounded-md shadow-sm">
                  <button
                    onClick={() => handleViewModeChange('detailed')}
                    className={`px-3 py-1 text-sm font-medium rounded-l-md border ${
                      viewMode === 'detailed'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    📋 Detailed
                  </button>
                  <button
                    onClick={() => handleViewModeChange('compact')}
                    className={`px-3 py-1 text-sm font-medium rounded-r-md border-l-0 border ${
                      viewMode === 'compact'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    📜 Compact
                  </button>
                </div>
              </div>
            </div>
            
            {games.length === 0 ? (
              <p className="text-gray-600">No matches available. Create a new match to get started!</p>
            ) : viewMode === 'detailed' ? (
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
                          <button 
                            onClick={() => handleJoinGame(game.id, game.name)}
                            className={`ml-2 text-white text-sm px-3 py-1 rounded ${
                              game.host === displayName 
                                ? 'bg-green-500 hover:bg-green-600' 
                                : 'bg-blue-500 hover:bg-blue-600'
                            }`}
                            disabled={!isConnectedToLobby}
                            title={game.host === displayName ? "Open your game (you are the host)" : "Join this game"}
                          >
                            {game.host === displayName ? "Open Game" : "Join"}
                          </button>
                        )}
                        {game.status === 'in-progress' && (
                          <div className="ml-2 space-x-2">
                            {game.host === displayName && (
                              <button 
                                onClick={() => handleJoinGame(game.id, game.name)}
                                className="bg-orange-500 hover:bg-orange-600 text-white text-sm px-3 py-1 rounded"
                                disabled={!isConnectedToLobby}
                                title="Rejoin your active game"
                              >
                                Rejoin
                              </button>
                            )}
                            <button 
                              onClick={() => handleSpectateGame(game.id, game.name)}
                              className="bg-purple-500 hover:bg-purple-600 text-white text-sm px-3 py-1 rounded"
                              disabled={!isConnectedToLobby}
                              title="Watch this game as a spectator"
                            >
                              👀 Spectate
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              // Compact view - table format for hundreds of games
              <div className="overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Match Name
                        </th>
                        <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Host
                        </th>
                        <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Players
                        </th>
                        <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Action
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {games.map((game) => (
                        <tr key={game.id} className="hover:bg-gray-50">
                          <td className="px-3 py-2 whitespace-nowrap text-sm font-medium text-gray-900">
                            {game.name}
                          </td>
                          <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-600">
                            {game.host}
                          </td>
                          <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-600">
                            {game.players}/{game.maxPlayers}
                          </td>
                          <td className="px-3 py-2 whitespace-nowrap">
                            <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(game.status)}`}>
                              {game.status === 'waiting' ? '⏳' : game.status === 'in-progress' ? '🎮' : '✅'} {game.status}
                            </span>
                          </td>
                          <td className="px-3 py-2 whitespace-nowrap text-sm">
                            {game.status === 'waiting' && (
                              <button 
                                onClick={() => handleJoinGame(game.id, game.name)}
                                className={`text-white text-xs px-2 py-1 rounded ${
                                  game.host === displayName 
                                    ? 'bg-green-500 hover:bg-green-600' 
                                    : 'bg-blue-500 hover:bg-blue-600'
                                }`}
                                disabled={!isConnectedToLobby}
                                title={game.host === displayName ? "Open your game" : "Join this game"}
                              >
                                {game.host === displayName ? "Open" : "Join"}
                              </button>
                            )}
                            {game.status === 'in-progress' && (
                              <div className="flex space-x-1">
                                {game.host === displayName && (
                                  <button 
                                    onClick={() => handleJoinGame(game.id, game.name)}
                                    className="bg-orange-500 hover:bg-orange-600 text-white text-xs px-2 py-1 rounded"
                                    disabled={!isConnectedToLobby}
                                    title="Rejoin your game"
                                  >
                                    Rejoin
                                  </button>
                                )}
                                <button 
                                  onClick={() => handleSpectateGame(game.id, game.name)}
                                  className="bg-purple-500 hover:bg-purple-600 text-white text-xs px-2 py-1 rounded"
                                  disabled={!isConnectedToLobby}
                                  title="Spectate"
                                >
                                  👀
                                </button>
                              </div>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                {games.length > 50 && (
                  <div className="mt-4 text-sm text-gray-500 text-center">
                    Showing {games.length} matches. Use filters or search to narrow results.
                  </div>
                )}
              </div>
            )}
            
            <div className="mt-6">
              <button 
                onClick={() => setShowCreateGameForm(true)}
                className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
              >
                Create New Match
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

      {/* Create Game Modal */}
      {showCreateGameForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <h2 className="text-xl font-bold mb-4">Create New Match</h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Match Name
                </label>
                <input
                  type="text"
                  value={gameForm.name}
                  onChange={(e) => setGameForm({...gameForm, name: e.target.value})}
                  placeholder={`${displayName}'s Match`}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description (optional)
                </label>
                <textarea
                  value={gameForm.description}
                  onChange={(e) => setGameForm({...gameForm, description: e.target.value})}
                  placeholder="Fun match with friends!"
                  className="w-full border border-gray-300 rounded px-3 py-2 h-20"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Games in Match
                </label>
                <select
                  value={gameForm.gamesPreset}
                  onChange={(e) => {
                    const preset = e.target.value;
                    let gamesToPlay = gameForm.gamesToPlay;
                    
                    if (preset === 'short') gamesToPlay = 7;
                    else if (preset === 'standard') gamesToPlay = 13;
                    else if (preset === 'long') gamesToPlay = 20;
                    else if (preset === 'custom') gamesToPlay = gameForm.customGameCount;
                    
                    setGameForm({
                      ...gameForm, 
                      gamesPreset: preset,
                      gamesToPlay: gamesToPlay
                    });
                  }}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="short">Short Match (7 games)</option>
                  <option value="standard">Standard Match (13 games)</option>
                  <option value="long">Long Match (20 games)</option>
                  <option value="custom">Custom</option>
                </select>
                
                {/* Custom game count input */}
                {gameForm.gamesPreset === 'custom' && (
                  <div className="mt-2">
                    <label className="block text-xs font-medium text-gray-600 mb-1">
                      Number of Games (1-100)
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={gameForm.customGameCount}
                      onChange={(e) => {
                        const count = Math.min(100, Math.max(1, parseInt(e.target.value) || 1));
                        setGameForm({
                          ...gameForm,
                          customGameCount: count,
                          gamesToPlay: count
                        });
                      }}
                      className="w-full border border-gray-300 rounded px-3 py-2"
                      placeholder="Enter number of games"
                    />
                  </div>
                )}
                
                <p className="text-xs text-gray-500 mt-1">
                  Each game uses the highest double any player holds
                </p>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Min Players
                  </label>
                  <select
                    value={gameForm.minPlayers}
                    onChange={(e) => {
                      const minVal = parseInt(e.target.value);
                      setGameForm({
                        ...gameForm, 
                        minPlayers: minVal,
                        maxPlayers: Math.max(minVal, gameForm.maxPlayers)
                      });
                    }}
                    className="w-full border border-gray-300 rounded px-3 py-2"
                  >
                    {[1,2,3,4,5,6,7,8].map(num => (
                      <option key={num} value={num}>{num}</option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Max Players
                  </label>
                  <select
                    value={gameForm.maxPlayers}
                    onChange={(e) => {
                      const maxVal = parseInt(e.target.value);
                      setGameForm({
                        ...gameForm, 
                        maxPlayers: maxVal,
                        minPlayers: Math.min(maxVal, gameForm.minPlayers)
                      });
                    }}
                    className="w-full border border-gray-300 rounded px-3 py-2"
                  >
                    {[1,2,3,4,5,6,7,8].map(num => (
                      <option key={num} value={num}>{num}</option>
                    ))}
                  </select>
                </div>
              </div>
              
              <div className="space-y-3">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={gameForm.allowSpectators}
                    onChange={(e) => setGameForm({...gameForm, allowSpectators: e.target.checked})}
                    className="mr-2"
                  />
                  Allow spectators
                </label>
                
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={gameForm.isPrivate}
                    onChange={(e) => setGameForm({...gameForm, isPrivate: e.target.checked})}
                    className="mr-2"
                  />
                  Private game (password required)
                </label>
                
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={gameForm.aiEnabled}
                    onChange={(e) => setGameForm({...gameForm, aiEnabled: e.target.checked})}
                    className="mr-2"
                  />
                  Add AI players
                </label>
              </div>
              
              {gameForm.aiEnabled && (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      AI Skill Level
                    </label>
                    <select
                      value={gameForm.aiSkillLevel}
                      onChange={(e) => setGameForm({...gameForm, aiSkillLevel: parseInt(e.target.value)})}
                      className="w-full border border-gray-300 rounded px-3 py-2"
                    >
                      <option value={1}>Easy</option>
                      <option value={2}>Medium</option>
                      <option value={3}>Hard</option>
                    </select>
                  </div>
                  
                  <div className="flex items-end">
                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        checked={gameForm.aiFillToMax}
                        onChange={(e) => setGameForm({...gameForm, aiFillToMax: e.target.checked})}
                        className="mr-2"
                      />
                      Fill to max players
                    </label>
                  </div>
                </div>
              )}
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Auto-start Timer (minutes)
                </label>
                <select
                  value={gameForm.countdownMinutes}
                  onChange={(e) => setGameForm({...gameForm, countdownMinutes: parseInt(e.target.value)})}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value={5}>5 minutes</option>
                  <option value={10}>10 minutes</option>
                  <option value={15}>15 minutes</option>
                  <option value={30}>30 minutes</option>
                  <option value={60}>1 hour</option>
                </select>
                <p className="text-xs text-gray-500 mt-1">
                  Game will auto-start when minimum players join, or be deleted if not enough players
                </p>
              </div>
              
              {gameForm.isPrivate && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Password
                  </label>
                  <input
                    type="password"
                    value={gameForm.password}
                    onChange={(e) => setGameForm({...gameForm, password: e.target.value})}
                    placeholder="Enter game password"
                    className="w-full border border-gray-300 rounded px-3 py-2"
                  />
                </div>
              )}
            </div>
            
            <div className="flex space-x-3 mt-6">
              <button
                onClick={handleCreateGame}
                className="flex-1 bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
              >
                Create Match
              </button>
              <button
                onClick={() => setShowCreateGameForm(false)}
                className="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Multi-tab and Multi-identity instructions */}
      <div className="mt-6 max-w-4xl mx-auto bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-lg p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <svg className="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-blue-800">
              Multi-Game & Multi-Identity Support
            </h3>
            <div className="mt-2 text-sm text-blue-700 space-y-2">
              <p>
                🎮 <strong>Multiple Games:</strong> Open different games in separate tabs - each maintains its own connection!
              </p>
              <p>
                👤 <strong>Multiple Identities:</strong> Click "New Identity" to get a fresh username in a new tab, perfect for testing or playing as different characters.
              </p>
              <p>
                🕵️ <strong>Pro Tip:</strong> Use incognito/private windows for completely separate identities, or just use the "New Identity" button for quick character switching!
              </p>
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