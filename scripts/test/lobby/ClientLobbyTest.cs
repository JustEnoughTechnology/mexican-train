using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// Client Lobby Test - C# Implementation
/// Tests client-side lobby functionality including connection, game browsing, and joining
/// </summary>
public partial class ClientLobbyTest : Control
{
    // UI Components
    private Panel _connectionPanel;
    private Panel _lobbyPanel;
    private Panel _gamePanel;
    
    // Connection Controls
    private LineEdit _serverAddressInput;
    private LineEdit _playerNameInput;
    private Button _connectButton;
    private Button _disconnectButton;
    private Label _connectionStatusLabel;
    
    // Lobby Controls
    private VBoxContainer _gamesList;
    private Button _refreshGamesButton;
    private Label _lobbyStatusLabel;
    
    // Game Controls
    private LineEdit _gameCodeInput;
    private Button _joinGameButton;
    private Button _createGameButton;
    private Label _currentGameLabel;
    private VBoxContainer _gamePlayersList;
    
    // State
    private Timer _refreshTimer;
    private bool _isConnected = false;
    private string _currentGameCode = "";
    
    // GDScript Autoload References
    private Node _networkManager;
    private Node _lobbyManager;

    public override void _Ready()
    {
        GetWindow().Title = "Mexican Train - Client Lobby Test";
        
        // Get references to GDScript autoloads
        _networkManager = GetNode("/root/NetworkManager");
        _lobbyManager = GetNode("/root/LobbyManager");
        
        // Build the entire UI programmatically
        BuildUI();
        
        // Connect signals
        ConnectSignals();
        
        // Setup auto-refresh
        SetupRefreshTimer();
        
        // Initial update
        UpdateConnectionStatus();
        
        GD.Print("C# Client Lobby Test initialized successfully");
    }

    private void BuildUI()
    {
        // Setup main container
        SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        
        var mainVBox = new VBoxContainer();
        mainVBox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        mainVBox.AddThemeConstantOverride("separation", 15);
        AddChild(mainVBox);

        // Add padding
        mainVBox.OffsetLeft = 20;
        mainVBox.OffsetTop = 20;
        mainVBox.OffsetRight = -20;
        mainVBox.OffsetBottom = -20;

        // Title
        var titleLabel = new Label();
        titleLabel.Text = "Client Lobby Testing Dashboard";
        titleLabel.HorizontalAlignment = HorizontalAlignment.Center;
        titleLabel.AddThemeFontSizeOverride("font_size", 24);
        titleLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        mainVBox.AddChild(titleLabel);

        // Build panels
        BuildConnectionPanel(mainVBox);
        
        var gameAreaHBox = new HBoxContainer();
        gameAreaHBox.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        gameAreaHBox.AddThemeConstantOverride("separation", 15);
        mainVBox.AddChild(gameAreaHBox);
        
        BuildLobbyPanel(gameAreaHBox);
        BuildGamePanel(gameAreaHBox);
    }

    private void BuildConnectionPanel(VBoxContainer parent)
    {
        _connectionPanel = CreateStyledPanel("Server Connection", new Color(0.2f, 0.2f, 0.3f, 0.9f));
        _connectionPanel.CustomMinimumSize = new Vector2(0, 120);
        parent.AddChild(_connectionPanel);

        var content = GetPanelContent(_connectionPanel);

        var connectionHBox = new HBoxContainer();
        connectionHBox.AddThemeConstantOverride("separation", 10);
        content.AddChild(connectionHBox);

        // Server address
        var addressLabel = new Label();
        addressLabel.Text = "Server:";
        addressLabel.CustomMinimumSize = new Vector2(60, 0);
        connectionHBox.AddChild(addressLabel);

        _serverAddressInput = new LineEdit();
        _serverAddressInput.Text = "localhost:9957";
        _serverAddressInput.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        connectionHBox.AddChild(_serverAddressInput);

        // Player name
        var nameLabel = new Label();
        nameLabel.Text = "Name:";
        nameLabel.CustomMinimumSize = new Vector2(50, 0);
        connectionHBox.AddChild(nameLabel);

        _playerNameInput = new LineEdit();
        _playerNameInput.Text = "TestPlayer";
        _playerNameInput.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        connectionHBox.AddChild(_playerNameInput);

        // Connection buttons
        var buttonHBox = new HBoxContainer();
        buttonHBox.AddThemeConstantOverride("separation", 10);
        content.AddChild(buttonHBox);

        _connectButton = new Button();
        _connectButton.Text = "Connect";
        _connectButton.CustomMinimumSize = new Vector2(100, 35);
        _connectButton.Modulate = Colors.Green;
        buttonHBox.AddChild(_connectButton);

        _disconnectButton = new Button();
        _disconnectButton.Text = "Disconnect";
        _disconnectButton.CustomMinimumSize = new Vector2(100, 35);
        _disconnectButton.Modulate = Colors.Red;
        _disconnectButton.Disabled = true;
        buttonHBox.AddChild(_disconnectButton);

        // Status
        _connectionStatusLabel = new Label();
        _connectionStatusLabel.Text = "Status: Disconnected";
        _connectionStatusLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_connectionStatusLabel);
    }

    private void BuildLobbyPanel(HBoxContainer parent)
    {
        _lobbyPanel = CreateStyledPanel("Game Lobby", new Color(0.2f, 0.3f, 0.2f, 0.9f));
        parent.AddChild(_lobbyPanel);

        var content = GetPanelContent(_lobbyPanel);

        // Lobby status
        _lobbyStatusLabel = new Label();
        _lobbyStatusLabel.Text = "Connect to server to browse games";
        _lobbyStatusLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_lobbyStatusLabel);

        // Refresh button
        _refreshGamesButton = new Button();
        _refreshGamesButton.Text = "Refresh Games";
        _refreshGamesButton.CustomMinimumSize = new Vector2(0, 35);
        _refreshGamesButton.Disabled = true;
        content.AddChild(_refreshGamesButton);

        // Separator
        var separator = new HSeparator();
        content.AddChild(separator);

        // Available games list
        var gamesLabel = new Label();
        gamesLabel.Text = "Available Games:";
        gamesLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(gamesLabel);

        var scrollContainer = new ScrollContainer();
        scrollContainer.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        scrollContainer.CustomMinimumSize = new Vector2(0, 200);
        content.AddChild(scrollContainer);

        _gamesList = new VBoxContainer();
        _gamesList.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        _gamesList.AddThemeConstantOverride("separation", 5);
        scrollContainer.AddChild(_gamesList);

        // Initial empty state
        var noGamesLabel = new Label();
        noGamesLabel.Text = "No games available";
        noGamesLabel.HorizontalAlignment = HorizontalAlignment.Center;
        noGamesLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        _gamesList.AddChild(noGamesLabel);
    }

    private void BuildGamePanel(HBoxContainer parent)
    {
        _gamePanel = CreateStyledPanel("Game Actions", new Color(0.3f, 0.2f, 0.2f, 0.9f));
        parent.AddChild(_gamePanel);

        var content = GetPanelContent(_gamePanel);

        // Game joining
        var joinLabel = new Label();
        joinLabel.Text = "Join Existing Game:";
        joinLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(joinLabel);

        _gameCodeInput = new LineEdit();
        _gameCodeInput.PlaceholderText = "Enter game code";
        _gameCodeInput.Disabled = true;
        content.AddChild(_gameCodeInput);

        _joinGameButton = new Button();
        _joinGameButton.Text = "Join Game";
        _joinGameButton.CustomMinimumSize = new Vector2(0, 35);
        _joinGameButton.Disabled = true;
        content.AddChild(_joinGameButton);

        // Separator
        var separator = new HSeparator();
        content.AddChild(separator);

        // Game creation
        _createGameButton = new Button();
        _createGameButton.Text = "Create New Game";
        _createGameButton.CustomMinimumSize = new Vector2(0, 35);
        _createGameButton.Disabled = true;
        content.AddChild(_createGameButton);

        // Separator
        var separator2 = new HSeparator();
        content.AddChild(separator2);

        // Current game status
        _currentGameLabel = new Label();
        _currentGameLabel.Text = "Current Game: None";
        _currentGameLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_currentGameLabel);

        // Game players list
        var playersLabel = new Label();
        playersLabel.Text = "Players in Game:";
        playersLabel.AddThemeFontSizeOverride("font_size", 12);
        content.AddChild(playersLabel);

        var playersScrollContainer = new ScrollContainer();
        playersScrollContainer.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        playersScrollContainer.CustomMinimumSize = new Vector2(0, 100);
        content.AddChild(playersScrollContainer);

        _gamePlayersList = new VBoxContainer();
        _gamePlayersList.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        playersScrollContainer.AddChild(_gamePlayersList);

        // Initial empty state
        var noPlayersLabel = new Label();
        noPlayersLabel.Text = "Not in a game";
        noPlayersLabel.HorizontalAlignment = HorizontalAlignment.Center;
        noPlayersLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        _gamePlayersList.AddChild(noPlayersLabel);
    }

    private Panel CreateStyledPanel(string title, Color bgColor)
    {
        var panel = new Panel();
        panel.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        panel.SizeFlagsVertical = Control.SizeFlags.ExpandFill;

        var style = new StyleBoxFlat();
        style.BgColor = bgColor;
        style.BorderColor = new Color(0.4f, 0.5f, 0.6f);
        style.BorderWidthLeft = style.BorderWidthRight = style.BorderWidthTop = style.BorderWidthBottom = 2;
        style.CornerRadiusTopLeft = style.CornerRadiusTopRight = style.CornerRadiusBottomLeft = style.CornerRadiusBottomRight = 8;
        panel.AddThemeStyleboxOverride("panel", style);

        var content = new VBoxContainer();
        content.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        content.OffsetLeft = content.OffsetTop = 15;
        content.OffsetRight = content.OffsetBottom = -15;
        content.AddThemeConstantOverride("separation", 8);
        panel.AddChild(content);

        // Title
        var titleLabel = new Label();
        titleLabel.Text = title;
        titleLabel.HorizontalAlignment = HorizontalAlignment.Center;
        titleLabel.AddThemeFontSizeOverride("font_size", 16);
        titleLabel.AddThemeColorOverride("font_color", new Color(0.9f, 0.9f, 1.0f));
        content.AddChild(titleLabel);

        var separator = new HSeparator();
        content.AddChild(separator);

        return panel;
    }

    private VBoxContainer GetPanelContent(Panel panel)
    {
        return panel.GetChild(0) as VBoxContainer;
    }

    private void ConnectSignals()
    {
        _connectButton.Pressed += OnConnectPressed;
        _disconnectButton.Pressed += OnDisconnectPressed;
        _refreshGamesButton.Pressed += OnRefreshGamesPressed;
        _joinGameButton.Pressed += OnJoinGamePressed;
        _createGameButton.Pressed += OnCreateGamePressed;

        // Connect to GDScript autoload signals if available
        if (_networkManager != null)
        {
            _networkManager.Connect("connected_to_server", new Callable(this, nameof(OnConnectedToServer)));
            _networkManager.Connect("disconnected_from_server", new Callable(this, nameof(OnDisconnectedFromServer)));
            _networkManager.Connect("connection_failed", new Callable(this, nameof(OnConnectionFailed)));
        }

        if (_lobbyManager != null)
        {
            _lobbyManager.Connect("lobby_updated", new Callable(this, nameof(OnLobbyUpdated)));
            _lobbyManager.Connect("joined_game", new Callable(this, nameof(OnJoinedGame)));
            _lobbyManager.Connect("left_game", new Callable(this, nameof(OnLeftGame)));
        }

        // Input handling
        _serverAddressInput.TextSubmitted += (string text) => OnConnectPressed();
        _playerNameInput.TextSubmitted += (string text) => OnConnectPressed();
        _gameCodeInput.TextSubmitted += (string text) => OnJoinGamePressed();
    }

    private void SetupRefreshTimer()
    {
        _refreshTimer = new Timer();
        _refreshTimer.WaitTime = 5.0; // Refresh every 5 seconds when connected
        _refreshTimer.Timeout += UpdateGamesList;
        AddChild(_refreshTimer);
    }

    private void OnConnectPressed()
    {
        var serverAddress = _serverAddressInput.Text.Trim();
        var playerName = _playerNameInput.Text.Trim();

        if (string.IsNullOrEmpty(serverAddress))
        {
            ShowStatus("Please enter a server address", Colors.Red);
            return;
        }

        if (string.IsNullOrEmpty(playerName))
        {
            ShowStatus("Please enter a player name", Colors.Red);
            return;
        }

        _connectionStatusLabel.Text = "Status: Connecting...";
        _connectionStatusLabel.Modulate = Colors.Yellow;
        _connectButton.Disabled = true;

        // Parse server address
        var parts = serverAddress.Split(':');
        string host = parts[0];
        int port = parts.Length > 1 && int.TryParse(parts[1], out int parsedPort) ? parsedPort : 9957;

        // Call GDScript NetworkManager.connect_to_server
        bool result = (bool)_networkManager?.Call("connect_to_server", host, port, playerName);
        if (!result)
        {
            OnConnectionFailed("Failed to initiate connection");
        }
    }

    private void OnDisconnectPressed()
    {
        _networkManager?.Call("disconnect_from_server");
        _refreshTimer.Stop();
    }

    private void OnRefreshGamesPressed()
    {
        _lobbyManager?.Call("request_lobby_update");
        ShowStatus("Refreshing games list...", Colors.Yellow);
    }

    private void OnJoinGamePressed()
    {
        var gameCode = _gameCodeInput.Text.Trim();
        if (string.IsNullOrEmpty(gameCode))
        {
            ShowStatus("Please enter a game code", Colors.Red);
            return;
        }

        bool result = (bool)_lobbyManager?.Call("join_game", gameCode);
        if (result)
        {
            ShowStatus($"Attempting to join game: {gameCode}", Colors.Yellow);
        }
        else
        {
            ShowStatus("Failed to join game", Colors.Red);
        }
    }

    private void OnCreateGamePressed()
    {
        bool result = (bool)_lobbyManager?.Call("create_game");
        if (result)
        {
            ShowStatus("Creating new game...", Colors.Yellow);
        }
        else
        {
            ShowStatus("Failed to create game", Colors.Red);
        }
    }

    private void OnConnectedToServer()
    {
        _isConnected = true;
        UpdateConnectionStatus();
        _refreshTimer.Start();
        ShowStatus("Connected to server successfully", Colors.Green);
    }

    private void OnDisconnectedFromServer()
    {
        _isConnected = false;
        _currentGameCode = "";
        UpdateConnectionStatus();
        _refreshTimer.Stop();
        ShowStatus("Disconnected from server", Colors.Orange);
    }

    private void OnConnectionFailed(string reason)
    {
        _isConnected = false;
        UpdateConnectionStatus();
        ShowStatus($"Connection failed: {reason}", Colors.Red);
    }

    private void OnLobbyUpdated()
    {
        UpdateGamesList();
    }

    private void OnJoinedGame(string gameCode)
    {
        _currentGameCode = gameCode;
        _currentGameLabel.Text = $"Current Game: {gameCode}";
        _currentGameLabel.Modulate = Colors.Green;
        UpdateGamePlayersList();
        ShowStatus($"Joined game: {gameCode}", Colors.Green);
    }

    private void OnLeftGame(string gameCode)
    {
        _currentGameCode = "";
        _currentGameLabel.Text = "Current Game: None";
        _currentGameLabel.Modulate = Colors.White;
        UpdateGamePlayersList();
        ShowStatus($"Left game: {gameCode}", Colors.Orange);
    }

    private void UpdateConnectionStatus()
    {
        if (_isConnected)
        {
            _connectionStatusLabel.Text = "Status: Connected";
            _connectionStatusLabel.Modulate = Colors.Green;
            _connectButton.Disabled = true;
            _disconnectButton.Disabled = false;
            _refreshGamesButton.Disabled = false;
            _gameCodeInput.Disabled = false;
            _joinGameButton.Disabled = false;
            _createGameButton.Disabled = false;
            _lobbyStatusLabel.Text = "Connected to server - Browse or create games";
        }
        else
        {
            _connectionStatusLabel.Text = "Status: Disconnected";
            _connectionStatusLabel.Modulate = Colors.Red;
            _connectButton.Disabled = false;
            _disconnectButton.Disabled = true;
            _refreshGamesButton.Disabled = true;
            _gameCodeInput.Disabled = true;
            _joinGameButton.Disabled = true;
            _createGameButton.Disabled = true;
            _lobbyStatusLabel.Text = "Connect to server to browse games";
        }
    }

    private void UpdateGamesList()
    {
        if (!_isConnected) return;

        // Clear existing entries
        foreach (Node child in _gamesList.GetChildren())
        {
            child.QueueFree();
        }

        var games = _lobbyManager?.Call("get_available_games") as Godot.Collections.Array;
        if (games == null || games.Count == 0)
        {
            var noGamesLabel = new Label();
            noGamesLabel.Text = "No games available";
            noGamesLabel.HorizontalAlignment = HorizontalAlignment.Center;
            noGamesLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
            _gamesList.AddChild(noGamesLabel);
        }
        else
        {
            foreach (var gameData in games)
            {
                var gameDict = gameData as Godot.Collections.Dictionary;
                if (gameDict != null)
                {
                    var gamePanel = CreateGameListItem(gameDict);
                    _gamesList.AddChild(gamePanel);
                }
            }
        }
    }

    private Panel CreateGameListItem(Godot.Collections.Dictionary gameData)
    {
        var panel = new Panel();
        panel.CustomMinimumSize = new Vector2(0, 60);

        var style = new StyleBoxFlat();
        style.BgColor = new Color(0.25f, 0.25f, 0.3f, 0.8f);
        style.BorderColor = new Color(0.4f, 0.5f, 0.6f);
        style.BorderWidthLeft = style.BorderWidthRight = style.BorderWidthTop = style.BorderWidthBottom = 1;
        style.CornerRadiusTopLeft = style.CornerRadiusTopRight = style.CornerRadiusBottomLeft = style.CornerRadiusBottomRight = 4;
        panel.AddThemeStyleboxOverride("panel", style);

        var hbox = new HBoxContainer();
        hbox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        hbox.OffsetLeft = hbox.OffsetTop = 8;
        hbox.OffsetRight = hbox.OffsetBottom = -8;
        hbox.AddThemeConstantOverride("separation", 10);
        panel.AddChild(hbox);

        // Game info
        var infoVBox = new VBoxContainer();
        infoVBox.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        hbox.AddChild(infoVBox);

        var gameCode = gameData.GetValueOrDefault("code", "Unknown").AsString();
        var playerCount = gameData.GetValueOrDefault("players", 0).AsInt32();
        var maxPlayers = gameData.GetValueOrDefault("max_players", 4).AsInt32();
        var isStarted = gameData.GetValueOrDefault("started", false).AsBool();

        var titleLabel = new Label();
        titleLabel.Text = $"Game: {gameCode}";
        titleLabel.AddThemeFontSizeOverride("font_size", 14);
        infoVBox.AddChild(titleLabel);

        var statusLabel = new Label();
        statusLabel.Text = $"Players: {playerCount}/{maxPlayers} | Status: {(isStarted ? "STARTED" : "WAITING")}";
        statusLabel.AddThemeFontSizeOverride("font_size", 12);
        statusLabel.Modulate = isStarted ? Colors.Orange : Colors.Green;
        infoVBox.AddChild(statusLabel);

        // Join button
        var joinButton = new Button();
        joinButton.Text = "Join";
        joinButton.CustomMinimumSize = new Vector2(60, 0);
        joinButton.Disabled = isStarted || playerCount >= maxPlayers;
        joinButton.Pressed += () => {
            _gameCodeInput.Text = gameCode;
            OnJoinGamePressed();
        };
        hbox.AddChild(joinButton);

        return panel;
    }

    private void UpdateGamePlayersList()
    {
        // Clear existing entries
        foreach (Node child in _gamePlayersList.GetChildren())
        {
            child.QueueFree();
        }

        if (string.IsNullOrEmpty(_currentGameCode))
        {
            var noPlayersLabel = new Label();
            noPlayersLabel.Text = "Not in a game";
            noPlayersLabel.HorizontalAlignment = HorizontalAlignment.Center;
            noPlayersLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
            _gamePlayersList.AddChild(noPlayersLabel);
            return;
        }

        var gameInfo = _lobbyManager?.Call("get_current_game_info") as Godot.Collections.Dictionary;
        var players = gameInfo?.GetValueOrDefault("players", new Godot.Collections.Array()) as Godot.Collections.Array;

        if (players == null || players.Count == 0)
        {
            var noPlayersLabel = new Label();
            noPlayersLabel.Text = "No players in game";
            noPlayersLabel.HorizontalAlignment = HorizontalAlignment.Center;
            noPlayersLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
            _gamePlayersList.AddChild(noPlayersLabel);
        }
        else
        {
            foreach (var playerData in players)
            {
                var playerDict = playerData as Godot.Collections.Dictionary;
                if (playerDict != null)
                {
                    var playerLabel = new Label();
                    var playerName = playerDict.GetValueOrDefault("name", "Unknown").AsString();
                    var isHost = playerDict.GetValueOrDefault("is_host", false).AsBool();
                    playerLabel.Text = $"{playerName}{(isHost ? " (Host)" : "")}";
                    playerLabel.Modulate = isHost ? Colors.Yellow : Colors.White;
                    _gamePlayersList.AddChild(playerLabel);
                }
            }
        }
    }

    private async void ShowStatus(string message, Color color)
    {
        var statusLabel = new Label();
        statusLabel.Text = message;
        statusLabel.Modulate = color;
        statusLabel.Position = new Vector2(20, 50);
        statusLabel.AddThemeFontSizeOverride("font_size", 12);
        AddChild(statusLabel);

        await ToSignal(GetTree().CreateTimer(3.0), SceneTreeTimer.SignalName.Timeout);
        
        if (statusLabel != null && IsInsideTree())
        {
            statusLabel.QueueFree();
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey keyEvent && keyEvent.Pressed)
        {
            switch (keyEvent.Keycode)
            {
                case Key.F5:
                    if (_isConnected)
                        OnRefreshGamesPressed();
                    break;
                case Key.F1:
                    if (!_isConnected)
                        OnConnectPressed();
                    break;
                case Key.F2:
                    if (_isConnected)
                        OnDisconnectPressed();
                    break;
                case Key.Enter:
                    if (!_isConnected)
                        OnConnectPressed();
                    else if (!string.IsNullOrEmpty(_gameCodeInput.Text))
                        OnJoinGamePressed();
                    break;
            }
        }
    }
}
