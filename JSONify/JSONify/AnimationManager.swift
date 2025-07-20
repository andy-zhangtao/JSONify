//
//  AnimationManager.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI

// MARK: - 动画配置管理器
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var isReducedMotionEnabled = false
    
    private init() {
        // 检查系统是否启用了减少动画
        updateReducedMotionSetting()
    }
    
    private func updateReducedMotionSetting() {
        #if os(macOS)
        isReducedMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }
    
    // MARK: - 预定义动画
    
    var spring: Animation {
        isReducedMotionEnabled ? 
            .easeInOut(duration: 0.1) : 
            .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    var bouncy: Animation {
        isReducedMotionEnabled ? 
            .easeInOut(duration: 0.1) : 
            .spring(response: 0.3, dampingFraction: 0.6)
    }
    
    var smooth: Animation {
        isReducedMotionEnabled ? 
            .linear(duration: 0.1) : 
            .easeInOut(duration: 0.3)
    }
    
    var quick: Animation {
        isReducedMotionEnabled ? 
            .linear(duration: 0.05) : 
            .easeInOut(duration: 0.15)
    }
    
    var slow: Animation {
        isReducedMotionEnabled ? 
            .linear(duration: 0.2) : 
            .easeInOut(duration: 0.6)
    }
}

// MARK: - 动画修饰符
struct AnimatedScale: ViewModifier {
    @StateObject private var animationManager = AnimationManager.shared
    let trigger: Bool
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(trigger ? scale : 1.0)
            .animation(animationManager.spring, value: trigger)
    }
}

struct AnimatedOpacity: ViewModifier {
    @StateObject private var animationManager = AnimationManager.shared
    let trigger: Bool
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(trigger ? opacity : 1.0)
            .animation(animationManager.smooth, value: trigger)
    }
}

struct AnimatedSlide: ViewModifier {
    @StateObject private var animationManager = AnimationManager.shared
    let trigger: Bool
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content
            .offset(trigger ? offset : .zero)
            .animation(animationManager.spring, value: trigger)
    }
}

struct AnimatedRotation: ViewModifier {
    @StateObject private var animationManager = AnimationManager.shared
    let trigger: Bool
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(trigger ? angle : 0))
            .animation(animationManager.smooth, value: trigger)
    }
}

// MARK: - 页面转场动画
struct PageTransition: ViewModifier {
    @StateObject private var animationManager = AnimationManager.shared
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1.0 : 0.0)
            .scaleEffect(isActive ? 1.0 : 0.95)
            .offset(y: isActive ? 0 : 20)
            .animation(animationManager.spring, value: isActive)
    }
}

// MARK: - 脉冲动画
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    @StateObject private var animationManager = AnimationManager.shared
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                animationManager.isReducedMotionEnabled ? 
                    .none : 
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                if isActive && !animationManager.isReducedMotionEnabled {
                    isPulsing = true
                }
            }
            .onChange(of: isActive) { _, newValue in
                if !animationManager.isReducedMotionEnabled {
                    isPulsing = newValue
                }
            }
    }
}

// MARK: - 打字机效果
struct TypewriterText: View {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTypewriting()
            }
    }
    
    private func startTypewriting() {
        if animationManager.isReducedMotionEnabled {
            displayedText = text
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - 粒子效果
struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    @StateObject private var animationManager = AnimationManager.shared
    let isActive: Bool
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var opacity: Double
        var scale: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.blue.opacity(particle.opacity))
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .position(particle.position)
            }
        }
        .onAppear {
            if isActive && !animationManager.isReducedMotionEnabled {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles.removeAll()
        
        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(x: 100, y: 100),
                velocity: CGPoint(
                    x: Double.random(in: -2...2),
                    y: Double.random(in: -2...2)
                ),
                opacity: Double.random(in: 0.3...1.0),
                scale: Double.random(in: 0.5...1.5)
            )
            particles.append(particle)
        }
        
        animateParticles()
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in 0..<particles.count {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity -= 0.01
                particles[i].scale -= 0.01
                
                if particles[i].opacity <= 0 {
                    particles[i].opacity = 0
                }
            }
            
            particles = particles.filter { $0.opacity > 0 }
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

// MARK: - View 扩展
extension View {
    func animatedScale(trigger: Bool, scale: CGFloat = 1.1) -> some View {
        modifier(AnimatedScale(trigger: trigger, scale: scale))
    }
    
    func animatedOpacity(trigger: Bool, opacity: Double = 0.5) -> some View {
        modifier(AnimatedOpacity(trigger: trigger, opacity: opacity))
    }
    
    func animatedSlide(trigger: Bool, offset: CGSize = CGSize(width: 10, height: 0)) -> some View {
        modifier(AnimatedSlide(trigger: trigger, offset: offset))
    }
    
    func animatedRotation(trigger: Bool, angle: Double = 180) -> some View {
        modifier(AnimatedRotation(trigger: trigger, angle: angle))
    }
    
    func pageTransition(isActive: Bool) -> some View {
        modifier(PageTransition(isActive: isActive))
    }
    
    func pulseEffect(isActive: Bool = true) -> some View {
        modifier(PulseEffect(isActive: isActive))
    }
}