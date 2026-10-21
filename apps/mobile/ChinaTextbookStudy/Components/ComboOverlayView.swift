import SwiftUI

/// Full-screen overlay badge shown when combo hits milestones (3, 5, 10).
/// Ported from `apps/web/src/components/ComboOverlay.tsx`.
struct ComboOverlayView: View {
    let combo: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(ClayFont.title)
                .foregroundStyle(ClayColor.white)
            Text("连击 ×\(combo)")
                .font(ClayFont.happy(size: 22))
                .foregroundStyle(ClayColor.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [ClayColor.flameCore, ClayColor.orange, ClayColor.balloonKnot],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: ClayRadius.bubble)
        )
        .clayShadow(.orange)
        .scaleEffect(scale)
        .opacity(opacity)
        .accessibilityIdentifier("lesson-combo")
        .allowsHitTesting(false)
        .onAppear {
            SFXEngine.shared.play(.combo)
            HapticEngine.shared.success()
            if reduceMotion {
                // Reduce Motion:不弹跳,直接以原尺寸出现,只保留淡出。
                scale = 1.0
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                    if !reduceMotion { scale = 0.8 }
                }
            }
        }
    }
}
