#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精力管理系统

负责管理用户精力变化、自动恢复和跨天重置
对应iOS的EnergyViewModel
"""

from typing import Dict, Any
from datetime import datetime, timedelta
from src.utils.config import get_config

class EnergyManager:
    """精力管理类
    
    对应iOS的EnergyViewModel
    
    负责管理精力变化、自动恢复和跨天重置
    """
    
    def __init__(self, user_data: Dict[str, Any]):
        """初始化精力管理器
        
        对应iOS的EnergyViewModel.init()
        
        Args:
            user_data: 用户数据，包含当前精力、上次记录时间等
        """
        self.user_data = user_data
        self.global_config = get_config("global_config")
    
    def update_energy(self, energy_cost: float) -> float:
        """更新精力，应用精力上限
        
        对应iOS的EnergyViewModel.updateEnergy()
        
        Args:
            energy_cost: 精力消耗/恢复值
            
        Returns:
            更新后的精力值
        """
        # 计算新精力值（恢复行为的energy_cost是负数）
        new_energy = self.user_data["current_energy"] - energy_cost
        
        # 应用精力上限
        new_energy = min(new_energy, self.global_config["energy_max"])
        
        # 确保精力不低于0
        new_energy = max(0.0, new_energy)
        
        # 更新用户数据
        self.user_data["current_energy"] = new_energy
        
        return new_energy
    
    def calculate_auto_recovery(self) -> float:
        """计算自动恢复的精力
        
        对应iOS的EnergyViewModel.calculateAutoRecovery()
        
        Returns:
            恢复的精力值
        """
        if not self.user_data["last_record_ts"]:
            return 0.0
        
        # 计算时间差（分钟）
        now = datetime.now().timestamp()
        time_diff = (now - self.user_data["last_record_ts"]) / 60
        
        # 超过30分钟才恢复
        if time_diff <= 30:
            return 0.0
        
        # 计算恢复的精力
        # 被动恢复率：每分钟恢复0.02点
        recovery = time_diff * self.global_config["passive_recovery_rate"]
        
        return recovery
    
    def apply_auto_recovery(self) -> float:
        """应用自动恢复的精力
        
        对应iOS的EnergyViewModel.applyAutoRecovery()
        
        Returns:
            更新后的精力值
        """
        recovery = self.calculate_auto_recovery()
        if recovery > 0:
            return self.update_energy(-recovery)  # 恢复是负数消耗
        return self.user_data["current_energy"]
    
    def reset_daily_energy(self) -> float:
        """重置每日精力
        
        对应iOS的EnergyViewModel.resetDailyEnergy()
        
        Returns:
            重置后的精力值
        """
        # 前日剩余精力
        previous_energy = self.user_data["current_energy"]
        
        # 睡眠恢复：默认8小时×7点=56点
        sleep_recovery = 56
        
        # 计算新一天的初始精力
        new_day_energy = previous_energy + sleep_recovery
        
        # 若无睡眠数据，默认+50点
        if not self.user_data["last_record_ts"]:
            new_day_energy = previous_energy + self.global_config["cross_day_recovery_default"]
        
        # 应用精力上限
        new_day_energy = min(new_day_energy, self.global_config["energy_max"])
        
        # 更新用户数据
        self.user_data["current_energy"] = new_day_energy
        
        return new_day_energy
    
    def is_low_energy(self) -> bool:
        """检查是否低精力
        
        对应iOS的EnergyViewModel.isLowEnergy()
        
        Returns:
            是否低精力
        """
        return self.user_data["current_energy"] < self.global_config["energy_low_threshold"]
    
    def get_energy_status(self) -> str:
        """获取精力状态描述
        
        对应iOS的EnergyViewModel.getEnergyStatus()
        
        Returns:
            精力状态描述
        """
        current_energy = self.user_data["current_energy"]
        
        if current_energy > 90:
            return "精力充沛"
        elif current_energy > 70:
            return "精力良好"
        elif current_energy > 50:
            return "精力一般"
        elif current_energy > 30:
            return "精力不足"
        else:
            return "精力枯竭"
