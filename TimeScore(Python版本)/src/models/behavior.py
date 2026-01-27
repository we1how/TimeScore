#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
行为数据模型

定义行为记录的数据结构和相关方法
对应iOS的Behavior struct
"""

from typing import Optional, Dict, Any
from datetime import datetime

class Behavior:
    """行为数据模型
    
    对应iOS的Behavior struct
    
    Attributes:
        id: 行为ID
        level: 行为等级（S/A/B/C/D/R）
        duration: 持续时长（分钟）
        mood: 心情评分（1-5）
        start_time: 开始时间
        end_time: 结束时间
        base_score: 基础分
        dynamic_coeff: 动态系数
        final_score: 最终得分
        energy_consume: 精力消耗/恢复
        name: 行为名称（可选）
        specific_time: 具体时段（可选）
        feeling: 当时感受（可选）
        create_time: 创建时间
    """
    
    def __init__(self, 
                 level: str, 
                 duration: int, 
                 mood: int, 
                 start_time: datetime, 
                 end_time: datetime, 
                 base_score: float, 
                 dynamic_coeff: float, 
                 final_score: float, 
                 energy_consume: float, 
                 id: Optional[int] = None, 
                 name: Optional[str] = None, 
                 specific_time: Optional[str] = None, 
                 feeling: Optional[str] = None, 
                 create_time: Optional[datetime] = None):
        """初始化行为对象
        
        对应iOS的Behavior.init()
        
        Args:
            level: 行为等级（S/A/B/C/D/R）
            duration: 持续时长（分钟）
            mood: 心情评分（1-5）
            start_time: 开始时间
            end_time: 结束时间
            base_score: 基础分
            dynamic_coeff: 动态系数
            final_score: 最终得分
            energy_consume: 精力消耗/恢复
            id: 行为ID（可选）
            name: 行为名称（可选）
            specific_time: 具体时段（可选）
            feeling: 当时感受（可选）
            create_time: 创建时间（可选）
        """
        self.id = id
        self.level = level
        self.duration = duration
        self.mood = mood
        self.start_time = start_time
        self.end_time = end_time
        self.base_score = base_score
        self.dynamic_coeff = dynamic_coeff
        self.final_score = final_score
        self.energy_consume = energy_consume
        self.name = name
        self.specific_time = specific_time
        self.feeling = feeling
        self.create_time = create_time or datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式
        
        对应iOS的Behavior.toDictionary()
        
        Returns:
            行为数据字典
        """
        return {
            "id": self.id,
            "level": self.level,
            "duration": self.duration,
            "mood": self.mood,
            "start_time": self.start_time.strftime("%Y-%m-%d %H:%M:%S"),
            "end_time": self.end_time.strftime("%Y-%m-%d %H:%M:%S"),
            "base_score": self.base_score,
            "dynamic_coeff": self.dynamic_coeff,
            "final_score": self.final_score,
            "energy_consume": self.energy_consume,
            "name": self.name,
            "specific_time": self.specific_time,
            "feeling": self.feeling,
            "create_time": self.create_time.strftime("%Y-%m-%d %H:%M:%S") if self.create_time else None
        }
    
    def to_db_dict(self) -> Dict[str, Any]:
        """转换为数据库存储格式
        
        对应iOS的Behavior.toCoreDataFormat()
        
        Returns:
            适合数据库存储的行为数据字典
        """
        return {
            "level": self.level,
            "duration": self.duration,
            "mood": self.mood,
            "start_ts": int(self.start_time.timestamp()),
            "end_ts": int(self.end_time.timestamp()),
            "base_score": self.base_score,
            "dynamic_coeff": self.dynamic_coeff,
            "final_score": self.final_score,
            "energy_consume": self.energy_consume
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Behavior":
        """从字典创建Behavior对象
        
        对应iOS的Behavior.fromDictionary()
        
        Args:
            data: 行为数据字典
            
        Returns:
            Behavior对象
        """
        return cls(
            id=data.get("id"),
            level=data["level"],
            duration=data["duration"],
            mood=data["mood"],
            start_time=datetime.strptime(data["start_time"], "%Y-%m-%d %H:%M:%S"),
            end_time=datetime.strptime(data["end_time"], "%Y-%m-%d %H:%M:%S"),
            base_score=data["base_score"],
            dynamic_coeff=data["dynamic_coeff"],
            final_score=data["final_score"],
            energy_consume=data["energy_consume"],
            name=data.get("name"),
            specific_time=data.get("specific_time"),
            feeling=data.get("feeling"),
            create_time=datetime.strptime(data["create_time"], "%Y-%m-%d %H:%M:%S") if data.get("create_time") else None
        )
    
    @classmethod
    def from_db_row(cls, row: Dict[str, Any]) -> "Behavior":
        """从数据库行创建Behavior对象
        
        对应iOS的Behavior.fromCoreData()
        
        Args:
            row: 数据库查询结果行
            
        Returns:
            Behavior对象
        """
        return cls(
            id=row["id"],
            level=row["level"],
            duration=row["duration"],
            mood=row["mood"],
            start_time=datetime.fromtimestamp(row["start_ts"]),
            end_time=datetime.fromtimestamp(row["end_ts"]),
            base_score=row["base_score"],
            dynamic_coeff=row["dynamic_coeff"],
            final_score=row["final_score"],
            energy_consume=row["energy_consume"],
            create_time=datetime.fromtimestamp(row["create_ts"])
        )
