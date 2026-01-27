#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
心愿数据模型

定义心愿和积分兑换的数据结构和相关方法
对应iOS的Wish struct
"""

from typing import Optional, Dict, Any
from datetime import datetime

class Wish:
    """心愿数据模型
    
    对应iOS的Wish struct
    
    Attributes:
        id: 心愿ID
        user_id: 用户ID
        name: 心愿名称
        cost: 所需积分
        status: 状态（pending/redeemed/archived）
        progress: 进度（当前积分/成本）
        created_at: 创建时间
        redeemed_at: 兑换时间
    """
    
    def __init__(self, 
                 name: str,
                 cost: int,
                 user_id: int = 1,
                 id: Optional[int] = None,
                 status: str = "pending",
                 progress: float = 0.0,
                 created_at: Optional[datetime] = None,
                 redeemed_at: Optional[datetime] = None):
        """初始化心愿对象
        
        对应iOS的Wish.init()
        
        Args:
            name: 心愿名称
            cost: 所需积分
            user_id: 用户ID
            id: 心愿ID
            status: 状态（pending/redeemed/archived）
            progress: 进度（当前积分/成本）
            created_at: 创建时间
            redeemed_at: 兑换时间
        """
        self.id = id
        self.user_id = user_id
        self.name = name
        self.cost = cost
        self.status = status
        self.progress = progress
        self.created_at = created_at or datetime.now()
        self.redeemed_at = redeemed_at
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式
        
        对应iOS的Wish.toDictionary()
        
        Returns:
            心愿数据字典
        """
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "cost": self.cost,
            "status": self.status,
            "progress": self.progress,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
            "redeemed_at": self.redeemed_at.strftime("%Y-%m-%d %H:%M:%S") if self.redeemed_at else None
        }
    
    def to_db_dict(self) -> Dict[str, Any]:
        """转换为数据库存储格式
        
        对应iOS的Wish.toCoreDataFormat()
        
        Returns:
            适合数据库存储的心愿数据字典
        """
        return {
            "user_id": self.user_id,
            "name": self.name,
            "cost": self.cost,
            "status": self.status,
            "progress": self.progress,
            "created_at": int(self.created_at.timestamp()) if self.created_at else None,
            "redeemed_at": int(self.redeemed_at.timestamp()) if self.redeemed_at else None
        }
    
    def update_progress(self, current_score: float) -> None:
        """更新心愿进度
        
        对应iOS的Wish.updateProgress()
        
        Args:
            current_score: 当前积分
        """
        self.progress = min(1.0, current_score / self.cost)
    
    def can_redeem(self, current_score: float) -> bool:
        """检查是否可以兑换
        
        对应iOS的Wish.canRedeem()
        
        Args:
            current_score: 当前积分
            
        Returns:
            是否可以兑换
        """
        return current_score >= self.cost and self.status == "pending"
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Wish":
        """从字典创建Wish对象
        
        对应iOS的Wish.fromDictionary()
        
        Args:
            data: 心愿数据字典
            
        Returns:
            Wish对象
        """
        return cls(
            id=data.get("id"),
            user_id=data.get("user_id", 1),
            name=data["name"],
            cost=data["cost"],
            status=data.get("status", "pending"),
            progress=data.get("progress", 0.0),
            created_at=datetime.strptime(data["created_at"], "%Y-%m-%d %H:%M:%S") if data.get("created_at") else None,
            redeemed_at=datetime.strptime(data["redeemed_at"], "%Y-%m-%d %H:%M:%S") if data.get("redeemed_at") else None
        )
    
    @classmethod
    def from_db_row(cls, row: Dict[str, Any]) -> "Wish":
        """从数据库行创建Wish对象
        
        对应iOS的Wish.fromCoreData()
        
        Args:
            row: 数据库查询结果行
            
        Returns:
            Wish对象
        """
        return cls(
            id=row["id"],
            user_id=row["user_id"],
            name=row["name"],
            cost=row["cost"],
            status=row["status"],
            progress=row["progress"],
            created_at=datetime.fromtimestamp(row["created_at"]) if row["created_at"] else None,
            redeemed_at=datetime.fromtimestamp(row["redeemed_at"]) if row["redeemed_at"] else None
        )
