import SwiftUI

struct FlowChipSelector<T: Hashable>: View {
  let options: [(T, String)]
  @Binding var selection: T
  var activeColor: Color = AppTheme.primary

  var body: some View {
    FlowLayout(spacing: 10, lineSpacing: 10) {
      ForEach(options, id: \.0) { option in
        let isSelected = selection == option.0
        Text(option.1)
          .font(AppTheme.sansFont(size: 14, weight: isSelected ? .bold : .medium))
          .foregroundColor(isSelected ? AppTheme.iconOnAccent : AppTheme.foreground.opacity(0.8))
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            isSelected
              ? AnyView(activeColor)
              : AnyView(AppTheme.card.opacity(0.5))
          )
          .clipShape(Capsule())
          .overlay(
            Capsule()
              .stroke(isSelected ? Color.clear : AppTheme.hairline, lineWidth: 0.5)
          )
          .shadow(color: isSelected ? activeColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              selection = option.0
            }
          }
      }
    }
  }
}
