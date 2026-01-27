#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CLI可视化仪表盘

负责生成CLI仪表盘、时间轴、热力图等可视化输出
对应iOS的DashboardViewModel
"""

from typing import List, Dict, Any
from termcolor import colored
from datetime import datetime, timedelta

class Dashboard:
    """CLI可视化仪表盘类
    
    对应iOS的DashboardViewModel
    
    负责生成CLI仪表盘、时间轴、热力图等可视化输出
    """
    
    def __init__(self, db):
        """初始化仪表盘
        
        对应iOS的DashboardViewModel.init()
        
        Args:
            db: 数据库操作对象
        """
        self.db = db
    
    def show(self):
        """显示完整仪表盘
        
        对应iOS的DashboardViewController.viewDidLoad()
        """
        print("\n" + "="*60)
        print(colored("TimeScore 仪表盘", "cyan", attrs=["bold"]))
        print("="*60)
        
        # 显示核心指标卡片
        self._show_core_metrics()
        
        # 显示时间轴
        self._show_timeline()
        
        # 显示热力图
        self._show_heatmap()
        
        # 显示RPG反馈
        self._show_rpg_feedback()
        
        print("="*60 + "\n")
    
    def _show_core_metrics(self):
        """显示核心指标卡片
        
        对应iOS的DashboardViewModel.showCoreMetrics()
        """
        # 获取总积分
        total_score = self.db.get_total_score()
        
        # 获取用户状态
        user_state = self.db.get_user_state()
        
        # 获取今日记录
        today_records = self.db.get_today_records()
        
        # 计算平均心情
        if today_records:
            avg_mood = sum(record["mood"] for record in today_records) / len(today_records)
            avg_mood = round(avg_mood)
        else:
            avg_mood = 3
        
        # 计算效率比（如果有精力消耗数据）
        total_energy_cost = sum(abs(record["energy_consume"]) for record in today_records if "energy_consume" in record)
        if total_energy_cost > 0:
            efficiency = total_score / total_energy_cost
        else:
            efficiency = 0
        
        # 显示仪表盘卡片
        print("┌──────────────┐ ┌──────────────┐")
        print(f"│总积分: {total_score:.1f} │ │效率: {efficiency:.1f}/点 │")
        print("└──────────────┘ └──────────────┘")
        print("┌──────────────┐ ┌──────────────┐")
        print(f"│连击: {user_state['combo_count']}次  │ │心情: {self._get_star_rating(avg_mood)} │")
        print("└──────────────┘ └──────────────┘")
    
    def _show_timeline(self, days: int = 1):
        """显示时间轴
        
        对应iOS的DashboardViewModel.showTimeline()
        
        Args:
            days: 显示天数
        """
        print("\n" + "="*50)
        print(colored("时间轴", "cyan", attrs=["bold"]))
        print("="*50)
        
        # 获取今日记录
        today_records = self.db.get_today_records()
        
        if not today_records:
            print("今日暂无行为记录")
            return
        
        # 按时间排序
        sorted_records = sorted(today_records, key=lambda x: x["start_ts"])
        
        for record in sorted_records:
            # 格式化时间
            start_time = datetime.fromtimestamp(record["start_ts"]).strftime("%H:%M")
            end_time = datetime.fromtimestamp(record["end_ts"]).strftime("%H:%M")
            
            # 等级颜色
            level_color_map = {
                "S": "green",
                "A": "blue",
                "B": "yellow",
                "C": "magenta",
                "D": "red",
                "R": "cyan"
            }
            level_color = level_color_map.get(record["level"], "white")
            
            # 生成进度条
            bar_length = min(20, int(record["duration"] / 5))  # 每5分钟一个字符
            bar = "■" * bar_length
            
            # 生成星级
            star_rating = self._get_star_rating(record["mood"])
            
            # 显示记录
            print(f"{start_time}-{end_time} [{colored(bar, level_color)}] {record['level']}级 "
                  f"积分:{record['final_score']:.0f} 精力:{record['energy_consume']:+.1f} "
                  f"心情:{star_rating}")
    
    def _show_heatmap(self, days: int = 30):
        """显示热力图
        
        对应iOS的DashboardViewModel.showHeatmap()
        
        Args:
            days: 显示天数
        """
        print("\n" + "="*50)
        print(colored("热力图", "cyan", attrs=["bold"]))
        print("="*50)
        
        # 获取过去days天的日期
        today = datetime.now().date()
        dates = [today - timedelta(days=i) for i in range(days-1, -1, -1)]
        
        # 简化处理，实际应该从数据库获取每日积分
        # 这里使用模拟数据
        daily_scores = {}
        for date in dates:
            # 计算当天的时间戳范围
            start_ts = int(datetime.combine(date, datetime.min.time()).timestamp())
            end_ts = int(datetime.combine(date, datetime.max.time()).timestamp())
            
            # 查询当天的所有记录
            self.db.cursor.execute(
                "SELECT SUM(final_score) FROM core_behavior WHERE start_ts BETWEEN ? AND ?",
                (start_ts, end_ts)
            )
            result = self.db.cursor.fetchone()[0]
            daily_scores[date] = result or 0
        
        # 显示月份
        print(f"{today.strftime('%b %Y')}")
        print("S M T W T F S")
        
        # 生成热力图网格
        week = []
        for date in dates:
            day = date.day
            score = daily_scores[date]
            
            # 根据分数确定颜色
            if score < 50:
                color = "red"
                char = "□"
            elif score < 100:
                color = "yellow"
                char = "■"
            elif score < 200:
                color = "green"
                char = "■"
            else:
                color = "green"
                char = "■■"
            
            week.append(colored(f"{day:2d}{char}", color))
            
            # 每周换行
            if date.weekday() == 6:  # 周日
                print(" ".join(week))
                week = []
        
        # 打印剩余的
        if week:
            print(" ".join(week))
    
    def _show_rpg_feedback(self):
        """显示RPG反馈
        
        对应iOS的DashboardViewModel.showRPGFeedback()
        """
        print("\n" + "="*50)
        print(colored("RPG反馈", "cyan", attrs=["bold"]))
        print("="*50)
        
        # 获取总积分
        total_score = self.db.get_total_score()
        
        # 获取用户状态
        user_state = self.db.get_user_state()
        
        # 计算等级（每1000分升一级）
        level = int(total_score / 1000) + 1
        xp = total_score % 1000
        
        # 生成XP进度条
        xp_bar_length = 8
        filled_bars = int((xp / 1000) * xp_bar_length)
        xp_bar = "■" * filled_bars + "□" * (xp_bar_length - filled_bars)
        
        # 显示RPG信息
        print(f"角色: 时间大师 Lv.{level}")
        print(f"XP: [{xp_bar}] {xp}/1000")
        print("属性:")
        print(f"- 专注: Lv.{min(5, level)} ({'■' * min(5, level)})")
        print(f"- 恢复: Lv.{min(5, int(level/2))} ({'■' * min(5, int(level/2))})")
        print(f"- 耐力: Lv.{min(5, int(level/3))} ({'■' * min(5, int(level/3))})")
        
        # 装备（基于连击数）
        if user_state['combo_count'] >= 3:
            print("装备: 连击剑 (解锁于3连击)")
        elif user_state['combo_count'] >= 1:
            print("装备: 入门装备")
        else:
            print("装备: 无")
    
    def _get_star_rating(self, mood: int) -> str:
        """根据心情值生成星级评分
        
        对应iOS的DashboardViewModel.getStarRating()
        
        Args:
            mood: 心情值（1-5）
            
        Returns:
            星级评分字符串
        """
        full_star = "★"
        empty_star = "☆"
        return full_star * mood + empty_star * (5 - mood)
