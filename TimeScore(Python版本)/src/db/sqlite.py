#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SQLite数据库操作模块

负责管理数据库连接和执行SQL操作
对应iOS的CoreDataManager
"""

import sqlite3
from typing import Optional, List, Dict, Any
from contextlib import contextmanager
from datetime import datetime

# 数据库文件路径
DB_PATH = "time_manage.db"

class SQLiteDB:
    """SQLite数据库操作类
    
    对应iOS的CoreDataManager
    
    提供数据库连接管理和CRUD操作
    """
    
    def __init__(self, db_path: str = DB_PATH):
        """初始化数据库连接
        
        对应iOS的CoreDataManager.init()
        
        Args:
            db_path: 数据库文件路径
        """
        self.db_path = db_path
        self._create_tables()
    
    @contextmanager
    def get_connection(self):
        """获取数据库连接上下文管理器
        
        对应iOS的CoreDataManager.performBackgroundTask()
        
        Yields:
            sqlite3.Connection: 数据库连接
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # 使用Row对象，方便访问列名
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def _create_tables(self):
        """创建数据库表
        
        对应iOS的CoreDataManager.setupCoreData()
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            # 1. 行为记录表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS core_behavior (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    level TEXT NOT NULL,
                    duration INTEGER NOT NULL,
                    mood INTEGER DEFAULT 3,
                    start_ts INTEGER NOT NULL,
                    end_ts INTEGER NOT NULL,
                    base_score REAL,
                    dynamic_coeff REAL,
                    final_score REAL,
                    energy_consume REAL,
                    create_ts INTEGER DEFAULT (strftime('%s', 'now'))
                )
            ''')
            
            # 2. 用户状态表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_state (
                    id INTEGER PRIMARY KEY DEFAULT 1,
                    current_energy REAL DEFAULT 100,
                    combo_count INTEGER DEFAULT 0,
                    today_total_score REAL DEFAULT 0,
                    today_behavior_count INTEGER DEFAULT 0,
                    last_record_ts INTEGER,
                    efficient_periods TEXT
                )
            ''')
            
            # 3. 配置表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS system_config (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    key TEXT UNIQUE NOT NULL,
                    value TEXT NOT NULL
                )
            ''')
            
            # 4. 行为定义表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS behavior_def (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT UNIQUE NOT NULL,
                    level TEXT NOT NULL,
                    category TEXT DEFAULT '未分类',
                    base_score_per_min REAL NOT NULL,
                    energy_cost_per_min REAL NOT NULL,
                    create_ts INTEGER DEFAULT (strftime('%s', 'now'))
                )
            ''')
            
            # 5. 成就表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_achievement (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    type TEXT NOT NULL,
                    unlock_ts INTEGER,
                    count INTEGER DEFAULT 1
                )
            ''')
            
            # 6. 心愿表（V5.0积分兑换系统）
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS wishes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER DEFAULT 1,
                    name TEXT NOT NULL,
                    cost INTEGER NOT NULL,
                    status TEXT DEFAULT 'pending',
                    created_at INTEGER DEFAULT (strftime('%s', 'now')),
                    redeemed_at INTEGER,
                    progress REAL DEFAULT 0.0
                )
            ''')
            
            # 创建索引
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_behavior_ts ON core_behavior(start_ts)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_behavior_level ON core_behavior(level)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_wishes_user_id ON wishes(user_id)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_wishes_status ON wishes(status)')
    
    # ----------------- 行为记录相关 -----------------
    def add_behavior(self, behavior_data: Dict[str, Any]) -> int:
        """添加行为记录
        
        对应iOS的CoreDataManager.addBehavior()
        
        Args:
            behavior_data: 行为数据字典
            
        Returns:
            记录ID
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO core_behavior (
                    level, duration, mood, start_ts, end_ts, 
                    base_score, dynamic_coeff, final_score, energy_consume
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                behavior_data["level"],
                behavior_data["duration"],
                behavior_data["mood"],
                behavior_data["start_ts"],
                behavior_data["end_ts"],
                behavior_data["base_score"],
                behavior_data["dynamic_coeff"],
                behavior_data["final_score"],
                behavior_data["energy_consume"]
            ))
            return cursor.lastrowid
    
    def get_today_records(self) -> List[Dict[str, Any]]:
        """获取今日行为记录
        
        对应iOS的CoreDataManager.getTodayBehaviors()
        
        Returns:
            今日行为记录列表
        """
        today_start = int(datetime.now().replace(hour=0, minute=0, second=0, microsecond=0).timestamp())
        
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM core_behavior WHERE start_ts >= ? ORDER BY start_ts DESC
            ''', (today_start,))
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
    
    def get_all_records(self, limit: int = None) -> List[Dict[str, Any]]:
        """获取所有行为记录
        
        对应iOS的CoreDataManager.getAllBehaviors()
        
        Args:
            limit: 返回记录的数量限制
            
        Returns:
            行为记录列表
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            if limit:
                cursor.execute('''
                    SELECT * FROM core_behavior ORDER BY start_ts DESC LIMIT ?
                ''', (limit,))
            else:
                cursor.execute('''
                    SELECT * FROM core_behavior ORDER BY start_ts DESC
                ''')
            
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_total_score(self) -> float:
        """获取总得分
        
        对应iOS的CoreDataManager.getTotalScore()
        
        Returns:
            总得分
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT SUM(final_score) FROM core_behavior')
            result = cursor.fetchone()[0]
            return result or 0.0
    
    # ----------------- 用户状态相关 -----------------
    def get_user_state(self) -> Dict[str, Any]:
        """获取用户状态
        
        对应iOS的CoreDataManager.getUserState()
        
        Returns:
            用户状态字典
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM user_state WHERE id = 1')
            row = cursor.fetchone()
            
            if not row:
                # 初始化用户状态
                cursor.execute('INSERT INTO user_state DEFAULT VALUES')
                conn.commit()
                cursor.execute('SELECT * FROM user_state WHERE id = 1')
                row = cursor.fetchone()
            
            return dict(row)
    
    def update_user_state(self, **kwargs) -> bool:
        """更新用户状态
        
        对应iOS的CoreDataManager.updateUserState()
        
        Args:
            kwargs: 要更新的字段和值
            
        Returns:
            是否更新成功
        """
        if not kwargs:
            return True
        
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            # 构建更新语句
            set_clause = ', '.join([f"{key} = ?" for key in kwargs.keys()])
            values = list(kwargs.values())
            
            try:
                cursor.execute(f"UPDATE user_state SET {set_clause} WHERE id = 1", values)
                return cursor.rowcount > 0
            except Exception as e:
                print(f"更新用户状态失败: {e}")
                return False
    
    # ----------------- 心愿相关 -----------------
    def add_wish(self, wish_data: Dict[str, Any]) -> int:
        """添加心愿
        
        对应iOS的CoreDataManager.addWish()
        
        Args:
            wish_data: 心愿数据字典
            
        Returns:
            心愿ID
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO wishes (user_id, name, cost, status, progress, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                wish_data["user_id"],
                wish_data["name"],
                wish_data["cost"],
                wish_data["status"],
                wish_data["progress"],
                wish_data["created_at"]
            ))
            return cursor.lastrowid
    
    def get_all_wishes(self, user_id: int = 1) -> List[Dict[str, Any]]:
        """获取所有心愿
        
        对应iOS的CoreDataManager.getAllWishes()
        
        Args:
            user_id: 用户ID
            
        Returns:
            心愿列表
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM wishes WHERE user_id = ? ORDER BY created_at DESC
            ''', (user_id,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_pending_wishes(self, user_id: int = 1) -> List[Dict[str, Any]]:
        """获取待兑换心愿
        
        对应iOS的CoreDataManager.getPendingWishes()
        
        Args:
            user_id: 用户ID
            
        Returns:
            待兑换心愿列表
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM wishes WHERE user_id = ? AND status = 'pending' ORDER BY created_at DESC
            ''', (user_id,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_wish_by_id(self, wish_id: int, user_id: int = 1) -> Optional[Dict[str, Any]]:
        """根据ID获取心愿
        
        对应iOS的CoreDataManager.getWishById()
        
        Args:
            wish_id: 心愿ID
            user_id: 用户ID
            
        Returns:
            心愿字典，或None
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM wishes WHERE id = ? AND user_id = ?
            ''', (wish_id, user_id))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def redeem_wish(self, wish_id: int, user_id: int = 1) -> bool:
        """兑换心愿
        
        对应iOS的CoreDataManager.redeemWish()
        
        Args:
            wish_id: 心愿ID
            user_id: 用户ID
            
        Returns:
            是否兑换成功
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE wishes SET status = 'redeemed', redeemed_at = ? WHERE id = ? AND user_id = ?
            ''', (int(datetime.now().timestamp()), wish_id, user_id))
            return cursor.rowcount > 0
    
    def update_wish_progress(self, wish_id: int, progress: float, user_id: int = 1) -> bool:
        """更新心愿进度
        
        对应iOS的CoreDataManager.updateWishProgress()
        
        Args:
            wish_id: 心愿ID
            progress: 进度值
            user_id: 用户ID
            
        Returns:
            是否更新成功
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE wishes SET progress = ? WHERE id = ? AND user_id = ?
            ''', (progress, wish_id, user_id))
            return cursor.rowcount > 0
    
    def update_all_wishes_progress(self, total_score: float, user_id: int = 1) -> bool:
        """更新所有待兑换心愿的进度
        
        对应iOS的CoreDataManager.updateAllWishesProgress()
        
        Args:
            total_score: 当前总积分
            user_id: 用户ID
            
        Returns:
            是否更新成功
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE wishes SET progress = ? / cost WHERE user_id = ? AND status = 'pending'
            ''', (total_score, user_id))
            return True
    
    # ----------------- 配置相关 -----------------
    def set_config(self, key: str, value: Any) -> bool:
        """设置配置
        
        对应iOS的CoreDataManager.setConfig()
        
        Args:
            key: 配置键
            value: 配置值
            
        Returns:
            是否设置成功
        """
        import json
        
        with self.get_connection() as conn:
            cursor = conn.cursor()
            json_value = json.dumps(value)
            try:
                cursor.execute('''
                    INSERT INTO system_config (key, value)
                    VALUES (?, ?)
                    ON CONFLICT(key) DO UPDATE SET value = ?
                ''', (key, json_value, json_value))
                return True
            except Exception as e:
                print(f"设置配置失败: {e}")
                return False
    
    def get_config(self, key: str, default: Any = None) -> Any:
        """获取配置
        
        对应iOS的CoreDataManager.getConfig()
        
        Args:
            key: 配置键
            default: 默认值
            
        Returns:
            配置值
        """
        import json
        
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT value FROM system_config WHERE key = ?', (key,))
            row = cursor.fetchone()
            
            if not row:
                return default
            
            try:
                return json.loads(row["value"])
            except json.JSONDecodeError:
                return default
