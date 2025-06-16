using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// Server Mechanics Test - C# Implementation
/// Tests server functionality including start/stop, game creation, and client connections
/// </summary>
public partial class ServerMechanicsTest : Control
{
    // UI Components
    private Panel _serverPanel;
    private Panel _gamePanel;
    private Panel _clientPanel;
    
    // Server Controls
    private Button _startServerButton;
    private Button _stopServerButton;
    private Label _serverStatusLabel;
    private Label _portLabel;
    private Label _connectionsLabel;
    
    // Game Controls
    private Button _createGameButton;
    private LineEdit _gameCodeInput;
    private Label _gamesListLabel;
    private VBoxContainer _gamesList;
    
    // Client Simulation
    private Button _simulateClientButton;
    private LineEdit _clientNameInput;
    private Label _connectedClientsLabel;
    private VBoxContainer _clientsList;
    
    // State
    private Timer _refreshTimer;
    private int _simulatedClientCount = 0;
    
    // GDScript Autoload References
    private Node _networkManager;
    private Node _lobbyManager;

    public override void _Ready()
    {
        GetWindow().Title = "Mexican Train - Server Mechanics Test";
        
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
        UpdateServerStatus();
        
        GD.Print("C# Server Mechanics Test initialized successfully");
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
        titleLabel.Text = "Server Mechanics Testing Dashboard";
        titleLabel.HorizontalAlignment = HorizontalAlignment.Center;
        titleLabel.AddThemeFontSizeOverride("font_size", 24);
        titleLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        mainVBox.AddChild(titleLabel);

        // Create horizontal layout for panels
        var mainHBox = new HBoxContainer();
        mainHBox.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        mainHBox.AddThemeConstantOverride("separation", 15);
        mainVBox.AddChild(mainHBox);

        // Build panels
        BuildServerPanel(mainHBox);
        BuildGamePanel(mainHBox);
        BuildClientPanel(mainHBox);
    }

    private void BuildServerPanel(HBoxContainer parent)
    {
        _serverPanel = CreateStyledPanel("Server Control", new Color(0.2f, 0.3f, 0.2f, 0.9f));
        parent.AddChild(_serverPanel);

        var content = GetPanelContent(_serverPanel);

        // Server status
        _serverStatusLabel = new Label();
        _serverStatusLabel.Text = "Server Status: STOPPED";
        _serverStatusLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_serverStatusLabel);

        _portLabel = new Label();
        _portLabel.Text = "Port: 9957";
        content.AddChild(_portLabel);

        _connectionsLabel = new Label();
        _connectionsLabel.Text = "Connections: 0";
        content.AddChild(_connectionsLabel);

        // Separator
        var separator = new HSeparator();
        content.AddChild(separator);

        // Control buttons
        var buttonContainer = new HBoxContainer();
        buttonContainer.AddThemeConstantOverride("separation", 10);
        content.AddChild(buttonContainer);

        _startServerButton = new Button();
        _startServerButton.Text = "Start Server";
        _startServerButton.CustomMinimumSize = new Vector2(100, 35);
        _startServerButton.Modulate = Colors.Green;
        buttonContainer.AddChild(_startServerButton);

        _stopServerButton = new Button();
        _stopServerButton.Text = "Stop Server";
        _stopServerButton.CustomMinimumSize = new Vector2(100, 35);
        _stopServerButton.Modulate = Colors.Red;
        _stopServerButton.Disabled = true;
        buttonContainer.AddChild(_stopServerButton);
    }

    private void BuildGamePanel(HBoxContainer parent)
    {
        _gamePanel = CreateStyledPanel("Game Management", new Color(0.2f, 0.2f, 0.3f, 0.9f));
        parent.AddChild(_gamePanel);

        var content = GetPanelContent(_gamePanel);

        // Game creation
        var gameLabel = new Label();
        gameLabel.Text = "Create New Game:";
        gameLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(gameLabel);

        _gameCodeInput = new LineEdit();
        _gameCodeInput.PlaceholderText = "Game code (optional)";
        content.AddChild(_gameCodeInput);

        _createGameButton = new Button();
        _createGameButton.Text = "Create Game";
        _createGameButton.CustomMinimumSize = new Vector2(0, 35);
        _createGameButton.Disabled = true;
        content.AddChild(_createGameButton);

        // Separator
        var separator = new HSeparator();
        content.AddChild(separator);

        // Games list
        _gamesListLabel = new Label();
        _gamesListLabel.Text = "Active Games:";
        _gamesListLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_gamesListLabel);

        var scrollContainer = new ScrollContainer();
        scrollContainer.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        scrollContainer.CustomMinimumSize = new Vector2(0, 200);
        content.AddChild(scrollContainer);

        _gamesList = new VBoxContainer();
        _gamesList.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        scrollContainer.AddChild(_gamesList);

        // Initial empty state
        var noGamesLabel = new Label();
        noGamesLabel.Text = "No active games";
        noGamesLabel.HorizontalAlignment = HorizontalAlignment.Center;
        noGamesLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        _gamesList.AddChild(noGamesLabel);
    }

    private void BuildClientPanel(HBoxContainer parent)
    {
        _clientPanel = CreateStyledPanel("Client Simulation", new Color(0.3f, 0.2f, 0.2f, 0.9f));
        parent.AddChild(_clientPanel);

        var content = GetPanelContent(_clientPanel);

        // Client simulation
        var clientLabel = new Label();
        clientLabel.Text = "Simulate Client Connection:";
        clientLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(clientLabel);

        _clientNameInput = new LineEdit();
        _clientNameInput.PlaceholderText = "Client name";
        _clientNameInput.Text = "TestClient";
        content.AddChild(_clientNameInput);

        _simulateClientButton = new Button();
        _simulateClientButton.Text = "Connect Client";
        _simulateClientButton.CustomMinimumSize = new Vector2(0, 35);
        _simulateClientButton.Disabled = true;
        content.AddChild(_simulateClientButton);

        // Separator
        var separator = new HSeparator();
        content.AddChild(separator);

        // Connected clients
        _connectedClientsLabel = new Label();
        _connectedClientsLabel.Text = "Connected Clients:";
        _connectedClientsLabel.AddThemeFontSizeOverride("font_size", 14);
        content.AddChild(_connectedClientsLabel);

        var scrollContainer = new ScrollContainer();
        scrollContainer.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        scrollContainer.CustomMinimumSize = new Vector2(0, 150);
        content.AddChild(scrollContainer);

        _clientsList = new VBoxContainer();
        _clientsList.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        scrollContainer.AddChild(_clientsList);

        // Initial empty state
        var noClientsLabel = new Label();
        noClientsLabel.Text = "No connected clients";
        noClientsLabel.HorizontalAlignment = HorizontalAlignment.Center;
        noClientsLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        _clientsList.AddChild(noClientsLabel);
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
        _startServerButton.Pressed += OnStartServerPressed;
        _stopServerButton.Pressed += OnStopServerPressed;
        _createGameButton.Pressed += OnCreateGamePressed;
        _simulateClientButton.Pressed += OnSimulateClientPressed;

        // Connect to GDScript autoload signals if available
        if (_networkManager != null)
        {
            // Connect to server status signals
            _networkManager.Connect("server_started", new Callable(this, nameof(OnServerStarted)));
            _networkManager.Connect("server_stopped", new Callable(this, nameof(OnServerStopped)));
            _networkManager.Connect("client_connected", new Callable(this, nameof(OnClientConnected)));
            _networkManager.Connect("client_disconnected", new Callable(this, nameof(OnClientDisconnected)));
        }

        if (_lobbyManager != null)
        {
            // Connect to game management signals
            _lobbyManager.Connect("game_created", new Callable(this, nameof(OnGameCreated)));
            _lobbyManager.Connect("lobby_updated", new Callable(this, nameof(OnLobbyUpdated)));
        }
    }

    private void SetupRefreshTimer()
    {
        _refreshTimer = new Timer();
        _refreshTimer.WaitTime = 2.0; // Refresh every 2 seconds
        _refreshTimer.Timeout += UpdateServerStatus;
        _refreshTimer.Autostart = true;
        AddChild(_refreshTimer);
    }

    private void OnStartServerPressed()
    {
        bool result = (bool)_networkManager?.Call("start_server");
        if (result)
        {
            GD.Print("Server start initiated");
        }
        else
        {
            ShowStatus("Failed to start server", Colors.Red);
        }
    }

    private void OnStopServerPressed()
    {
        _networkManager?.Call("disconnect_from_server");
        GD.Print("Server stop initiated");
    }

    private void OnCreateGamePressed()
    {
        var gameCode = _gameCodeInput.Text.Trim();
        if (string.IsNullOrEmpty(gameCode))
        {
            gameCode = GenerateGameCode();
        }

        bool result = (bool)_lobbyManager?.Call("create_game", gameCode);
        if (result)
        {
            _gameCodeInput.Text = "";
            ShowStatus($"Game '{gameCode}' created", Colors.Green);
        }
        else
        {
            ShowStatus("Failed to create game", Colors.Red);
        }
    }

    private void OnSimulateClientPressed()
    {
        var clientName = _clientNameInput.Text.Trim();
        if (string.IsNullOrEmpty(clientName))
        {
            clientName = $"TestClient{_simulatedClientCount + 1}";
        }

        // Simulate client connection (this would normally connect to localhost)
        GD.Print($"Simulating client connection: {clientName}");
        _simulatedClientCount++;
        _clientNameInput.Text = "";
        ShowStatus($"Client '{clientName}' simulated", Colors.Yellow);
    }

    private void OnServerStarted()
    {
        UpdateServerStatus();
        ShowStatus("Server started successfully", Colors.Green);
    }

    private void OnServerStopped()
    {
        UpdateServerStatus();
        ShowStatus("Server stopped", Colors.Orange);
    }

    private void OnClientConnected(int peerId)
    {
        UpdateConnectedClients();
        ShowStatus($"Client connected (ID: {peerId})", Colors.Green);
    }

    private void OnClientDisconnected(int peerId)
    {
        UpdateConnectedClients();
        ShowStatus($"Client disconnected (ID: {peerId})", Colors.Orange);
    }

    private void OnGameCreated(string gameCode)
    {
        UpdateGamesList();
        ShowStatus($"Game created: {gameCode}", Colors.Green);
    }

    private void OnLobbyUpdated()
    {
        UpdateGamesList();
    }

    private void UpdateServerStatus()
    {
        bool isServerRunning = (bool)_networkManager?.Call("is_server_running");
        
        if (isServerRunning)
        {
            _serverStatusLabel.Text = "Server Status: RUNNING";
            _serverStatusLabel.Modulate = Colors.Green;
            _startServerButton.Disabled = true;
            _stopServerButton.Disabled = false;
            _createGameButton.Disabled = false;
            _simulateClientButton.Disabled = false;
        }
        else
        {
            _serverStatusLabel.Text = "Server Status: STOPPED";
            _serverStatusLabel.Modulate = Colors.Red;
            _startServerButton.Disabled = false;
            _stopServerButton.Disabled = true;
            _createGameButton.Disabled = true;
            _simulateClientButton.Disabled = true;
        }

        UpdateConnectedClients();
        UpdateGamesList();
    }

    private void UpdateConnectedClients()
    {
        // Clear existing entries
        foreach (Node child in _clientsList.GetChildren())
        {
            child.QueueFree();
        }

        var peers = _networkManager?.Call("get_peers") as Godot.Collections.Array;
        if (peers == null || peers.Count == 0)
        {
            var noClientsLabel = new Label();
            noClientsLabel.Text = "No connected clients";
            noClientsLabel.HorizontalAlignment = HorizontalAlignment.Center;
            noClientsLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
            _clientsList.AddChild(noClientsLabel);
        }
        else
        {
            foreach (var peerId in peers)
            {
                var clientLabel = new Label();
                clientLabel.Text = $"Client ID: {peerId}";
                _clientsList.AddChild(clientLabel);
            }
        }

        _connectionsLabel.Text = $"Connections: {peers?.Count ?? 0}";
    }

    private void UpdateGamesList()
    {
        // Clear existing entries
        foreach (Node child in _gamesList.GetChildren())
        {
            child.QueueFree();
        }

        var games = _lobbyManager?.Call("get_all_games") as Godot.Collections.Array;
        if (games == null || games.Count == 0)
        {
            var noGamesLabel = new Label();
            noGamesLabel.Text = "No active games";
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
                    var gameLabel = new Label();
                    var gameCode = gameDict.GetValueOrDefault("code", "Unknown").AsString();
                    var playerCount = gameDict.GetValueOrDefault("players", 0).AsInt32();
                    gameLabel.Text = $"Game: {gameCode} ({playerCount} players)";
                    _gamesList.AddChild(gameLabel);
                }
            }
        }
    }

    private string GenerateGameCode()
    {
        var random = new Random();
        return $"TEST{random.Next(1000, 9999)}";
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
                    UpdateServerStatus();
                    ShowStatus("Status refreshed", Colors.Yellow);
                    break;
                case Key.F1:
                    OnStartServerPressed();
                    break;
                case Key.F2:
                    OnStopServerPressed();
                    break;
                case Key.F3:
                    OnCreateGamePressed();
                    break;
            }
        }
    }
}
