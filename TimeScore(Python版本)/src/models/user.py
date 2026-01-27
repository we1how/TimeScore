#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
用户数据模型

定义用户状态和数据的数据结构和相关方法
对应iOS的User struct
"""

from typing import Optional, List, Dict, Any
from datetime import datetime
from .behavior import Behavior

class User:
    """用户数据模型
    
    对应iOS的User struct
    
    Attributes:
        id: 用户ID
        current_energy: 当前精力值
        combo_count: 连击次数
        today_total_score: 今日总积分
        today_behavior_count: 今日行为数量
        last_record_ts: 上次记录时间戳
        efficient_periods: 高效时段列表
        total_score: 总积分
        recent_behaviors: 最近行为列表
        beginner_period: 是否处于新手期
        is_first_behavior_today: 是否是今日第一个行为
    """
    
    def __init__(self, 
                 id: int = 1,
                 current_energy: float = 100.0,
                 combo_count: int = 0,
                 today_total_score: float = 0.0,
                 today_behavior_count: int = 0,
                 last_record_ts: Optional[int] = None,
                 efficient_periods: Optional[List[str]] = None,
                 total_score: float = 0.0,
                 recent_behaviors: Optional[List[Behavior]] = None,
                 beginner_period: bool = True,
                 is_first_behavior_today: bool = True):
        """初始化用户对象
        
        对应iOS的User.init()
        
        Args:
            id: 用户ID
            current_energy: 当前精力值
            combo_count: 连击次数
            today_total_score: 今日总积分
            today_behavior_count: 今日行为数量
            last_record_ts: 上次记录时间戳
            efficient_periods: 高效时段列表
            total_score: 总积分
            recent_behaviors: 最近行为列表
            beginner_period: 是否处于新手期
            is_first_behavior_today: 是否是今日第一个行为
        """
        self.id = id
        self.current_energy = current_energy
        self.combo_count = combo_count
        self.today_total_score = today_total_score
        self.today_behavior_count = today_behavior_count
        self.last_record_ts = last_record_ts
        self.efficient_periods = efficient_periods or []
        self.total_score = total_score
        self.recent_behaviors = recent_behaviors or []
        self.beginner_period = beginner_period
        self.is_first_behavior_today = is_first_behavior_today
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式
        
        对应iOS的User.toDictionary()
        
        Returns:
            用户数据字典
        """
        return {
            "id": self.id,
            "current_energy": self.current_energy,
            "combo_count": self.combo_count,
            "today_total_score": self.today_total_score,
            "today_behavior_count": self.today_behavior_count,
            "last_record_ts": self.last_record_ts,
            "efficient_periods": self.efficient_periods,
            "total_score": self.total_score,
            "recent_behaviors": [behavior.to_dict() for behavior in self.recent_behaviors],
            "beginner_period": self.beginner_period,
            "is_first_behavior_today": self.is_first_behavior_today
        }
    
    def to_db_dict(self) -> Dict[str, Any]:
        """转换为数据库存储格式
        
        对应iOS的User.toCoreDataFormat()
        
        Returns:
            适合数据库存储的用户数据字典
        """
        import json
        
        return {
            "id": self.id,
            "current_energy": self.current_energy,
            "combo_count": self.combo_count,
            "today_total_score": self.today_total_score,
            "today_behavior_count": self.today_behavior_count,
            "last_record_ts": self.last_record_ts,
            "efficient_periods": json.dumps(self.efficient_periods)
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "User":
        """从字典创建User对象
        
        对应iOS的User.fromDictionary()
        
        Args:
            data: 用户数据字典
            
        Returns:
            User对象
        """
        recent_behaviors = []
        for behavior_data in data.get("recent_behaviors", []):
            recent_behaviors.append(Behavior.from_dict(behavior_data))
        
        return cls(
            id=data.get("id", 1),
            current_energy=data.get("current_energy", 100.0),
            combo_count=data.get("combo_count", 0),
            today_total_score=data.get("today_total_score", 0.0),
            today_behavior_count=data.get("today_behavior_count", 0),
            last_record_ts=data.get("last_record_ts"),
            efficient_periods=data.get("efficient_periods"),
            total_score=data.get("total_score", 0.0),
            recent_behaviors=recent_behaviors,
            beginner_period=data.get("beginner_period", True),
            is_first_behavior_today=data.get("is_first_behavior_today", True)
        )
    
    @classmethod
    def from_db_row(cls, row: Dict[str, Any]) -> "User":
        """从数据库行创建User对象
        
        对应iOS的User.fromCoreData()
        
        Args:
            row: 数据库查询结果行
            
        Returns:
            User对象
        """
        import json
        
        efficient_periods = []
        if row.get("efficient_periods"):
            try:
                efficient_periods = json.loads(row["efficient_periods"])
            except json.JSONDecodeError:
                efficient_periods = []
        
        return cls(
            id=row["id"],
            current_energy=row["current_energy"],
            combo_count=row["combo_count"],
            today_total_score=row["today_total_score"],
            today_behavior_count=row["today_behavior_count"],
            last_record_ts=row["last_record_ts"],
            efficient_periods=efficient_periods
        )
