# Mexican Train Server Testing Guide

## Prerequisites

- Godot Engine 4.4+ installed
- Project opens without compilation errors
- All autoloads properly configured

## Test Sequence

### 1. Test Server Startup

#### A. Using Server Mechanics Test Scene

```powershell
# Open the server launcher
godot scenes/test/test_server_mechanics.tscn
```

**Expected Results:**

- Window opens with "Mexican Train - Central Server" title
- Shows "Server Status: STOPPED" (gray text)
- "Start Server" button is enabled, "Stop Server" is disabled
- Click "Start Server" → Status changes to "RUNNING on port 9957" (green text)
- Server starts successfully with console output

#### B. Using Command Line Test

```powershell
# Alternative: Test headless server startup
godot --headless scenes/test/test_server_mechanics.tscn
```

### 2. Test Server Admin Console

#### A. Open Admin Dashboard

```powershell
# Open the admin console
godot scenes/test/test_server_admin_dashboard.tscn
```

#### B. Login Process

**Credentials:**

- Email: `admin@mexicantrain.local`
- Password: `admin123`

**Expected Results:**

- Login panel appears first
- After successful login, dashboard shows:
  - "Logged in as: `admin@mexicantrain.local`"
  - Server status (RUNNING/STOPPED)
  - Version: 0.6.0
  - Uptime counter
  - Memory usage
  - Platform information
  - Active games/players counts

#### C. Admin Functions

- **Refresh Data**: Updates all metrics
- **Server Control**: Start/Stop server
- **Logout**: Returns to login screen

### 3. Test Client Lobby Connection

#### A. Open Client Lobby

```powershell
# Open the client lobby interface
godot scenes/lobby/client_lobby.tscn
```

#### B. Connect to Server

**Steps:**

1. Enter server address: `127.0.0.1` (localhost)
2. Click "Connect to Server"
3. Wait for connection confirmation

**Expected Results:**

- Connection status changes to "Connected"
- Lobby panel becomes visible
- Shows available games list (initially empty)

### 4. Test Game Hosting

#### A. From Client Lobby

**Steps:**

1. Ensure connected to server
2. Click "Create New Game"
3. Game code should be generated (6 characters)
4. You become the host

**Expected Results:**

- Game room panel appears
- Shows your game code
- Lists you as host
- "Start Game" button available (but disabled until ready)

#### B. Verify in Admin Console

**Steps:**

1. Switch to admin dashboard window
2. Click "Refresh Data"
3. Check active games section

**Expected Results:**

- Shows 1 active game
- Game details display with your code
- Shows host name and player count

### 5. Multi-Instance Network Testing

#### A. Basic 2-Instance Test (Server + Client)

**Purpose**: Test fundamental server-client communication

**Setup:**

```powershell
# Terminal 1: Start server
godot scenes/test/test_server_mechanics.tscn

# Terminal 2: Start client  
godot scenes/lobby/client_lobby.tscn
```

**Test Steps:**

1. In server window: Click "Start Server"
2. In client window: Connect to `127.0.0.1`
3. Create a game from client
4. Verify connection remains stable

**Expected Results:**

- Client shows "Connected" status
- Game creation succeeds
- Server logs show client connection

#### B. 3-Instance Admin Monitoring Test

**Purpose**: Test admin dashboard real-time monitoring

**Setup:**

```powershell
# Terminal 1: Start server
godot scenes/test/test_server_mechanics.tscn

# Terminal 2: Start admin dashboard
godot scenes/test/test_server_admin_dashboard.tscn

# Terminal 3: Start client
godot scenes/lobby/client_lobby.tscn
```

**Test Steps:**

1. Start server (Terminal 1)
2. Login to admin dashboard (Terminal 2): `admin@mexicantrain.local` / `admin123`
3. Connect client to server (Terminal 3)
4. Create game from client
5. Monitor statistics in admin dashboard

**Expected Results:**

- Admin shows server as RUNNING
- Statistics update: 1 player connected
- Game appears in active games list
- Metrics refresh automatically every 10 seconds

#### C. 4-Instance Multi-Client Game Test

**Purpose**: Test multiple players in same game

**Setup:**

```powershell
# Terminal 1: Start server
godot scenes/test/test_server_mechanics.tscn

# Terminal 2: Start admin monitor
godot scenes/test/test_server_admin_dashboard.tscn

# Terminal 3: Host client
godot scenes/lobby/client_lobby.tscn

# Terminal 4: Joining client
godot scenes/lobby/client_lobby.tscn
```

**Test Steps:**

1. Start server and login to admin
2. Connect BOTH clients to `127.0.0.1`
3. Host creates game in client 3 → Note the game code
4. Client 4 joins using the game code
5. Monitor admin dashboard for 2 players

**Expected Results:**

- Both clients show "Connected"
- Game room shows 2 players (host + joiner)
- Admin dashboard shows: 1 game, 2 players
- Players can see each other in game room

#### D. PowerShell Quick Launch

**Use the enhanced test script:**

```powershell
# Run from project root
.\test_server.ps1

# Select option 6 for multi-client testing
# This opens all 4 windows automatically
```

#### E. Stress Testing (Optional)

**Purpose**: Test with multiple games and players

**Setup:** Open 6+ instances:

- 1 Server
- 1 Admin dashboard  
- 4+ Clients (create multiple games)

**Test:** Create multiple games simultaneously and monitor admin dashboard

### 6. Complete Integration Test

#### A. Multi-Window Test Setup

1. **Window 1**: Server Mechanics (`test_server_mechanics.tscn`)
2. **Window 2**: Admin Dashboard (`test_server_admin_dashboard.tscn`)
3. **Window 3**: Client Lobby (`client_lobby.tscn`)

#### B. Test Workflow

1. **Start Server** (Window 1)
   - Click "Start Server"
   - Verify green "RUNNING" status

2. **Monitor Admin** (Window 2)
   - Login with admin credentials
   - Verify server shows as RUNNING
   - Note initial metrics

3. **Connect Client** (Window 3)
   - Connect to localhost
   - Verify lobby appears

4. **Create Game** (Window 3)
   - Click "Create New Game"
   - Note the game code generated

5. **Verify Admin Tracking** (Window 2)
   - Click "Refresh Data"
   - Verify active games count increased
   - Check game appears in games list

#### C. Expected Final State

- **Server**: RUNNING status, 1 active game
- **Admin**: Shows 1 game, 1 player, statistics updated
- **Client**: In game room as host, ready to start

### 7. Automated System Testing

#### A. Run Complete Test Suite

```powershell
# Run automated tests
godot scenes/test/test_server_system.tscn
```

**Test Coverage:**

- Autoload system verification
- ServerAdmin authentication
- NetworkManager functionality
- LobbyManager game creation
- Statistics tracking
- Admin authentication security
- Server metrics collection

**Expected Results:**

- All 8 tests pass (8/8 PASSED)
- Green checkmarks for all components
- No security vulnerabilities detected
- All autoloads loaded correctly

#### B. Individual Component Tests

```powershell
# Test individual components if needed
godot scenes/test/test_server_mechanics.tscn
godot scenes/test/test_server_admin_dashboard.tscn
```

### 8. Troubleshooting

#### Common Issues

- **Server won't start**: Check port 9957 isn't in use
- **Client can't connect**: Verify server is running first
- **Admin login fails**: Use exact credentials (case-sensitive)
- **Game not showing in admin**: Click refresh, check timing
- **Multiple instances**: Ensure each has unique window focus
- **Network errors**: Check firewall isn't blocking port 9957

#### Debug Commands

```powershell
# Check for compilation errors
godot --headless --check-only

# View detailed server logs
godot --verbose scenes/test/test_server_mechanics.tscn

# Test specific autoload
godot --script-expr "print(ServerAdmin.get_server_metrics())"

# Test multiple instances
godot --position 100,100 scenes/test/test_server_mechanics.tscn &
godot --position 400,100 scenes/lobby/client_lobby.tscn &
```

#### Performance Validation

```powershell
# Test server performance under load
for ($i=1; $i -le 5; $i++) {
    Start-Process godot `
        -ArgumentList "scenes/lobby/client_lobby.tscn" `
        -WindowStyle Normal
    Start-Sleep 1
}
```

### 9. Verification Checklist

#### Server Components

- [ ] Server starts successfully on port 9957
- [ ] Admin dashboard login works with correct credentials
- [ ] Admin dashboard rejects invalid credentials
- [ ] Server metrics display correctly
- [ ] Multiple clients can connect simultaneously

#### Game Functionality

- [ ] Games can be created with unique codes
- [ ] Players can join games using codes
- [ ] Game statistics tracked in admin dashboard
- [ ] Player counts update correctly
- [ ] Games appear in admin monitoring

#### Network Stability

- [ ] Clients reconnect after disconnection
- [ ] Server handles multiple simultaneous connections
- [ ] No memory leaks during extended testing
- [ ] Admin dashboard updates in real-time

### 10. Test Automation Script

For automated testing, use the PowerShell script:

```powershell
# Run complete test suite
.\test_server.ps1
```

**Options:**

1. Automated System Tests (recommended first)
2. Server Mechanics (manual server testing)
3. Admin Dashboard (server administration)
4. Client Lobby (player interface)
5. Complete Integration Test (all windows)
6. Multi-Client Game Test (server + 2 clients + admin)
7. Quick Validation (headless check)

### 11. Success Criteria

#### All Tests Pass When

- All autoloads load without errors
- Server starts and stops cleanly
- Admin authentication works correctly
- Clients connect and disconnect properly
- Games are created and joined successfully
- Statistics tracking functions correctly
- Admin dashboard displays real-time data
- No compilation errors or warnings
- Memory usage remains stable during testing

#### Performance Verification

##### Admin Dashboard Features

- **Auto-refresh**: Metrics update every 10 seconds
- **Real-time stats**: Memory, uptime, active connections
- **Game monitoring**: Live game list with player counts
- **Server control**: Start/stop functionality

##### Network Features

- **Game codes**: 6-character alphanumeric
- **Player management**: Host designation, ready status
- **Connection handling**: Graceful connect/disconnect
- **Lobby updates**: Real-time game list synchronization

## Additional Resources

- **Server Configuration**: See `autoload/game_config.gd`
- **Network Settings**: Default port 9957, max 8 players
- **Admin Credentials**: Located in `autoload/server_admin.gd`
- **Debug Logging**: Enable in GameConfig for detailed output

For detailed implementation information, see the source code in the
`autoload/` and `scripts/test/` directories.
