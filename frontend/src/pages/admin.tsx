import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/router';

interface AdminDashboard {
  timestamp: number;
  games: {
    total_active: number;
    in_progress: number;
    waiting_for_players: number;
    games_list: GameInfo[];
  };
  players: {
    total_players: number;
    total_spectators: number;
    ai_players: number;
    human_players: number;
  };
  connections: {
    total_game_connections: number;
    total_lobby_connections: number;
    total_spectator_connections: number;
    total_websockets: number;
  };
  resources: {
    cpu_percent: number | null;
    memory_percent: number | null;
    memory_used_mb: number | null;
    memory_total_mb: number | null;
  };
}

interface GameInfo {
  game_id: string;
  player_count: number;
  spectator_count: number;
  started: boolean;
  current_player: string | null;
  host: string;
  ai_players: number;
  created_at: string | null;
  current_round: number;
  connections: number;
}

interface GameDetails {
  game_id: string;
  name: string;
  host: string;
  players: string[];
  spectators: string[];
  ai_players: string[];
  player_count: number;
  spectator_count: number;
  max_players: number;
  min_players: number;
  started: boolean;
  current_player: string | null;
  current_round: number;
  boneyard_count: number;
  connections: number;
  spectator_connections: number;
  created_at: string | null;
  countdown_remaining: number | null;
  ai_enabled: boolean;
  ai_skill_level: number;
  potential_ai_stuck: boolean;
}

export default function AdminDashboard() {
  const { data: session, status } = useSession();
  const router = useRouter();
  const [dashboard, setDashboard] = useState<AdminDashboard | null>(null);
  const [games, setGames] = useState<GameDetails[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedGameId, setSelectedGameId] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<{ [key: string]: boolean }>({});

  // Auto-refresh data every 5 seconds
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [dashboardRes, gamesRes] = await Promise.all([
          fetch('/api/admin/dashboard'),
          fetch('/api/admin/games')
        ]);

        if (!dashboardRes.ok || !gamesRes.ok) {
          throw new Error('Failed to fetch admin data');
        }

        const dashboardData = await dashboardRes.json();
        const gamesData = await gamesRes.json();

        setDashboard(dashboardData);
        setGames(gamesData.games);
        setError(null);
      } catch (err) {
        setError('Failed to load admin dashboard');
        console.error('Admin dashboard error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 5000); // Refresh every 5 seconds

    return () => clearInterval(interval);
  }, []);

  const handleKillGame = async (gameId: string, reason: string = 'Admin terminated stuck game') => {
    setActionLoading(prev => ({ ...prev, [`kill-${gameId}`]: true }));
    
    try {
      const response = await fetch(`/api/admin/games/${gameId}/kill`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ reason })
      });

      if (!response.ok) {
        throw new Error('Failed to kill game');
      }

      const result = await response.json();
      alert(`Game ${gameId} terminated: ${result.message}`);
      
      // Refresh data immediately
      window.location.reload();
    } catch (err) {
      console.error('Error killing game:', err);
      alert('Failed to kill game');
    } finally {
      setActionLoading(prev => ({ ...prev, [`kill-${gameId}`]: false }));
    }
  };

  const handleForceNextTurn = async (gameId: string) => {
    setActionLoading(prev => ({ ...prev, [`next-turn-${gameId}`]: true }));
    
    try {
      const response = await fetch(`/api/admin/games/${gameId}/force-next-turn`, {
        method: 'POST'
      });

      if (!response.ok) {
        throw new Error('Failed to force next turn');
      }

      const result = await response.json();
      alert(`Turn forced: ${result.message}`);
    } catch (err) {
      console.error('Error forcing next turn:', err);
      alert('Failed to force next turn');
    } finally {
      setActionLoading(prev => ({ ...prev, [`next-turn-${gameId}`]: false }));
    }
  };

  if (status === 'loading' || loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading admin dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-xl font-bold text-red-800 mb-2">Error Loading Dashboard</h2>
          <p className="text-red-600">{error}</p>
          <button 
            onClick={() => window.location.reload()}
            className="mt-4 bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <Head>
        <title>Server Admin Dashboard - Mexican Train</title>
      </Head>

      <div className="max-w-7xl mx-auto p-6">
        {/* Header */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Server Admin Dashboard</h1>
              <p className="text-gray-600 mt-2">
                Last updated: {dashboard ? new Date(dashboard.timestamp * 1000).toLocaleTimeString() : 'Loading...'}
              </p>
            </div>
            <button
              onClick={() => router.push('/lobby')}
              className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            >
              Back to Lobby
            </button>
          </div>
        </div>

        {dashboard && (
          <>
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-700">Active Games</h3>
                <div className="text-3xl font-bold text-blue-600">{dashboard.games.total_active}</div>
                <p className="text-sm text-gray-500">
                  {dashboard.games.in_progress} in progress, {dashboard.games.waiting_for_players} waiting
                </p>
              </div>

              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-700">Players</h3>
                <div className="text-3xl font-bold text-green-600">{dashboard.players.total_players}</div>
                <p className="text-sm text-gray-500">
                  {dashboard.players.human_players} human, {dashboard.players.ai_players} AI
                </p>
              </div>

              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-700">WebSocket Connections</h3>
                <div className="text-3xl font-bold text-purple-600">{dashboard.connections.total_websockets}</div>
                <p className="text-sm text-gray-500">
                  {dashboard.connections.total_game_connections} games, {dashboard.connections.total_lobby_connections} lobby
                </p>
              </div>

              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-700">System Resources</h3>
                <div className="text-3xl font-bold text-orange-600">
                  {dashboard.resources.cpu_percent ? `${dashboard.resources.cpu_percent.toFixed(1)}%` : 'N/A'}
                </div>
                <p className="text-sm text-gray-500">
                  CPU Usage
                  {dashboard.resources.memory_percent && (
                    <span className="block">Memory: {dashboard.resources.memory_percent.toFixed(1)}%</span>
                  )}
                </p>
              </div>
            </div>

            {/* Resource Details */}
            {dashboard.resources.memory_used_mb && dashboard.resources.memory_total_mb && (
              <div className="bg-white rounded-lg shadow p-6 mb-6">
                <h3 className="text-lg font-semibold text-gray-700 mb-4">System Resources</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <h4 className="font-medium text-gray-600">Memory Usage</h4>
                    <div className="w-full bg-gray-200 rounded-full h-2.5 mb-2">
                      <div 
                        className="bg-blue-600 h-2.5 rounded-full" 
                        style={{ width: `${dashboard.resources.memory_percent}%` }}
                      ></div>
                    </div>
                    <p className="text-sm text-gray-500">
                      {dashboard.resources.memory_used_mb} MB / {dashboard.resources.memory_total_mb} MB
                    </p>
                  </div>
                  {dashboard.resources.cpu_percent !== null && (
                    <div>
                      <h4 className="font-medium text-gray-600">CPU Usage</h4>
                      <div className="w-full bg-gray-200 rounded-full h-2.5 mb-2">
                        <div 
                          className="bg-green-600 h-2.5 rounded-full" 
                          style={{ width: `${dashboard.resources.cpu_percent}%` }}
                        ></div>
                      </div>
                      <p className="text-sm text-gray-500">
                        {dashboard.resources.cpu_percent.toFixed(1)}% usage
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </>
        )}

        {/* Games List */}
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-xl font-bold text-gray-900">Active Games</h2>
            <p className="text-gray-600 mt-1">Manage and monitor all active games</p>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Game ID
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Players
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Current Player
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Round
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Connections
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {games.map((game) => (
                  <tr key={game.game_id} className={game.potential_ai_stuck ? 'bg-red-50' : ''}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {game.game_id}
                      {game.potential_ai_stuck && (
                        <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          ⚠️ AI Stuck
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        game.started 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {game.started ? '🎮 Active' : '⏳ Waiting'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {game.player_count}/{game.max_players}
                      {game.ai_players.length > 0 && (
                        <span className="text-blue-600 ml-1">({game.ai_players.length} AI)</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {game.current_player || 'N/A'}
                      {game.current_player && game.ai_players.includes(game.current_player) && (
                        <span className="ml-1 text-blue-600">🤖</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {game.current_round}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {game.connections}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                      {game.started && game.potential_ai_stuck && (
                        <button
                          onClick={() => handleForceNextTurn(game.game_id)}
                          disabled={actionLoading[`next-turn-${game.game_id}`]}
                          className="inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 disabled:opacity-50"
                        >
                          {actionLoading[`next-turn-${game.game_id}`] ? 'Processing...' : '⏭️ Force Next Turn'}
                        </button>
                      )}
                      <button
                        onClick={() => {
                          const reason = prompt('Reason for terminating game:', 'Admin intervention - stuck game');
                          if (reason) {
                            handleKillGame(game.game_id, reason);
                          }
                        }}
                        disabled={actionLoading[`kill-${game.game_id}`]}
                        className="inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                      >
                        {actionLoading[`kill-${game.game_id}`] ? 'Terminating...' : '🔥 Kill Game'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {games.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                No active games found
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}