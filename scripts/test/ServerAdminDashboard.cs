using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// Server Administration Dashboard - Fully Programmatic C# Implementation
/// Handles admin authentication, server monitoring, and game management
/// </summary>
public partial class ServerAdminDashboard : Control
{
    // UI Components - Login Panel
    private Panel _loginPanel;
    private LineEdit _emailInput;
    private LineEdit _passwordInput;
    private Button _loginButton;
    private Label _statusLabel;

    // UI Components - Dashboard Panel
    private Panel _dashboardPanel;
    private Label _adminInfoLabel;
    private Label _serverStatusLabel;
    private Label _versionLabel;
    private Label _uptimeLabel;
    private Label _activeGamesLabel;
    private Label _activePlayersLabel;
    private Label _memoryLabel;
    private Label _networkLabel;
    private Label _platformLabel;
    private VBoxContainer _gamesList;
    private Button _refreshButton;
    private Button _logoutButton;
    private Button _serverControlButton;

    // State
    private string _currentAdminEmail = "";
    private Timer _refreshTimer;
    
    // GDScript Autoload References (accessed via GetNode)
    private Node _serverAdmin;
    private Node _networkManager;

    public override void _Ready()
    {
        GetWindow().Title = "Mexican Train - Server Administration Dashboard";
        
        // Get references to GDScript autoloads
        _serverAdmin = GetNode("/root/ServerAdmin");
        _networkManager = GetNode("/root/NetworkManager");
        
        // Build the entire UI programmatically
        BuildUI();
        
        // Connect signals
        ConnectSignals();
        
        // Setup auto-refresh timer
        SetupRefreshTimer();
        
        // Start with login panel visible
        ShowLoginPanel();
        
        GD.Print("C# Server Admin Dashboard initialized successfully");
    }

    private void BuildUI()
    {
        // Setup main container
        SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        
        var mainVBox = new VBoxContainer();
        mainVBox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        mainVBox.AddThemeConstantOverride("separation", 10);
        AddChild(mainVBox);

        // Add padding
        mainVBox.OffsetLeft = 20;
        mainVBox.OffsetTop = 20;
        mainVBox.OffsetRight = -20;
        mainVBox.OffsetBottom = -20;

        // Title
        var titleLabel = new Label();
        titleLabel.Text = "Mexican Train - Server Administration Dashboard";
        titleLabel.HorizontalAlignment = HorizontalAlignment.Center;
        titleLabel.AddThemeStyleboxOverride("normal", new StyleBoxEmpty());
        titleLabel.AddThemeFontSizeOverride("font_size", 24);
        mainVBox.AddChild(titleLabel);

        // Separator
        var separator = new HSeparator();
        mainVBox.AddChild(separator);

        // Build Login Panel
        BuildLoginPanel(mainVBox);

        // Build Dashboard Panel
        BuildDashboardPanel(mainVBox);
    }

    private void BuildLoginPanel(VBoxContainer parent)
    {
        _loginPanel = new Panel();
        _loginPanel.CustomMinimumSize = new Vector2(0, 150);
        
        var style = new StyleBoxFlat();
        style.BgColor = new Color(0.2f, 0.2f, 0.3f, 0.8f);
        style.BorderColor = new Color(0.4f, 0.4f, 0.6f);
        style.BorderWidthLeft = style.BorderWidthRight = style.BorderWidthTop = style.BorderWidthBottom = 2;
        style.CornerRadiusTopLeft = style.CornerRadiusTopRight = style.CornerRadiusBottomLeft = style.CornerRadiusBottomRight = 8;
        _loginPanel.AddThemeStyleboxOverride("panel", style);
        
        parent.AddChild(_loginPanel);

        var loginVBox = new VBoxContainer();
        loginVBox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        loginVBox.OffsetLeft = loginVBox.OffsetTop = 15;
        loginVBox.OffsetRight = loginVBox.OffsetBottom = -15;
        loginVBox.AddThemeConstantOverride("separation", 8);
        _loginPanel.AddChild(loginVBox);

        // Login header
        var loginLabel = new Label();
        loginLabel.Text = "Admin Authentication Required";
        loginLabel.HorizontalAlignment = HorizontalAlignment.Center;
        loginLabel.AddThemeFontSizeOverride("font_size", 16);
        loginVBox.AddChild(loginLabel);

        // Email input
        _emailInput = new LineEdit();
        _emailInput.PlaceholderText = "Enter admin email address";
        _emailInput.Text = "admin@mexicantrain.local"; // Pre-fill for convenience
        loginVBox.AddChild(_emailInput);

        // Password input
        _passwordInput = new LineEdit();
        _passwordInput.PlaceholderText = "Enter password";
        _passwordInput.Secret = true;
        _passwordInput.Text = "admin123"; // Pre-fill for convenience
        loginVBox.AddChild(_passwordInput);

        // Login button
        _loginButton = new Button();
        _loginButton.Text = "Login as Admin";
        _loginButton.CustomMinimumSize = new Vector2(0, 35);
        loginVBox.AddChild(_loginButton);

        // Status label
        _statusLabel = new Label();
        _statusLabel.Text = "Please enter credentials to access server administration";
        _statusLabel.HorizontalAlignment = HorizontalAlignment.Center;
        _statusLabel.AutowrapMode = TextServer.AutowrapMode.WordSmart;
        loginVBox.AddChild(_statusLabel);
    }

    private void BuildDashboardPanel(VBoxContainer parent)
    {
        _dashboardPanel = new Panel();
        _dashboardPanel.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        _dashboardPanel.Visible = false;

        var dashStyle = new StyleBoxFlat();
        dashStyle.BgColor = new Color(0.15f, 0.15f, 0.2f, 0.9f);
        dashStyle.BorderColor = new Color(0.3f, 0.4f, 0.5f);
        dashStyle.BorderWidthLeft = dashStyle.BorderWidthRight = dashStyle.BorderWidthTop = dashStyle.BorderWidthBottom = 2;
        dashStyle.CornerRadiusTopLeft = dashStyle.CornerRadiusTopRight = dashStyle.CornerRadiusBottomLeft = dashStyle.CornerRadiusBottomRight = 8;
        _dashboardPanel.AddThemeStyleboxOverride("panel", dashStyle);

        parent.AddChild(_dashboardPanel);

        var dashboardVBox = new VBoxContainer();
        dashboardVBox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        dashboardVBox.OffsetLeft = dashboardVBox.OffsetTop = 15;
        dashboardVBox.OffsetRight = dashboardVBox.OffsetBottom = -15;
        dashboardVBox.AddThemeConstantOverride("separation", 10);
        _dashboardPanel.AddChild(dashboardVBox);

        // Admin info
        _adminInfoLabel = new Label();
        _adminInfoLabel.Text = "Logged in as: Loading...";
        _adminInfoLabel.AddThemeFontSizeOverride("font_size", 14);
        dashboardVBox.AddChild(_adminInfoLabel);

        // Server info container
        var serverInfoContainer = new HBoxContainer();
        serverInfoContainer.AddThemeConstantOverride("separation", 20);
        dashboardVBox.AddChild(serverInfoContainer);

        // Left column - Server status
        BuildLeftColumn(serverInfoContainer);

        // Right column - System resources
        BuildRightColumn(serverInfoContainer);

        // Separator
        var separator2 = new HSeparator();
        dashboardVBox.AddChild(separator2);

        // Games section
        BuildGamesSection(dashboardVBox);

        // Control buttons
        BuildControlButtons(dashboardVBox);
    }

    private void BuildLeftColumn(HBoxContainer parent)
    {
        var leftColumn = new VBoxContainer();
        leftColumn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        leftColumn.AddThemeConstantOverride("separation", 5);
        parent.AddChild(leftColumn);

        var serverLabel = new Label();
        serverLabel.Text = "Server Information";
        serverLabel.AddThemeFontSizeOverride("font_size", 16);
        serverLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        leftColumn.AddChild(serverLabel);

        _serverStatusLabel = new Label();
        _serverStatusLabel.Text = "Server Status: Checking...";
        leftColumn.AddChild(_serverStatusLabel);

        _versionLabel = new Label();
        _versionLabel.Text = "Version: 0.6.0";
        leftColumn.AddChild(_versionLabel);

        _uptimeLabel = new Label();
        _uptimeLabel.Text = "Uptime: 0s";
        leftColumn.AddChild(_uptimeLabel);

        _activeGamesLabel = new Label();
        _activeGamesLabel.Text = "Active Games: 0";
        leftColumn.AddChild(_activeGamesLabel);

        _activePlayersLabel = new Label();
        _activePlayersLabel.Text = "Active Players: 0";
        leftColumn.AddChild(_activePlayersLabel);
    }

    private void BuildRightColumn(HBoxContainer parent)
    {
        var rightColumn = new VBoxContainer();
        rightColumn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        rightColumn.AddThemeConstantOverride("separation", 5);
        parent.AddChild(rightColumn);

        var resourceLabel = new Label();
        resourceLabel.Text = "System Resources";
        resourceLabel.AddThemeFontSizeOverride("font_size", 16);
        resourceLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        rightColumn.AddChild(resourceLabel);

        _memoryLabel = new Label();
        _memoryLabel.Text = "Memory Usage: 0 MB";
        rightColumn.AddChild(_memoryLabel);

        _networkLabel = new Label();
        _networkLabel.Text = "Network: Port 9957";
        rightColumn.AddChild(_networkLabel);

        _platformLabel = new Label();
        _platformLabel.Text = "Platform: " + OS.GetName();
        rightColumn.AddChild(_platformLabel);
    }

    private void BuildGamesSection(VBoxContainer parent)
    {
        var gamesLabel = new Label();
        gamesLabel.Text = "Active Games:";
        gamesLabel.AddThemeFontSizeOverride("font_size", 16);
        gamesLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        parent.AddChild(gamesLabel);

        var scrollContainer = new ScrollContainer();
        scrollContainer.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        scrollContainer.CustomMinimumSize = new Vector2(0, 200);
        parent.AddChild(scrollContainer);

        _gamesList = new VBoxContainer();
        _gamesList.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        _gamesList.AddThemeConstantOverride("separation", 5);
        scrollContainer.AddChild(_gamesList);

        // Initial empty state
        var noGamesLabel = new Label();
        noGamesLabel.Text = "No active games";
        noGamesLabel.HorizontalAlignment = HorizontalAlignment.Center;
        noGamesLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        _gamesList.AddChild(noGamesLabel);
    }

    private void BuildControlButtons(VBoxContainer parent)
    {
        var buttonContainer = new HBoxContainer();
        buttonContainer.Alignment = BoxContainer.AlignmentMode.Center;
        buttonContainer.AddThemeConstantOverride("separation", 15);
        parent.AddChild(buttonContainer);

        _refreshButton = new Button();
        _refreshButton.Text = "Refresh Data";
        _refreshButton.CustomMinimumSize = new Vector2(120, 35);
        buttonContainer.AddChild(_refreshButton);

        _serverControlButton = new Button();
        _serverControlButton.Text = "Start Server";
        _serverControlButton.CustomMinimumSize = new Vector2(120, 35);
        buttonContainer.AddChild(_serverControlButton);

        _logoutButton = new Button();
        _logoutButton.Text = "Logout";
        _logoutButton.CustomMinimumSize = new Vector2(120, 35);
        buttonContainer.AddChild(_logoutButton);
    }

    private void ConnectSignals()
    {
        // Login button
        _loginButton.Pressed += OnLoginPressed;

        // Dashboard buttons
        _refreshButton.Pressed += OnRefreshPressed;
        _logoutButton.Pressed += OnLogoutPressed;
        _serverControlButton.Pressed += OnServerControlPressed;

        // Connect to GDScript autoload signals
        if (_serverAdmin != null)
        {
            _serverAdmin.Connect("admin_authenticated", new Callable(this, nameof(OnAdminAuthenticated)));
            _serverAdmin.Connect("admin_access_denied", new Callable(this, nameof(OnAdminAccessDenied)));
        }

        // Input handling
        _emailInput.TextSubmitted += (string text) => OnLoginPressed();
        _passwordInput.TextSubmitted += (string text) => OnLoginPressed();
    }

    private void SetupRefreshTimer()
    {
        _refreshTimer = new Timer();
        _refreshTimer.WaitTime = 10.0; // Refresh every 10 seconds
        _refreshTimer.Timeout += UpdateDashboardData;
        AddChild(_refreshTimer);
    }

    private void ShowLoginPanel()
    {
        _loginPanel.Visible = true;
        _dashboardPanel.Visible = false;
        _statusLabel.Text = "Please enter credentials to access server administration";
        _statusLabel.Modulate = Colors.White;
    }

    private void ShowDashboardPanel()
    {
        _loginPanel.Visible = false;
        _dashboardPanel.Visible = true;
        _refreshTimer.Start();
        UpdateDashboardData();
    }

    private void OnLoginPressed()
    {
        var email = _emailInput.Text.Trim();
        var password = _passwordInput.Text;

        if (string.IsNullOrEmpty(email))
        {
            ShowLoginError("Please enter an email address");
            return;
        }

        if (string.IsNullOrEmpty(password))
        {
            ShowLoginError("Please enter a password");
            return;
        }

        _statusLabel.Text = "Authenticating...";
        _statusLabel.Modulate = Colors.Yellow;
        _loginButton.Disabled = true;

        // Call GDScript ServerAdmin.authenticate_admin
        _serverAdmin?.Call("authenticate_admin", email, password);
    }

    private void OnAdminAuthenticated(string adminEmail)
    {
        _currentAdminEmail = adminEmail;
        GD.Print($"C# Admin Dashboard: Authentication successful for {adminEmail}");
        ShowDashboardPanel();
    }

    private void OnAdminAccessDenied(string email, string reason)
    {
        ShowLoginError($"Access denied: {reason}");
        _loginButton.Disabled = false;
    }

    private void ShowLoginError(string message)
    {
        _statusLabel.Text = message;
        _statusLabel.Modulate = Colors.Red;
        _loginButton.Disabled = false;
    }

    private async void OnRefreshPressed()
    {
        UpdateDashboardData();
        _refreshButton.Text = "Refreshed!";
        _refreshButton.Disabled = true;

        await ToSignal(GetTree().CreateTimer(1.0), SceneTreeTimer.SignalName.Timeout);
        
        _refreshButton.Text = "Refresh Data";
        _refreshButton.Disabled = false;
    }

    private void OnLogoutPressed()
    {
        _serverAdmin?.Call("logout_admin", _currentAdminEmail);
        _currentAdminEmail = "";
        _refreshTimer.Stop();
        ShowLoginPanel();
        _passwordInput.Text = ""; // Clear sensitive data
    }

    private void OnServerControlPressed()
    {
        bool isServerRunning = (bool)_networkManager?.Call("is_server_running");
        
        if (isServerRunning)
        {
            // Stop server
            _networkManager?.Call("disconnect_from_server");
            _serverControlButton.Text = "Start Server";
            _serverControlButton.Modulate = Colors.Green;
        }
        else
        {
            // Start server
            bool startResult = (bool)_networkManager?.Call("start_server");
            if (startResult)
            {
                _serverControlButton.Text = "Stop Server";
                _serverControlButton.Modulate = Colors.Red;
            }
            else
            {
                ShowTemporaryMessage("Failed to start server!");
            }
        }
    }

    private void UpdateDashboardData()
    {
        if (string.IsNullOrEmpty(_currentAdminEmail))
            return;

        // Get dashboard data from GDScript ServerAdmin
        var dashboardData = _serverAdmin?.Call("get_admin_dashboard_data", _currentAdminEmail) as Godot.Collections.Dictionary;
        
        if (dashboardData?.ContainsKey("error") == true)
        {
            ShowLoginError(dashboardData["error"].AsString());
            ShowLoginPanel();
            return;
        }

        PopulateDashboard(dashboardData);
    }

    private void PopulateDashboard(Godot.Collections.Dictionary data)
    {
        if (data == null) return;

        var adminInfo = data.GetValueOrDefault("admin_info", new Godot.Collections.Dictionary()) as Godot.Collections.Dictionary;
        var serverInfo = data.GetValueOrDefault("server_info", new Godot.Collections.Dictionary()) as Godot.Collections.Dictionary;
        var currentState = data.GetValueOrDefault("current_state", new Godot.Collections.Dictionary()) as Godot.Collections.Dictionary;
        var systemResources = data.GetValueOrDefault("system_resources", new Godot.Collections.Dictionary()) as Godot.Collections.Dictionary;
        var networkStatus = data.GetValueOrDefault("network_status", new Godot.Collections.Dictionary()) as Godot.Collections.Dictionary;

        // Update admin info
        _adminInfoLabel.Text = $"Logged in as: {adminInfo?.GetValueOrDefault("logged_in_as", "Unknown")}";

        // Update server information
        bool serverRunning = networkStatus?.GetValueOrDefault("server_running", false).AsBool() ?? false;
        _serverStatusLabel.Text = $"Server Status: {(serverRunning ? "RUNNING" : "STOPPED")}";
        _serverStatusLabel.Modulate = serverRunning ? Colors.Green : Colors.Red;

        _versionLabel.Text = $"Version: {serverInfo?.GetValueOrDefault("version", "Unknown")}";
        _uptimeLabel.Text = $"Uptime: {serverInfo?.GetValueOrDefault("uptime_formatted", "Unknown")}";

        _activeGamesLabel.Text = $"Active Games: {currentState?.GetValueOrDefault("active_games", 0)}";
        _activePlayersLabel.Text = $"Active Players: {currentState?.GetValueOrDefault("active_players", 0)}";

        // Update system resources
        double memoryMb = systemResources?.GetValueOrDefault("memory_usage_mb", 0.0).AsDouble() ?? 0.0;
        _memoryLabel.Text = $"Memory Usage: {memoryMb:F1} MB";

        var port = networkStatus?.GetValueOrDefault("default_port", "Unknown");
        _networkLabel.Text = $"Network: Port {port}";

        _platformLabel.Text = $"Platform: {systemResources?.GetValueOrDefault("platform", "Unknown")}";

        // Update server control button
        if (serverRunning)
        {
            _serverControlButton.Text = "Stop Server";
            _serverControlButton.Modulate = Colors.Red;
        }
        else
        {
            _serverControlButton.Text = "Start Server";
            _serverControlButton.Modulate = Colors.Green;
        }

        // Update games list
        var gameDetails = currentState?.GetValueOrDefault("game_details", new Godot.Collections.Array()) as Godot.Collections.Array;
        UpdateGamesList(gameDetails);
    }

    private void UpdateGamesList(Godot.Collections.Array gameDetails)
    {
        // Clear existing entries
        foreach (Node child in _gamesList.GetChildren())
        {
            child.QueueFree();
        }

        if (gameDetails == null || gameDetails.Count == 0)
        {
            var noGamesLabel = new Label();
            noGamesLabel.Text = "No active games";
            noGamesLabel.HorizontalAlignment = HorizontalAlignment.Center;
            noGamesLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
            _gamesList.AddChild(noGamesLabel);
            return;
        }

        // Add game entries
        foreach (var gameData in gameDetails)
        {
            var gameDict = gameData as Godot.Collections.Dictionary;
            if (gameDict != null)
            {
                var gamePanel = CreateGamePanel(gameDict);
                _gamesList.AddChild(gamePanel);
            }
        }
    }

    private Panel CreateGamePanel(Godot.Collections.Dictionary gameData)
    {
        var panel = new Panel();
        panel.CustomMinimumSize = new Vector2(0, 80);

        var style = new StyleBoxFlat();
        style.BgColor = new Color(0.2f, 0.25f, 0.3f, 0.8f);
        style.BorderColor = new Color(0.4f, 0.5f, 0.6f, 1.0f);
        style.BorderWidthLeft = style.BorderWidthRight = style.BorderWidthTop = style.BorderWidthBottom = 2;
        style.CornerRadiusTopLeft = style.CornerRadiusTopRight = style.CornerRadiusBottomLeft = style.CornerRadiusBottomRight = 5;
        panel.AddThemeStyleboxOverride("panel", style);

        var vbox = new VBoxContainer();
        vbox.SetAnchorsAndOffsetsPreset(Control.PresetFullRect);
        vbox.OffsetLeft = vbox.OffsetTop = 8;
        vbox.OffsetRight = vbox.OffsetBottom = -8;
        vbox.AddThemeConstantOverride("separation", 2);
        panel.AddChild(vbox);

        // Game code and status
        var gameCode = gameData.GetValueOrDefault("code", "Unknown").AsString();
        bool isStarted = gameData.GetValueOrDefault("started", false).AsBool();
        string statusText = isStarted ? "STARTED" : "WAITING";

        var titleLabel = new Label();
        titleLabel.Text = $"Game: {gameCode} ({statusText})";
        titleLabel.AddThemeFontSizeOverride("font_size", 14);
        titleLabel.Modulate = isStarted ? Colors.Green : Colors.Yellow;
        vbox.AddChild(titleLabel);

        // Host and players
        var playerCount = gameData.GetValueOrDefault("players", 0).AsInt32();
        var hostName = gameData.GetValueOrDefault("host", "Unknown").AsString();

        var infoLabel = new Label();
        infoLabel.Text = $"Host: {hostName} | Players: {playerCount}";
        vbox.AddChild(infoLabel);

        // Time since creation
        var createdAgo = gameData.GetValueOrDefault("created_ago", 0.0).AsDouble();
        var timeLabel = new Label();
        timeLabel.Text = $"Created: {FormatUptime(createdAgo)} ago";
        timeLabel.AddThemeFontSizeOverride("font_size", 10);
        timeLabel.Modulate = new Color(0.7f, 0.7f, 0.7f, 1.0f);
        vbox.AddChild(timeLabel);

        return panel;
    }

    private string FormatUptime(double seconds)
    {
        int totalSeconds = (int)seconds;
        int days = totalSeconds / 86400;
        int hours = (totalSeconds % 86400) / 3600;
        int minutes = (totalSeconds % 3600) / 60;
        int secs = totalSeconds % 60;

        if (days > 0)
            return $"{days}d {hours}h {minutes}m {secs}s";
        else if (hours > 0)
            return $"{hours}h {minutes}m {secs}s";
        else if (minutes > 0)
            return $"{minutes}m {secs}s";
        else
            return $"{secs}s";
    }

    private async void ShowTemporaryMessage(string message)
    {
        var tempLabel = new Label();
        tempLabel.Text = message;
        tempLabel.Modulate = Colors.Orange;
        tempLabel.Position = new Vector2(20, 50);
        AddChild(tempLabel);

        await ToSignal(GetTree().CreateTimer(3.0), SceneTreeTimer.SignalName.Timeout);
        
        if (tempLabel != null && IsInsideTree())
        {
            tempLabel.QueueFree();
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey keyEvent && keyEvent.Pressed)
        {
            switch (keyEvent.Keycode)
            {
                case Key.F5:
                    if (_dashboardPanel.Visible)
                        OnRefreshPressed();
                    break;
                case Key.Escape:
                    if (_dashboardPanel.Visible)
                        OnLogoutPressed();
                    break;
            }
        }
    }
}
