#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
积分计算系统

负责计算行为得分和管理积分
对应iOS的ScoringViewModel
"""

from typing import Dict, Any, Optional, Tuple
from datetime import datetime
from src.models.behavior import Behavior
from src.utils.config import get_config

class ScoringCalculator:
    """积分计算类
    
    对应iOS的ScoringViewModel
    
    负责计算行为得分，基于等级基础分、时长、动态系数（精力、连击等）
    """
    
    def __init__(self, user_data: Dict[str, Any]):
        """初始化积分计算器
        
        对应iOS的ScoringViewModel.init()
        
        Args:
            user_data: 用户数据，包含最近行为、精力等
        """
        self.user_data = user_data
        self.level_config = get_config("level_config")
        self.global_config = get_config("global_config")
    
    def calculate_score(self, behavior: Behavior) -> float:
        """计算单次行为得分
        
        对应iOS的ScoringViewModel.calculateScore()
        
        Args:
            behavior: 行为对象
            
        Returns:
            最终得分
        """
        # 检查精力为0时不得分
        if self.user_data["current_energy"] <= self.global_config["energy_zero_threshold"]:
            return 0.0
        
        # 获取等级配置
        behavior_info = self.get_behavior_info(behavior.level, behavior.duration, behavior.mood)
        
        # 计算基础分
        base_score = behavior_info["base_score_per_min"] * behavior.duration
        
        # 计算动态系数
        energy_coeff = self._calculate_energy_coefficient()
        combo_coeff = self._calculate_combo_coefficient(behavior.level)
        dynamic_coeff = energy_coeff * combo_coeff
        
        # 开始奖励：前5分钟得分×1.2
        start_bonus_score = 1.0
        if behavior.duration <= self.global_config["start_bonus_duration"]:
            start_bonus_score = self.global_config["start_bonus_score"]
        
        # 新手奖励：首周所有系数×1.2
        novice_bonus = 1.0
        if self.user_data["beginner_period"]:
            novice_bonus = self.global_config["novice_bonus"]
        
        # 计算最终得分
        final_score = base_score * dynamic_coeff * start_bonus_score * novice_bonus
        
        return final_score
    
    def calculate_energy_cost(self, behavior: Behavior) -> Tuple[float, bool]:
        """计算精力消耗/恢复
        
        对应iOS的ScoringViewModel.calculateEnergyCost()
        
        Args:
            behavior: 行为对象
            
        Returns:
            精力变化值，是否为恢复行为
        """
        # 获取行为信息
        behavior_info = self.get_behavior_info(behavior.level, behavior.duration, behavior.mood)
        
        # 开始奖励：前5分钟精力消耗×0.8
        start_bonus_energy = 1.0
        if behavior.duration <= self.global_config["start_bonus_duration"]:
            start_bonus_energy = self.global_config["start_bonus_energy"]
        
        energy_cost_per_min = behavior_info["energy_cost_per_min"]
        
        # 计算基础精力变化
        final_energy_cost = energy_cost_per_min * behavior.duration * start_bonus_energy
        
        # 低精力时恢复行为加成
        if self.user_data["current_energy"] < self.global_config["energy_low_threshold"] and energy_cost_per_min < 0:
            final_energy_cost *= self.global_config["low_energy_recovery_bonus"]
        
        is_recovery = energy_cost_per_min < 0
        
        return final_energy_cost, is_recovery
    
    def get_behavior_info(self, level: str, duration: int, mood: int) -> Dict[str, Any]:
        """获取行为信息，处理R级子级推测
        
        对应iOS的ScoringViewModel.getBehaviorInfo()
        
        Args:
            level: 行为等级
            duration: 持续时长
            mood: 心情评分
            
        Returns:
            行为信息字典
        """
        if level.startswith("R"):
            # 处理R级行为
            r_level = self._infer_r_sublevel(level, duration, mood)
            # 获取R级配置
            r_config = self.level_config["R"]
            # 获取子级配置
            sublevel_config = r_config["sublevels"][r_level]
            
            return {
                "name": level,
                "level": level,
                "category": "恢复行为",
                "base_score_per_min": sublevel_config["base_score_per_min"],
                "energy_cost_per_min": sublevel_config["energy_cost_per_min"],
                "mental_anchor": sublevel_config["mental_anchor"],
                "example": sublevel_config["example"],
                "inferred_sublevel": r_level
            }
        else:
            # 普通行为，直接返回
            return self.level_config[level]
    
    def _infer_r_sublevel(self, level: str, duration: int, mood: int) -> str:
        """推测R级的子级（R1/R2/R3）
        
        对应iOS的ScoringViewModel.inferRSublevel()
        
        Args:
            level: 行为等级
            duration: 持续时长
            mood: 心情评分
            
        Returns:
            推测的子级
        """
        # 如果用户已经指定了子级（如R1），直接返回
        if len(level) > 1:
            return level
        
        # 基于心情推测
        if mood <= 2:
            inferred_sublevel = "R1"
        elif mood == 3:
            inferred_sublevel = "R2"
        else:  # 4-5星
            inferred_sublevel = "R3"
        
        # 基于时长调整
        if duration < 15:
            inferred_sublevel = "R1"
        elif 15 <= duration <= 30:
            inferred_sublevel = "R2"
        else:  # >30分钟
            inferred_sublevel = "R3"
        
        # 基于上下文（前一个行为）
        if self.user_data["recent_behaviors"]:
            last_behavior = self.user_data["recent_behaviors"][-1]
            if last_behavior.level in ["S", "A"]:
                # 前行为是高消耗，提升恢复子级
                if inferred_sublevel == "R1":
                    inferred_sublevel = "R2"
                elif inferred_sublevel == "R2":
                    inferred_sublevel = "R3"
        
        return inferred_sublevel
    
    def _calculate_energy_coefficient(self) -> float:
        """计算精力系数
        
        对应iOS的ScoringViewModel.calculateEnergyCoefficient()
        
        Returns:
            精力系数
        """
        current_energy = self.user_data["current_energy"]
        if current_energy > 70:
            return 1.0 + (current_energy - 70) * 0.01
        elif current_energy > 40:
            return 0.85 + (current_energy - 40) * 0.005
        else:
            return 0.7
    
    def _calculate_combo_coefficient(self, level: str) -> float:
        """计算连击系数
        
        对应iOS的ScoringViewModel.calculateComboCoefficient()
        
        Args:
            level: 行为等级
            
        Returns:
            连击系数
        """
        combo_result = self._calculate_combo_result(level)
        return combo_result["coefficient"]
    
    def _calculate_combo_result(self, level: str) -> Dict[str, Any]:
        """计算连击结果
        
        对应iOS的ScoringViewModel.calculateComboResult()
        
        Args:
            level: 行为等级
            
        Returns:
            连击结果字典
        """
        # 检查当前行为是否为正向行为（S/A/B）
        is_positive = level in ["S", "A", "B"]
        
        # 获取最近的正向行为
        positive_recent = [b for b in self.user_data["recent_behaviors"] if b.level in ["S", "A", "B"]]
        
        combo_count = len(positive_recent)
        
        # 计算连击系数
        if combo_count == 0:
            combo_coeff = 1.0
        elif combo_count == 1:
            combo_coeff = 1.1
        elif combo_count == 2:
            combo_coeff = 1.2
        else:
            combo_coeff = self.global_config["max_combo_bonus"]  # 上限1.3
        
        # 检查是否是中断后的第一个正面行为
        is_negative_break = len(self.user_data["recent_behaviors"]) > 0 and self.user_data["recent_behaviors"][-1].level in ["C", "D"]
        if is_positive and is_negative_break:
            combo_coeff *= self.global_config["rebound_bonus"]
        
        # 检查是否是同领域专精
        # 简化处理：假设相同等级为同领域
        is_same_field = len(positive_recent) > 0 and all(b.level == level for b in positive_recent)
        if is_same_field and combo_count >= 1:
            combo_coeff *= 1.15
        
        return {
            "coefficient": combo_coeff,
            "combo_count": combo_count,
            "is_same_field": is_same_field,
            "is_negative_break": is_negative_break
        }
    
    def apply_balance_mechanisms(self, final_score: float, same_behavior_count: int, is_short_frequency: bool, level: str) -> float:
        """应用防滥用与平衡机制
        
        对应iOS的ScoringViewModel.applyBalanceMechanisms()
        
        Args:
            final_score: 最终得分
            same_behavior_count: 同一行为重复次数
            is_short_frequency: 是否为短时长高频
            level: 行为等级
            
        Returns:
            应用平衡机制后的得分
        """
        adjusted_score = final_score
        
        # 同一行为重复第4次起收益递减20%
        if same_behavior_count >= 3:
            adjusted_score *= 0.8
        
        # 短时长高频（10分钟内重复）第二次起系数×0.7
        if is_short_frequency:
            adjusted_score *= 0.7
        
        # 防刷R机制：连续R级>2次，恢复率降低
        if level.startswith("R"):
            r_count = sum(1 for b in self.user_data["recent_behaviors"] if b.level.startswith("R"))
            if r_count >= 2:
                adjusted_score *= 0.8
        
        return adjusted_score
