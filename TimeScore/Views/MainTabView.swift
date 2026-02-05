//
//  MainTabView.swift
//  TimeScore
//
//  主 TabView 架构
//  三栏: Home / Insights / Wishlist
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @State private var showQuickRecord = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 首页
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                // 数据洞察
                InsightsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Insights")
                    }
                    .tag(1)

                // 心愿兑换
                WishlistView()
                    .tabItem {
                        Image(systemName: "gift.fill")
                        Text("Wishlist")
                    }
                    .tag(2)
            }
            .tint(Color.primaryGreen)

            // 悬浮添加按钮 - 只在首页显示
            if selectedTab == 0 {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Button(action: { showQuickRecord = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.primaryGreen)
                                .clipShape(Circle())
                                .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // 增加底部间距，避免与 TabBar 重叠
                    }
                }
            }
        }
        .sheet(isPresented: $showQuickRecord) {
            DetailRecordView()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
