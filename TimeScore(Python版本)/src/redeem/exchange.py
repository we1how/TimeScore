#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
积分兑换系统

负责管理心愿和积分兑换
对应iOS的ExchangeViewModel
"""

from typing import List, Dict, Any
from datetime import datetime
from src.models.wish import Wish
from src.db.sqlite import SQLiteDB

class ExchangeSystem:
    """积分兑换系统类
    
    对应iOS的ExchangeViewModel
    
    负责管理心愿和积分兑换
    """
    
    def __init__(self, db: SQLiteDB):
        """初始化积分兑换系统
        
        对应iOS的ExchangeViewModel.init()
        
        Args:
            db: 数据库操作对象
        """
        self.db = db
        self.MIN_WISH_COST = 100  # 心愿积分成本下限
    
    def run(self):
        """运行积分兑换系统
        
        对应iOS的ExchangeViewController.viewDidLoad()
        """
        while True:
            # 显示兑换菜单
            choice = self._show_exchange_menu()
            
            if choice == "0":
                break
            elif choice == "1":
                self._add_wish()
            elif choice == "2":
                self._redeem_wish()
            else:
                print("无效的选项，请重新输入！")
    
    def _show_exchange_menu(self) -> str:
        """显示积分兑换主菜单
        
        对应iOS的ExchangeViewModel.showExchangeMenu()
        
        Returns:
            用户选择的选项
        """
        print("\n" + "="*60)
        print("积分兑换中心")
        print("="*60)
        
        # 获取当前总积分
        total_score = self.db.get_total_score()
        print(f"当前总积分: {total_score:.1f}")
        
        # 获取待兑换心愿数量
        pending_wishes = self.db.get_pending_wishes()
        available_count = sum(1 for wish_dict in pending_wishes if total_score >= wish_dict["cost"])
        
        print("\n请选择操作：")
        print("1. 新增心愿")
        print(f"2. 兑换心愿 (可用: {available_count})")
        print("0. 返回主菜单")
        
        return input("请输入选项编号: ")
    
    def _add_wish(self):
        """新增心愿
        
        对应iOS的ExchangeViewModel.addWish()
        """
        print("\n" + "="*60)
        print("新增心愿")
        print("="*60)
        
        # 获取当前总积分，用于AI建议
        total_score = self.db.get_total_score()
        
        # 获取心愿名称
        while True:
            name = input("请输入心愿名称（限50字）: ").strip()
            if name and len(name) <= 50:
                break
            print("心愿名称不能为空且不能超过50字，请重新输入！")
        
        # 获取所需积分
        while True:
            cost_input = input(f"请输入所需积分（最小值: {self.MIN_WISH_COST}）: ").strip()
            try:
                cost = int(cost_input)
                if cost >= self.MIN_WISH_COST:
                    break
                print(f"所需积分不能低于{self.MIN_WISH_COST}，请重新输入！")
            except ValueError:
                print("请输入有效的整数！")
        
        # 确认添加
        confirm = input(f"\n确认添加心愿「{name}」，所需积分：{cost}？(y/n): ").strip().lower()
        if confirm != "y":
            print("\n已取消添加心愿")
            return
        
        # 创建心愿对象
        wish = Wish(
            name=name,
            cost=cost,
            created_at=datetime.now()
        )
        
        # 添加心愿到数据库
        wish_id = self.db.add_wish(wish.to_db_dict())
        if wish_id:
            wish.id = wish_id
            print(f"\n✅ 心愿添加成功！ID: {wish_id}")
            self._show_wish_details(wish)
        else:
            print("\n❌ 心愿添加失败，请重试！")
    
    def _redeem_wish(self):
        """兑换心愿
        
        对应iOS的ExchangeViewModel.redeemWish()
        """
        print("\n" + "="*60)
        print("兑换心愿")
        print("="*60)
        
        # 获取当前总积分
        total_score = self.db.get_total_score()
        
        # 获取待兑换心愿
        pending_wishes = self.db.get_pending_wishes()
        
        if not pending_wishes:
            print("\n您还没有添加任何心愿，请先添加心愿！")
            return
        
        # 更新所有心愿的进度
        self.db.update_all_wishes_progress(total_score)
        
        # 重新获取更新后的心愿
        pending_wishes = self.db.get_pending_wishes()
        
        # 显示心愿列表
        print("\n心愿列表：")
        print("-"*60)
        for wish_dict in pending_wishes:
            # 创建Wish对象
            wish = Wish.from_db_row(wish_dict)
            
            # 生成进度条
            bar_length = 20
            filled_length = int(bar_length * wish.progress)
            bar = "■" * filled_length + "□" * (bar_length - filled_length)
            
            # 计算进度百分比
            progress_percent = wish.progress * 100
            
            # 积分是否足够
            if total_score >= wish.cost:
                status = "✓ 积分够"
            else:
                status = f"✗ 需{wish.cost - total_score:.1f}积分"
            
            print(f"{wish.id}. {wish.name} - {wish.cost}分 [{bar}] {progress_percent:.0f}% {status}")
        
        # 选择要兑换的心愿
        while True:
            wish_id_input = input("\n请输入要兑换的心愿ID（0返回）: ").strip()
            if wish_id_input == "0":
                return
            
            try:
                wish_id = int(wish_id_input)
                # 检查心愿是否存在
                wish_dict = self.db.get_wish_by_id(wish_id)
                if wish_dict:
                    break
                print("无效的心愿ID，请重新输入！")
            except ValueError:
                print("请输入有效的整数！")
        
        # 创建Wish对象
        wish = Wish.from_db_row(wish_dict)
        
        # 检查积分是否足够
        if total_score < wish.cost:
            print(f"\n❌ 积分不足！需要 {wish.cost} 积分，当前只有 {total_score:.1f} 积分")
            print("继续努力积累积分吧！")
            return
        
        # 确认兑换
        confirm = input(f"\n确认兑换心愿「{wish.name}」，消耗 {wish.cost} 积分？(y/n): ").strip().lower()
        if confirm != "y":
            print("\n已取消兑换")
            return
        
        # 执行兑换
        if self.db.redeem_wish(wish.id):
            # 兑换成功，触发庆祝
            print("\n🎉 兑换成功！")
            print(f"恭喜您实现了心愿：{wish.name}")
            print(f"剩余积分: {total_score - wish.cost:.1f}")
            print("\n✨ 继续努力积累积分，实现更多心愿吧！")
        else:
            print("\n❌ 兑换失败，请重试！")
    
    def _show_wish_details(self, wish: Wish):
        """显示心愿详情
        
        对应iOS的ExchangeViewModel.showWishDetails()
        
        Args:
            wish: 心愿对象
        """
        print(f"\n心愿详情：")
        print(f"ID: {wish.id}")
        print(f"名称: {wish.name}")
        print(f"所需积分: {wish.cost}")
        print(f"状态: {wish.status}")
        print(f"创建时间: {wish.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
