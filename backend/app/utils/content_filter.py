"""
Content filtering utilities for username validation
"""
import re
import json
import os
from typing import List, Dict, Set
from pathlib import Path

class ContentFilter:
    def __init__(self):
        self._load_word_lists()
    
    def _load_word_lists(self):
        """Load inappropriate word lists from configuration files"""
        config_dir = Path(__file__).parent / "word_lists"
        
        # Load English inappropriate words
        english_file = config_dir / "english_blocked.json"
        if english_file.exists():
            with open(english_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.english_blocked = set(word.lower() for word in data.get("words", []))
        else:
            self.english_blocked = self._get_default_english_words()
        
        # Load Spanish inappropriate words
        spanish_file = config_dir / "spanish_blocked.json"
        if spanish_file.exists():
            with open(spanish_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.spanish_blocked = set(word.lower() for word in data.get("words", []))
        else:
            self.spanish_blocked = self._get_default_spanish_words()
        
        # Load inappropriate patterns
        patterns_file = config_dir / "patterns_blocked.json"
        if patterns_file.exists():
            with open(patterns_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.inappropriate_patterns = set(pattern.lower() for pattern in data.get("patterns", []))
        else:
            self.inappropriate_patterns = self._get_default_patterns()
    
    def _get_default_english_words(self) -> Set[str]:
        """Default English inappropriate words"""
        return {
            # Common profanity
            "damn", "hell", "crap", "suck", "stupid", "idiot", "moron", "dumb",
            # Stronger profanity (partial list for family-friendly filtering)
            "wtf", "omg", "jesus", "christ", "god", "lord",
            # Sexual/NSFW terms
            "sex", "sexy", "hot", "nude", "naked", "porn", "xxx", "adult",
            # Violence/aggression
            "kill", "murder", "die", "death", "blood", "gun", "weapon", "fight",
            "hate", "racist", "nazi", "terror", "bomb", "attack",
            # Drugs/alcohol
            "drug", "weed", "high", "drunk", "beer", "wine", "smoke", "tobacco",
            # Other inappropriate
            "noob", "loser", "fail", "trash", "garbage", "sucks", "worst"
        }
    
    def _get_default_spanish_words(self) -> Set[str]:
        """Default Spanish inappropriate words"""
        return {
            # Common Spanish profanity/inappropriate terms
            "tonto", "estupido", "idiota", "basura", "odio", "matar", "muerte",
            "sangre", "arma", "pelea", "racista", "terror", "bomba", "ataque",
            "droga", "borracho", "cerveza", "vino", "tabaco", "sexo", "desnudo",
            "pornografia", "adulto", "caliente", "sexy", "malo", "peor", "feo",
            "gordo", "flaco", "negro", "blanco", "amarillo", "rojo", "verde",
            # Slang and offensive terms
            "pendejo", "cabron", "pinche", "chingon", "joder", "mierda", "carajo"
        }
    
    def _get_default_patterns(self) -> Set[str]:
        """Default inappropriate patterns"""
        return {
            # Leetspeak variations
            "f*ck", "sh*t", "d*mn", "h*ll", "b*tch", "a**", "f4ck", "sh1t",
            # Numbers/symbols replacing letters
            "k1ll", "d34th", "h4te", "5ex", "dr0g", "n4zi", "b0mb",
            # Common gaming/toxic terms
            "pwn", "rekt", "noobz", "scrub", "tryhard", "camper", "hacker"
        }
    
    def contains_inappropriate_content(self, username: str) -> bool:
        """Check if username contains inappropriate content"""
        username_lower = username.lower()
        
        # Check against English blocked words
        for word in self.english_blocked:
            if word in username_lower:
                return True
        
        # Check against Spanish blocked words  
        for word in self.spanish_blocked:
            if word in username_lower:
                return True
        
        # Check for inappropriate patterns
        for pattern in self.inappropriate_patterns:
            if pattern in username_lower:
                return True
        
        return False
    
    def get_word_lists_info(self) -> Dict[str, int]:
        """Get information about loaded word lists"""
        return {
            "english_words": len(self.english_blocked),
            "spanish_words": len(self.spanish_blocked),
            "patterns": len(self.inappropriate_patterns),
            "total_blocked_items": len(self.english_blocked) + len(self.spanish_blocked) + len(self.inappropriate_patterns)
        }

# Global instance
content_filter = ContentFilter()