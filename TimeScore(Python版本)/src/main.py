#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TimeScore 主程序入口

对应iOS的AppDelegate

整合所有模块，处理用户输入和调用各个模块的功能
"""

from src.db.sqlite import SQLiteDB
from src.visualization.dashboard import Dashboard
from src.redeem.exchange import ExchangeSystem


def main():
    """主程序入口
    
    对应iOS的AppDelegate.application(_:didFinishLaunchingWithOptions:)
    """
    print("=== Welcome to TimeScore 时间管理系统 ===")
    
    # 初始化数据库连接
    db = SQLiteDB()
    
    try:
        while True:
            # 显示主菜单
            choice = _show_main_menu()
            
            if choice == "5":
                break
            elif choice == "1":
                _add_behavior(db)
            elif choice == "2":
                _record_behavior(db)
            elif choice == "3":
                _show_visualization(db)
            elif choice == "4":
                _run_exchange_system(db)
            else:
                print("无效的选项，请重新输入！")
    finally:
        # 关闭数据库连接
        db.close()


def _show_main_menu() -> str:
    """显示主菜单
    
    对应iOS的MainViewController.viewDidLoad()
    
    Returns:
        用户选择的选项
    """
    print("\n请选择要进入的界面：")
    print("1. 增加行为界面")
    print("2. 记录行为界面")
    print("3. 历史回顾系统")
    print("4. 积分兑换系统")
    print("5. 退出系统")
    
    return input("请输入选项编号（1-5）: ")


def _add_behavior(db):
    """增加行为界面
    
    对应iOS的AddBehaviorViewController.viewDidLoad()
    
    Args:
        db: 数据库操作对象
    """
    print("\n=== 增加行为界面 ===")
    # TODO: 实现增加行为功能
    print("该功能暂未实现，敬请期待！")


def _record_behavior(db):
    """记录行为界面
    
    对应iOS的RecordBehaviorViewController.viewDidLoad()
    
    Args:
        db: 数据库操作对象
    """
    print("\n=== 记录行为界面 ===")
    # TODO: 实现记录行为功能
    print("该功能暂未实现，敬请期待！")


def _show_visualization(db):
    """历史回顾系统
    
    对应iOS的VisualizationViewController.viewDidLoad()
    
    Args:
        db: 数据库操作对象
    """
    print("\n=== 历史回顾系统 ===")
    dashboard = Dashboard(db)
    dashboard.show()


def _run_exchange_system(db):
    """积分兑换系统
    
    对应iOS的ExchangeViewController.viewDidLoad()
    
    Args:
        db: 数据库操作对象
    """
    exchange = ExchangeSystem(db)
    exchange.run()


if __name__ == "__main__":
    main()
