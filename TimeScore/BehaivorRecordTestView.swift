//
//  BehaivorRecordTestView.swift
//  TimeScore
//
//  Created by 林伟豪 on 2026/1/31.
//
import SwiftUI

struct TimeScoreMainView: View {
    // 状态变量
    @State private var grade: String = "S"
    @State private var behavior: String = "尚未选择具体行为"
    @State private var energyProgress: Double = 0.75 // 精力进度条，默认75%
    @State private var todayScore: Int = 1250 // 今日分数
    @State private var selectedTab: Int = 0 // 当前选中的标签页
    
    var body: some View {
        ZStack {
            // 纯白背景
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                // 顶部空间，用于放置右上角按钮
                Spacer().frame(height: 20)
                
                // 中央圆形精力进度条
                ZStack {
                    // 背景圆环
                    Circle()
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 320, height: 320)
                    
                    // 精力进度圆环
                    Circle()
                        .trim(from: 0, to: energyProgress)
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 320, height: 320)
                        .rotationEffect(.degrees(-90))
                    
                    // 分数和标签
                    VStack(spacing: 8) {
                        Text("\(todayScore)")
                            .font(.system(size: 60, weight: .light, design: .serif))
                            .foregroundColor(.black)
                        Text("今日分数")
                            .font(.system(size: 16, design: .serif))
                            .foregroundColor(.gray)
                    }
                }
                
                // 行为输入框
                HStack(spacing: 0) {
                    // 等级选择器
                    Picker("等级", selection: $grade) {
                        ForEach(["S", "A", "B", "C", "D", "E", "R"], id: \.self) { 
                            Text($0)
                                .font(.system(size: 18, design: .serif))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .accentColor(.white)
                    .font(.system(size: 18, design: .serif))
                    
                    // 分隔线
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    // 行为选择器
                    Picker("行为", selection: $behavior) {
                        Text("尚未选择具体行为").tag("尚未选择具体行为")
                        // 可在此添加更多行为选项
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .accentColor(.white.opacity(0.8))
                    .font(.system(size: 16, design: .serif))
                    
                    // 分隔线
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    // play按钮
                    Button(action: {}) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .padding()
                .background(Color.black.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal, 20.0)
                
                // 底部空间，用于放置标签栏
                Spacer()
            }
            
            // 右上角按钮
            VStack {
                HStack {
                    Spacer()
                    
                    // 增加行为按钮
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .padding(8)
                    .accessibilityLabel("增加行为")
                    
                    // 详细记录按钮
                    Button(action: {}) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .padding(8)
                    .padding(.trailing, 16)
                    .accessibilityLabel("详细记录")
                }
                Spacer()
            }
            
            // 底部标签栏
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // 首页标签
                    Button(action: { selectedTab = 0 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 0 ? .black : .gray)
                            Text("首页")
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(selectedTab == 0 ? .black : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // 记录标签
                    Button(action: { selectedTab = 1 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 1 ? .black : .gray)
                            Text("记录")
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(selectedTab == 1 ? .black : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // 设置标签
                    Button(action: { selectedTab = 2 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "gear")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 2 ? .black : .gray)
                            Text("设置")
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(selectedTab == 2 ? .black : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .alignmentGuide(.top) { $0[.top] },
                    alignment: .top
                )
            }
        }
        .environment(\.colorScheme, .light) // 默认浅色模式
    }
}

#Preview {
    TimeScoreMainView()
}

#Preview("Dark Mode") {
    TimeScoreMainView()
        .environment(\.colorScheme, .dark)
        .background(Color.black)
} 

