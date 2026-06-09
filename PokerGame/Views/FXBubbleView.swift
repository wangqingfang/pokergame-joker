import SwiftUI

/// 漂浮特效气泡：从指定锚点淡入 → 上飘 → 淡出
struct FXBubbleView: View {
    let bubble: FXBubble
    @State private var phase: CGFloat = 0  // 0=刚出现, 1=飘到顶

    var body: some View {
        Text(bubble.text)
            .font(.system(size: bubble.isBig ? 36 : 22, weight: .heavy, design: .rounded))
            .foregroundColor(bubble.color)
            .shadow(color: bubble.color.opacity(0.8), radius: 8)
            .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
            .scaleEffect(0.6 + phase * 0.6)        // 0.6 → 1.2
            .offset(y: -phase * 70)
            .opacity(1.0 - phase * 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) { phase = 1.0 }
            }
            .allowsHitTesting(false)
    }
}

/// 屏幕震动 modifier
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = sin(animatableData * .pi * 6) * amount * (1 - animatableData)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}
