"""
AI Configuration System for Mexican Train
Allows loading and customizing AI strategies from JSON files
"""

import json
import os
from typing import Dict, List, Any, Optional
from pathlib import Path

class AIConfig:
    def __init__(self, config_file: str = None):
        """Initialize AI configuration system"""
        if config_file is None:
            # Default to ai_strategies.json in the app directory
            config_file = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'ai_strategies.json')
        
        self.config_file = config_file
        self.tactics = {}
        self.strategies = {}
        self.level_mappings = {}
        self.load_config()
    
    def load_config(self) -> None:
        """Load AI configuration from JSON file"""
        try:
            with open(self.config_file, 'r') as f:
                config = json.load(f)
            
            self.tactics = config.get('tactics', {})
            self.strategies = config.get('strategies', {})
            self.level_mappings = config.get('level_mappings', {})
            
            print(f"Loaded AI config: {len(self.tactics)} tactics, {len(self.strategies)} strategies")
            
        except FileNotFoundError:
            print(f"AI config file not found: {self.config_file}")
            self._load_default_config()
        except json.JSONDecodeError as e:
            print(f"Error parsing AI config file: {e}")
            self._load_default_config()
    
    def _load_default_config(self) -> None:
        """Load minimal default configuration if file loading fails"""
        self.tactics = {
            "random": {"description": "Random moves", "weight": 1.0}
        }
        self.strategies = {
            "sleepy_caboose": {
                "name": "Sleepy Caboose",
                "description": "Random moves",
                "tactics": [{"name": "random", "weight": 1.0, "priority": 1}]
            }
        }
        self.level_mappings = {"1": "sleepy_caboose"}
    
    def get_strategy(self, level: int) -> Optional[Dict]:
        """Get strategy configuration for a given level"""
        level_str = str(level)
        if level_str in self.level_mappings:
            strategy_name = self.level_mappings[level_str]
            return self.strategies.get(strategy_name)
        return None
    
    def get_strategy_by_name(self, name: str) -> Optional[Dict]:
        """Get strategy configuration by name"""
        return self.strategies.get(name)
    
    def get_tactic(self, name: str) -> Optional[Dict]:
        """Get tactic configuration by name"""
        return self.tactics.get(name)
    
    def list_strategies(self) -> List[str]:
        """Get list of available strategy names"""
        return list(self.strategies.keys())
    
    def list_tactics(self) -> List[str]:
        """Get list of available tactic names"""
        return list(self.tactics.keys())
    
    def save_config(self) -> None:
        """Save current configuration to file"""
        config = {
            "tactics": self.tactics,
            "strategies": self.strategies,
            "level_mappings": self.level_mappings
        }
        
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"Saved AI config to {self.config_file}")
    
    def add_custom_strategy(self, name: str, strategy_config: Dict) -> None:
        """Add a custom strategy to the configuration"""
        self.strategies[name] = strategy_config
        print(f"Added custom strategy: {name}")
    
    def set_level_mapping(self, level: int, strategy_name: str) -> None:
        """Map a level number to a strategy name"""
        if strategy_name in self.strategies:
            self.level_mappings[str(level)] = strategy_name
            print(f"Mapped level {level} to strategy '{strategy_name}'")
        else:
            raise ValueError(f"Strategy '{strategy_name}' not found")

# Global instance
ai_config = AIConfig()