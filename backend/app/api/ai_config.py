"""
AI Configuration API endpoints
Allows runtime management of AI strategies and tactics
"""

from fastapi import APIRouter, HTTPException
from typing import Dict, List, Any, Optional
from pydantic import BaseModel
from app.core.ai_config import ai_config

router = APIRouter()

class TacticConfig(BaseModel):
    name: str
    weight: float
    priority: int

class StrategyConfig(BaseModel):
    name: str
    description: str
    tactics: List[TacticConfig]

class CustomStrategyRequest(BaseModel):
    strategy_name: str
    strategy: StrategyConfig

class LevelMappingRequest(BaseModel):
    level: int
    strategy_name: str

@router.get("/strategies")
async def list_strategies():
    """Get all available AI strategies"""
    strategies = {}
    for name, config in ai_config.strategies.items():
        strategies[name] = {
            "name": config.get("name", name),
            "description": config.get("description", ""),
            "tactics": config.get("tactics", []),
            "is_mapped": name in ai_config.level_mappings.values()
        }
    
    return {
        "strategies": strategies,
        "total": len(strategies)
    }

@router.get("/tactics")
async def list_tactics():
    """Get all available AI tactics"""
    return {
        "tactics": ai_config.tactics,
        "total": len(ai_config.tactics)
    }

@router.get("/levels")
async def get_level_mappings():
    """Get current level to strategy mappings"""
    mappings = {}
    for level, strategy_name in ai_config.level_mappings.items():
        strategy = ai_config.strategies.get(strategy_name, {})
        mappings[level] = {
            "strategy_name": strategy_name,
            "display_name": strategy.get("name", strategy_name),
            "description": strategy.get("description", "")
        }
    
    return {
        "mappings": mappings,
        "total": len(mappings)
    }

@router.post("/strategies")
async def create_custom_strategy(request: CustomStrategyRequest):
    """Create a new custom AI strategy"""
    try:
        # Validate that all referenced tactics exist
        for tactic in request.strategy.tactics:
            if tactic.name not in ai_config.tactics:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Tactic '{tactic.name}' not found. Available tactics: {list(ai_config.tactics.keys())}"
                )
        
        # Convert to the expected format
        strategy_config = {
            "name": request.strategy.name,
            "description": request.strategy.description,
            "tactics": [
                {
                    "name": tactic.name,
                    "weight": tactic.weight,
                    "priority": tactic.priority
                }
                for tactic in request.strategy.tactics
            ]
        }
        
        # Add to configuration
        ai_config.add_custom_strategy(request.strategy_name, strategy_config)
        
        return {
            "message": f"Strategy '{request.strategy_name}' created successfully",
            "strategy": strategy_config
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create strategy: {str(e)}")

@router.put("/levels/{level}")
async def set_level_mapping(level: int, request: LevelMappingRequest):
    """Map a level number to a strategy"""
    try:
        if request.strategy_name not in ai_config.strategies:
            available = list(ai_config.strategies.keys())
            raise HTTPException(
                status_code=400,
                detail=f"Strategy '{request.strategy_name}' not found. Available: {available}"
            )
        
        ai_config.set_level_mapping(level, request.strategy_name)
        
        return {
            "message": f"Level {level} mapped to strategy '{request.strategy_name}'",
            "level": level,
            "strategy": request.strategy_name
        }
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to set mapping: {str(e)}")

@router.delete("/strategies/{strategy_name}")
async def delete_strategy(strategy_name: str):
    """Delete a custom strategy"""
    if strategy_name not in ai_config.strategies:
        raise HTTPException(status_code=404, detail=f"Strategy '{strategy_name}' not found")
    
    # Check if strategy is currently mapped to a level
    mapped_levels = [level for level, mapped_strategy in ai_config.level_mappings.items() 
                    if mapped_strategy == strategy_name]
    
    if mapped_levels:
        raise HTTPException(
            status_code=400, 
            detail=f"Cannot delete strategy '{strategy_name}' - it is mapped to levels: {mapped_levels}"
        )
    
    # Remove from strategies
    del ai_config.strategies[strategy_name]
    
    return {
        "message": f"Strategy '{strategy_name}' deleted successfully"
    }

@router.post("/save")
async def save_configuration():
    """Save current AI configuration to file"""
    try:
        ai_config.save_config()
        return {"message": "AI configuration saved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save config: {str(e)}")

@router.post("/reload")
async def reload_configuration():
    """Reload AI configuration from file"""
    try:
        ai_config.load_config()
        return {
            "message": "AI configuration reloaded successfully",
            "tactics": len(ai_config.tactics),
            "strategies": len(ai_config.strategies),
            "level_mappings": len(ai_config.level_mappings)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to reload config: {str(e)}")

@router.get("/strategy/{strategy_name}")
async def get_strategy_details(strategy_name: str):
    """Get detailed information about a specific strategy"""
    if strategy_name not in ai_config.strategies:
        raise HTTPException(status_code=404, detail=f"Strategy '{strategy_name}' not found")
    
    strategy = ai_config.strategies[strategy_name]
    
    # Enrich with tactic details
    enriched_tactics = []
    for tactic_config in strategy.get("tactics", []):
        tactic_name = tactic_config["name"]
        tactic_info = ai_config.tactics.get(tactic_name, {})
        
        enriched_tactics.append({
            **tactic_config,
            "description": tactic_info.get("description", "No description available"),
            "default_weight": tactic_info.get("weight", 1.0)
        })
    
    return {
        "name": strategy.get("name", strategy_name),
        "description": strategy.get("description", ""),
        "tactics": enriched_tactics,
        "is_mapped": strategy_name in ai_config.level_mappings.values(),
        "mapped_levels": [level for level, mapped_strategy in ai_config.level_mappings.items() 
                         if mapped_strategy == strategy_name]
    }