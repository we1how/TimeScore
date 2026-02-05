//
//  SuccessOverlayView.swift
//  TimeScore
//
//  成功记录行为界面
//  对应 UI 原型: 成功记录行为界面.html
//

import SwiftUI

struct SuccessOverlayView: View {

    // MARK: - Properties

    let result: RecordResult
    let onComplete: () -> Void

    @State private var showParticles = false
    @State private var scaleEffect: CGFloat = 0.5
    @State private var opacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // 纯黑背景，确保完全覆盖
            Color.black
                .ignoresSafeArea()

            // 粒子效果背景
            if showParticles {
                ParticleView()
            }

            VStack(spacing: 32) {
                Spacer()

                // 成功图标
                ZStack {
                    // 发光背景
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)

                    // 主图标
                    Circle()
                        .fill(Color.primaryGreen)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.primaryGreen.opacity(0.4), radius: 20, x: 0, y: 0)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                .scaleEffect(scaleEffect)

                // 文字内容
                VStack(spacing: 8) {
                    Text("Achievement Unlocked")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.primaryGreen)
                        .textCase(.uppercase)

                    Text(result.scoreDescription)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text(result.behavior.name ?? "Behavior Recorded")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                // 能量进度卡片
                energyCard

                Spacer()

                // 继续按钮
                Button(action: onComplete) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                scaleEffect = 1.0
            }

            withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                showParticles = true
            }
        }
    }

    // MARK: - Energy Card

    private var energyCard: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryGreen)

                    Text("Energy Level")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text("\(Int(result.newEnergy))/120")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primaryGreen)
                        .frame(width: geometry.size.width * (result.newEnergy / 120), height: 6)
                        .shadow(color: Color.primaryGreen.opacity(0.6), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)

            // 提示文字
            Text(energyHint)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 32)
    }

    // MARK: - Energy Hint

    private var energyHint: String {
        if result.energyChange > 0 {
            return "精力恢复 \(Int(result.energyChange)) 点！"
        } else if result.newEnergy < 30 {
            return "精力较低，建议休息一下"
        } else if result.newEnergy > 90 {
            return "精力充沛，状态极佳！"
        } else {
            return "距离满精力还有 \(Int(120 - result.newEnergy)) 点"
        }
    }
}

// MARK: - Particle View

struct ParticleView: View {

    @State private var particles: [Particle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width,
                    y: particle.y * size.height,
                    width: particle.size,
                    height: particle.size
                )

                context.opacity = particle.opacity
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color)
                )
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: 0.3...0.7),
                size: CGFloat.random(in: 4...12),
                color: Bool.random() ? Color.primaryGreen : Color.accentGold,
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
}

// MARK: - Particle Model

struct Particle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Preview

struct SuccessOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataStack.shared.viewContext
        let behavior = Behavior(context: context)
        behavior.name = "Test Behavior"
        behavior.score = 231
        behavior.energyChange = -10

        let result = RecordResult(
            behavior: behavior,
            score: 231,
            energyChange: -10,
            newTotalPoints: 1250,
            newEnergy: 85
        )

        return SuccessOverlayView(result: result) {}
    }
}
