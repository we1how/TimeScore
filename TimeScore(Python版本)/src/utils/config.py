#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
配置管理模块

负责加载和管理应用程序的配置
对应iOS的ConfigManager
"""

import json
from typing import Dict, Any, Optional

# 默认配置
DEFAULT_CONFIG = {
    "level_config": {
        "S": {
            "base_score_per_min": 1.8,
            "energy_cost_per_min": 0.35,
            "mental_anchor": "突破性成长",
            "example": "深度工作、攻克难题、高强度训练"
        },
        "A": {
            "base_score_per_min": 1.2,
            "energy_cost_per_min": 0.25,
            "mental_anchor": "有效进步",
            "example": "学习新知识、创造性工作、专注阅读"
        },
        "B": {
            "base_score_per_min": 0.7,
            "energy_cost_per_min": 0.18,
            "mental_anchor": "稳定维持",
            "example": "复习、整理、轻度运动、家务"
        },
        "C": {
            "base_score_per_min": -0.5,
            "energy_cost_per_min": 0.10,
            "mental_anchor": "时间流逝",
            "example": "无目的刷手机、看无聊视频"
        },
        "D": {
            "base_score_per_min": -1.0,
            "energy_cost_per_min": 0.15,
            "mental_anchor": "自我损害",
            "example": "熬夜、暴食、过度放纵"
        },
        "R": {
            "base_score_per_min": 0,
            "energy_cost_per_min": 0,
            "mental_anchor": "恢复行为",
            "example": "散步、冥想、午睡",
            "sublevels": {
                "R1": {
                    "base_score_per_min": 0.2,
                    "energy_cost_per_min": -0.10,
                    "mental_anchor": "轻度放松",
                    "example": "喝茶、听音乐、短暂休息"
                },
                "R2": {
                    "base_score_per_min": 0.3,
                    "energy_cost_per_min": -0.20,
                    "mental_anchor": "中等恢复",
                    "example": "散步、瑜伽、阅读休闲书"
                },
                "R3": {
                    "base_score_per_min": 0.4,
                    "energy_cost_per_min": -0.30,
                    "mental_anchor": "深度恢复",
                    "example": "午睡、冥想、正念练习"
                }
            }
        }
    },
    "mood_config": {
        1: {
            "coefficient": 0.7,
            "description": "显著降低",
            "text": "承认今天的艰难"
        },
        2: {
            "coefficient": 0.85,
            "description": "适度降低",
            "text": "不太理想但可接受"
        },
        3: {
            "coefficient": 1.0,
            "description": "无影响",
            "text": "标准状态"
        },
        4: {
            "coefficient": 1.2,
            "description": "适度提升",
            "text": "状态不错"
        },
        5: {
            "coefficient": 1.4,
            "description": "显著提升",
            "text": "巅峰体验"
        }
    },
    "global_config": {
        "per_time": 1,
        "energy_max": 120,  # 精力上限
        "energy_low_threshold": 30,  # 低精力阈值
        "energy_zero_threshold": 0,  # 精力为0时不得分
        "low_energy_positive_coeff": 0.9,  # 低精力时正面行为系数上限
        "low_energy_recovery_bonus": 1.2,  # 低精力时恢复行为加成
        "passive_recovery_rate": 0.02,  # 行为间隔>30分钟时的恢复率
        "no_behavior_recovery_rate": 1.5,  # 无行为时每小时恢复率
        "cross_day_recovery_default": 50,  # 跨天默认恢复值
        "b_level_recovery_percent": 0.3,  # B级行为后恢复其消耗的百分比
        "max_combo_bonus": 1.3,  # 最大连击奖励
        "rebound_bonus": 1.1,  # 反弹奖励
        "start_bonus_duration": 5,  # 开始奖励时长
        "start_bonus_score": 1.2,  # 开始奖励得分系数
        "start_bonus_energy": 0.8,  # 开始奖励精力系数
        "beginner_period_days": 7,  # 新手期天数
        "novice_bonus": 1.2,  # 新手奖励系数
        "enable_time_period_coeff": False,  # 是否启用时段系数
        "enable_lucky_coeff": False,  # 是否启用幸运系数
        "enable_mood_coeff": False  # 是否启用心情系数
    },
    "time_period_config": {
        "golden": {
            "time_ranges": [[9, 11], [15, 17]],
            "coefficient": 1.3,
            "description": "认知高峰期"
        },
        "silver": {
            "time_ranges": [[8, 9], [14, 15], [19, 21]],
            "coefficient": 1.1,
            "description": "次佳工作期"
        },
        "standard": {
            "time_ranges": [],
            "coefficient": 1.0,
            "description": "正常效率"
        },
        "fatigue": {
            "time_ranges": [[13, 14], [22, 24]],
            "coefficient": 0.8,
            "description": "生理低谷"
        },
        "rest": {
            "time_ranges": [[0, 6]],
            "coefficient": 0.5,
            "description": "应睡眠时间"
        }
    }
}

# 配置缓存
_config_cache: Optional[Dict[str, Any]] = None

def load_config(config_path: str = "config.json") -> Dict[str, Any]:
    """加载配置文件
    
    对应iOS的ConfigManager.loadConfig()
    
    Args:
        config_path: 配置文件路径
        
    Returns:
        配置字典
    """
    global _config_cache
    
    if _config_cache is not None:
        return _config_cache
    
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except FileNotFoundError:
        # 配置文件不存在，使用默认配置
        config = DEFAULT_CONFIG
    except json.JSONDecodeError:
        # 配置文件格式错误，使用默认配置
        config = DEFAULT_CONFIG
    
    # 合并默认配置和加载的配置
    merged_config = DEFAULT_CONFIG.copy()
    merged_config.update(config)
    
    _config_cache = merged_config
    return merged_config

def get_config(key: str, default: Any = None) -> Any:
    """获取配置项
    
    对应iOS的ConfigManager.getConfig()
    
    Args:
        key: 配置键
        default: 默认值
        
    Returns:
        配置值
    """
    config = load_config()
    return config.get(key, default)

def save_config(config: Dict[str, Any], config_path: str = "config.json") -> bool:
    """保存配置到文件
    
    对应iOS的ConfigManager.saveConfig()
    
    Args:
        config: 配置字典
        config_path: 配置文件路径
        
    Returns:
        是否保存成功
    """
    try:
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
        return True
    except Exception:
        return False
