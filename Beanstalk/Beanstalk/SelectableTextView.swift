import SwiftUI
import UIKit
import Combine

struct HighlightRange: Equatable {
    let range: NSRange
    let color: UIColor
    var note: String? = nil
    
    var isNote: Bool {
        guard let n = note else { return false }
        return !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    static func == (lhs: HighlightRange, rhs: HighlightRange) -> Bool {
        return lhs.range == rhs.range && lhs.note == rhs.note && lhs.color.isEqual(rhs.color)
    }
}

struct BubbleShape: Shape {
    var cornerRadius: CGFloat = 20
    var tailHeight: CGFloat = 0
    var tailWidth: CGFloat = 16
    var tailPointsDown: Bool = true
    var pointerX: CGFloat? = nil
    
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(cornerRadius, AnimatablePair(tailHeight, pointerX ?? 0)) }
        set {
            cornerRadius = newValue.first
            tailHeight = newValue.second.first
            pointerX = newValue.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let targetMidX = pointerX ?? rect.midX
        let minX = cornerRadius + tailWidth / 2
        let maxX = max(minX, rect.width - cornerRadius - tailWidth / 2)
        let clampedMidX = max(minX, min(targetMidX, maxX))
        
        if tailPointsDown {
            let bubbleRect = CGRect(x: 0, y: 0, width: rect.width, height: max(0, rect.height - tailHeight))
            path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
            if tailHeight > 0.5 {
                path.move(to: CGPoint(x: clampedMidX - tailWidth / 2, y: bubbleRect.maxY))
                path.addLine(to: CGPoint(x: clampedMidX, y: rect.maxY))
                path.addLine(to: CGPoint(x: clampedMidX + tailWidth / 2, y: bubbleRect.maxY))
                path.closeSubpath()
            }
        } else {
            let bubbleRect = CGRect(x: 0, y: tailHeight, width: rect.width, height: max(0, rect.height - tailHeight))
            path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
            if tailHeight > 0.5 {
                path.move(to: CGPoint(x: clampedMidX - tailWidth / 2, y: bubbleRect.minY))
                path.addLine(to: CGPoint(x: clampedMidX, y: 0))
                path.addLine(to: CGPoint(x: clampedMidX + tailWidth / 2, y: bubbleRect.minY))
                path.closeSubpath()
            }
        }
        
        return path
    }
}

// Red-tinted liquid glass delete menu for tapped highlights
struct DeleteHighlightMenuView: View {
    var onDelete: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onDelete()
        }) {
            HStack(spacing: 6) {
                Image("trash")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white)
                
                Text("Delete")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Color.red.opacity(0.65)), in: .capsule)
        .shadow(color: Color.red.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// Liquid glass note viewer: snug fit-text horizontal capsule with red circular delete button
struct NoteDisplayMenuView: View {
    var noteText: String
    var isSingleLine: Bool = true
    var isAbove: Bool
    var pointerX: CGFloat
    var menuWidth: CGFloat
    var menuHeight: CGFloat
    var onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(noteText)
                .font(.custom("InclusiveSans-Regular", size: 15))
                .foregroundColor(.textDark)
                .lineLimit(isSingleLine ? 1 : 4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: isSingleLine, vertical: !isSingleLine)
                .padding(.leading, 14)
                .padding(.vertical, 8)
                .frame(maxHeight: .infinity, alignment: isSingleLine ? .leading : .topLeading)
            
            Spacer(minLength: 6)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDelete()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.26, blue: 0.21))
                        .frame(width: 30, height: 30)
                    
                    Image("trash")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.white)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 30, height: 30)
            .contentShape(Circle())
            .padding(.trailing, 4)
            .padding(.bottom, 4)
        }
        .padding(.bottom, isAbove ? 8 : 0)
        .padding(.top, isAbove ? 0 : 8)
        .frame(width: menuWidth, height: menuHeight)
        .glassEffect(.regular, in: BubbleShape(cornerRadius: 20, tailHeight: 8, tailPointsDown: isAbove, pointerX: pointerX))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
    }
}

final class MenuViewModel: ObservableObject {
    @Published var isAbove: Bool
    @Published var selectionMidX: CGFloat
    @Published var textViewWidth: CGFloat
    
    init(isAbove: Bool, selectionMidX: CGFloat, textViewWidth: CGFloat) {
        self.isAbove = isAbove
        self.selectionMidX = selectionMidX
        self.textViewWidth = textViewWidth
    }
}

struct CustomMenuView: View {
    @ObservedObject var viewModel: MenuViewModel
    var onHighlight: (UIColor) -> Void
    var onAddNote: (String?) -> Void
    var onStartAddNote: (() -> Void)? = nil
    var onCancelAddNote: (() -> Void)? = nil
    var onSizeChange: (CGSize) -> Void
    
    @State private var isAddingNote = false
    @State private var noteText = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool
    
    private var isAbove: Bool {
        viewModel.isAbove
    }
    
    let colors: [UIColor] = [
        UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),
        UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0),
        UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)
    ]
    
    private var isCheckDisabled: Bool {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func cancelNote() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isFocused = false
        onCancelAddNote?()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.74, blendDuration: 0.12)) {
            isAddingNote = false
        }
    }
    
    private func submitNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isSubmitting else { return }
        isSubmitting = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isFocused = false
        onAddNote(trimmed)
    }
    
    private var targetWidth: CGFloat {
        isAddingNote ? 285 : 264
    }
    
    private var targetHeight: CGFloat {
        isAddingNote ? 128 : 46
    }
    
    private var pointerX: CGFloat {
        let menuX = max(8, min(viewModel.selectionMidX - targetWidth / 2, viewModel.textViewWidth - targetWidth - 8))
        return viewModel.selectionMidX - menuX
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isAddingNote {
                noteContentView
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity.combined(with: .scale(scale: 0.94))
                        )
                    )
            } else {
                paletteContentView
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        )
                    )
            }
        }
        .frame(width: targetWidth, height: targetHeight)
        .clipped()
        .glassEffect(.regular, in: BubbleShape(cornerRadius: 23, tailHeight: isAddingNote ? 8 : 0, tailPointsDown: isAbove, pointerX: pointerX))
        .shadow(color: Color.black.opacity(isAddingNote ? 0.14 : 0.08), radius: isAddingNote ? 14 : 8, x: 0, y: isAddingNote ? 6 : 4)
        .onAppear {
            onSizeChange(CGSize(width: targetWidth, height: targetHeight))
        }
        .onChange(of: isAddingNote) { _, adding in
            onSizeChange(CGSize(width: targetWidth, height: targetHeight))
            if adding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if isAddingNote {
                        isFocused = true
                    }
                }
            } else {
                isFocused = false
            }
        }
    }
    
    // Exact 4px padding on all sides (top, bottom, left), 4px spacing between each color
    private var paletteContentView: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onHighlight(color)
                    }) {
                        Circle()
                            .fill(Color(uiColor: color))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .frame(width: 38, height: 38)
                }
            }
            
            Divider()
                .frame(height: 22)
                .padding(.horizontal, 8)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onStartAddNote?()
                withAnimation(.spring(response: 0.44, dampingFraction: 0.74, blendDuration: 0.12)) {
                    isAddingNote = true
                }
            }) {
                Text("Add Note")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.trailing, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 4)
        .padding(.vertical, 4)
        .frame(height: 46)
    }
    
    private var noteContentView: some View {
        ZStack(alignment: .bottom) {
            // Text input area fills the top portion
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    TextField("Add Note....", text: $noteText, axis: .vertical)
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .focused($isFocused)
                        .foregroundColor(.textDark)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollDismissesKeyboard(.never)
                .frame(maxHeight: 56)
                .padding(.horizontal, 16)
                .padding(.top, isAbove ? 12 : 18)
                
                Spacer()
            }
            
            // Buttons overlaid at bottom — highest Z-order, always tappable
            HStack {
                // Cancel button
                Button(action: {
                    cancelNote()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.06))
                            .frame(width: 38, height: 38)
                        
                        Image("x")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(Color.textDark)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                .padding(.bottom, isAbove ? 12 : 7)
                
                Spacer()
                
                // Check / submit button
                Button(action: {
                    submitNote()
                }) {
                    ZStack {
                        Circle()
                            .fill(isCheckDisabled ? Color.black.opacity(0.06) : Color.brandGreen)
                            .frame(width: 38, height: 38)
                        
                        Image("check")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isCheckDisabled ? Color.textSecondary.opacity(0.35) : .white)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .padding(.bottom, isAbove ? 12 : 7)
            }
            .allowsHitTesting(true)
        }
        .frame(width: 285, height: 128)
    }
}

class CustomSelectableTextView: UITextView, UITextViewDelegate, UIGestureRecognizerDelegate {
    var onHighlight: ((NSRange, UIColor) -> Void)?
    var onAddNote: ((NSRange, String) -> Void)?
    var onDeleteHighlight: ((NSRange) -> Void)?
    
    private var customMenuHostingController: UIHostingController<CustomMenuView>?
    private var currentMenuViewModel: MenuViewModel?
    private var activeActionHostingController: UIViewController?
    private var menuWorkItem: DispatchWorkItem?
    private var currentMenuRange: NSRange?
    private var pendingNoteRange: NSRange?
    
    private let highlightsOverlay = UIView()
    private var highlightViewsMap: [NSRange: [UIView]] = [:]
    private var currentHighlights: [HighlightRange] = []
    private var greyPreviewViews: [UIView] = []
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.delegate = self
        self.clipsToBounds = false
        highlightsOverlay.backgroundColor = .clear
        highlightsOverlay.isUserInteractionEnabled = false
        highlightsOverlay.clipsToBounds = false
        self.addSubview(highlightsOverlay)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleHighlightTap(_:)))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        self.addGestureRecognizer(tap)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Allow touch events that land on the custom menu or action popovers, even when they extend outside bounds (crucial for short texts like Card 0)
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let host = customMenuHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(point) {
            return true
        }
        if let host = activeActionHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let loc = gestureRecognizer.location(in: self)
        if let host = customMenuHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(loc) {
            return false
        }
        if let host = activeActionHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(loc) {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            return true
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let hostView = activeActionHostingController?.view {
            let p = touch.location(in: hostView)
            if hostView.bounds.insetBy(dx: -16, dy: -16).contains(p) {
                return false
            }
        }
        if let menuView = customMenuHostingController?.view {
            let p = touch.location(in: menuView)
            if menuView.bounds.insetBy(dx: -16, dy: -16).contains(p) {
                return false
            }
        }
        return true
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let host = activeActionHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(point) {
            let converted = convert(point, to: host.view)
            if let hit = host.view.hitTest(converted, with: event) {
                return hit
            }
            return host.view
        }
        if let host = customMenuHostingController, host.view.frame.insetBy(dx: -16, dy: -16).contains(point) {
            let converted = convert(point, to: host.view)
            if let hit = host.view.hitTest(converted, with: event) {
                return hit
            }
            return host.view
        }
        return super.hitTest(point, with: event)
    }
    
    func showGreyPreviewHighlight(for range: NSRange) {
        removeGreyPreviewHighlight()
        let boundingBoxes = rects(for: range)
        guard !boundingBoxes.isEmpty else { return }
        
        let greyColor = UIColor(red: 0.58, green: 0.62, blue: 0.67, alpha: 1.0)
        
        for (index, box) in boundingBoxes.enumerated() {
            let expanded = box.insetBy(dx: -2, dy: -1)
            let v = UIView()
            v.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            v.frame = expanded
            v.backgroundColor = greyColor.withAlphaComponent(0.32)
            v.layer.cornerRadius = 4
            v.layer.masksToBounds = true
            v.isUserInteractionEnabled = false
            v.transform = CGAffineTransform(scaleX: 0.001, y: 1.0)
            v.alpha = 0.0
            
            highlightsOverlay.addSubview(v)
            greyPreviewViews.append(v)
            
            let staggerDelay = Double(index) * 0.12
            UIView.animate(withDuration: 0.6, delay: staggerDelay, options: [.curveEaseInOut]) {
                v.transform = .identity
                v.alpha = 1.0
            }
        }
    }
    
    func removeGreyPreviewHighlight() {
        greyPreviewViews.forEach { $0.removeFromSuperview() }
        greyPreviewViews.removeAll()
    }
    
    @objc private func handleHighlightTap(_ gesture: UITapGestureRecognizer) {
        if pendingNoteRange != nil { return }
        let point = gesture.location(in: self)
        
        // 1. Check if tap intersects any existing highlight view frame
        for (range, views) in highlightViewsMap {
            for v in views {
                if v.frame.insetBy(dx: -6, dy: -6).contains(point) {
                    if let hr = currentHighlights.first(where: { $0.range == range }) {
                        showHighlightActionMenu(for: hr, at: point)
                        return
                    }
                }
            }
        }
        
        // 2. Check by character position
        if let pos = self.closestPosition(to: point) {
            let offset = self.offset(from: self.beginningOfDocument, to: pos)
            if let hr = currentHighlights.first(where: { offset >= $0.range.location && offset <= ($0.range.location + $0.range.length) }) {
                showHighlightActionMenu(for: hr, at: point)
                return
            }
        }
        
        // Tap was outside highlights: hide any open action menu
        hideActionMenu()
    }
    
    private func showHighlightActionMenu(for highlight: HighlightRange, at point: CGPoint) {
        hideActionMenu()
        hideCustomMenu()
        
        let boundingBoxes = rects(for: highlight.range)
        let targetBox = boundingBoxes.first(where: { $0.insetBy(dx: -4, dy: -4).contains(point) })
            ?? boundingBoxes.first
            ?? CGRect(origin: point, size: CGSize(width: 20, height: 20))
        
        if highlight.isNote {
            let noteContent = highlight.note ?? ""
            let maxAvailableWidth = min(self.bounds.width - 32, 290)
            
            // Calculate accurate dimensions for the fit-text note view capsule
            let font = UIFont(name: "InclusiveSans-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
            let horizontalPadding: CGFloat = 68 // 14 leading + 6 minSpacer + 30 btn + 4 trailing + 14 breathing room
            
            let singleLineSize = (noteContent as NSString).size(withAttributes: [.font: font])
            let singleLineWidth = ceil(singleLineSize.width)
            
            let isSingleLine = (singleLineWidth + horizontalPadding) <= maxAvailableWidth && !noteContent.contains("\n")
            
            let contentWidth: CGFloat
            let contentHeight: CGFloat
            
            if isSingleLine {
                contentWidth = max(92, singleLineWidth + horizontalPadding)
                contentHeight = 46
            } else {
                let maxTextWidth = maxAvailableWidth - horizontalPadding
                let textRect = (noteContent as NSString).boundingRect(
                    with: CGSize(width: maxTextWidth, height: 300),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                )
                let textWidth = ceil(textRect.width)
                let textHeight = ceil(textRect.height)
                contentWidth = min(maxAvailableWidth, max(120, textWidth + horizontalPadding))
                contentHeight = max(50, min(textHeight + 28, 140))
            }
            
            let isAbove = true
            let x = max(8, min(targetBox.midX - contentWidth / 2, self.bounds.width - contentWidth - 8))
            let y = targetBox.minY - contentHeight - 8
            let pointerX = targetBox.midX - x
            
            let noteView = NoteDisplayMenuView(
                noteText: noteContent,
                isSingleLine: isSingleLine,
                isAbove: isAbove,
                pointerX: pointerX,
                menuWidth: contentWidth,
                menuHeight: contentHeight,
                onDelete: { [weak self] in
                    self?.deleteHighlight(range: highlight.range)
                }
            )
            
            let host = UIHostingController(rootView: noteView)
            host.view.backgroundColor = .clear
            let frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: contentWidth, height: contentHeight))
            host.view.frame = frame
            
            host.view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            host.view.alpha = 0
            self.addSubview(host.view)
            self.activeActionHostingController = host
            
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                host.view.transform = .identity
                host.view.alpha = 1
            }
        } else {
            let deleteView = DeleteHighlightMenuView(
                onDelete: { [weak self] in
                    self?.deleteHighlight(range: highlight.range)
                }
            )
            
            let host = UIHostingController(rootView: deleteView)
            host.view.backgroundColor = .clear
            
            let menuSize = CGSize(width: 104, height: 38)
            let isAbove = true
            let x = max(8, min(targetBox.midX - menuSize.width / 2, self.bounds.width - menuSize.width - 8))
            let y = targetBox.minY - menuSize.height - 8
            let frame = CGRect(origin: CGPoint(x: x, y: y), size: menuSize)
            
            host.view.frame = frame
            host.view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            host.view.alpha = 0
            self.addSubview(host.view)
            self.activeActionHostingController = host
            
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                host.view.transform = .identity
                host.view.alpha = 1
            }
        }
    }
    
    func hideActionMenu() {
        if let host = activeActionHostingController {
            UIView.animate(withDuration: 0.2, animations: {
                host.view.alpha = 0
                host.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                host.view.removeFromSuperview()
            }
            activeActionHostingController = nil
        }
    }
    
    private func deleteHighlight(range: NSRange, notify: Bool = true) {
        hideActionMenu()
        
        if let views = highlightViewsMap.removeValue(forKey: range) {
            UIView.animate(withDuration: 0.25, animations: {
                views.forEach {
                    $0.alpha = 0
                    $0.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            }) { _ in
                views.forEach { $0.removeFromSuperview() }
            }
        }
        
        currentHighlights.removeAll(where: { $0.range == range })
        if notify {
            onDeleteHighlight?(range)
        }
    }
    
    @available(iOS 16.0, *)
    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        return UIMenu(children: []) // Suppress system edit menu
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false // Suppress copy/paste menu
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        menuWorkItem?.cancel()
        menuWorkItem = nil
        hideActionMenu()
        
        // While typing a note, don't let selection shifts hide the note composer
        if pendingNoteRange != nil {
            return
        }
        
        guard let range = textView.selectedTextRange, !range.isEmpty else {
            hideCustomMenu()
            return
        }
        
        let nsRange = textView.selectedRange
        guard nsRange.length > 0 else {
            hideCustomMenu()
            return
        }
        
        // If the custom menu is ALREADY visible, dynamically update its position immediately!
        if customMenuHostingController != nil {
            self.updateCustomMenuPosition(for: nsRange)
            return
        }
        
        // If the menu is not yet visible, wait 1.0 second after the user stops touching the selectors
        let workItem = DispatchWorkItem { [weak self, weak textView] in
            guard let self = self, let textView = textView else { return }
            guard let currentRange = textView.selectedTextRange, !currentRange.isEmpty,
                  textView.selectedRange == nsRange else {
                return
            }
            self.showCustomMenu(for: nsRange)
        }
        
        self.menuWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    func menuPosition(for range: NSRange, menuSize: CGSize) -> (frame: CGRect, isAbove: Bool, pointerMidX: CGFloat) {
        let boxes = rects(for: range)
        guard !boxes.isEmpty else {
            let fallback = CGRect(x: max(8, self.bounds.midX - menuSize.width / 2), y: 10, width: menuSize.width, height: menuSize.height)
            return (fallback, true, fallback.midX)
        }
        
        // Compute union rect encompassing all selected lines/segments
        var unionRect = boxes[0]
        for b in boxes.dropFirst() {
            unionRect = unionRect.union(b)
        }
        
        let firstBox = boxes.first ?? unionRect
        let lastBox = boxes.last ?? unionRect
        
        // 12pt vertical clearance so menu never overlaps selected text
        let clearance: CGFloat = 12
        // Always place on top to prevent iOS keyboard overlap during text entry
        let isAbove = true
        
        let targetMidX = isAbove ? firstBox.midX : lastBox.midX
        let x = max(8, min(targetMidX - menuSize.width / 2, self.bounds.width - menuSize.width - 8))
        
        let y = unionRect.minY - menuSize.height - clearance
        
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: menuSize)
        return (frame, isAbove, targetMidX)
    }
    
    func updateCustomMenuPosition(for range: NSRange) {
        if pendingNoteRange != nil { return }
        guard let host = customMenuHostingController, let vm = currentMenuViewModel else {
            showCustomMenu(for: range)
            return
        }
        self.currentMenuRange = range
        
        let menuSize = host.view.frame.size == .zero ? CGSize(width: 264, height: 46) : host.view.frame.size
        let pos = menuPosition(for: range, menuSize: menuSize)
        
        withAnimation(.easeOut(duration: 0.18)) {
            vm.isAbove = pos.isAbove
            vm.selectionMidX = pos.pointerMidX
            vm.textViewWidth = self.bounds.width
        }
        
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]) {
            host.view.frame = pos.frame
        }
    }
    
    func showCustomMenu(for range: NSRange) {
        if pendingNoteRange != nil { return }
        hideCustomMenu()
        hideActionMenu()
        
        self.currentMenuRange = range
        
        let initialSize = CGSize(width: 264, height: 46)
        let pos = menuPosition(for: range, menuSize: initialSize)
        
        let vm = MenuViewModel(
            isAbove: pos.isAbove,
            selectionMidX: pos.pointerMidX,
            textViewWidth: self.bounds.width
        )
        self.currentMenuViewModel = vm
        
        let menuView = CustomMenuView(
            viewModel: vm,
            onHighlight: { [weak self] color in
                guard let self = self else { return }
                let selRange = self.currentMenuRange ?? range
                self.addAndAnimateHighlight(range: selRange, color: color)
                self.onHighlight?(selRange, color)
                self.selectedRange = NSRange(location: selRange.location, length: 0)
                self.hideCustomMenu()
            },
            onAddNote: { [weak self] noteText in
                guard let self = self, let note = noteText, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let selRange = self.pendingNoteRange ?? self.currentMenuRange ?? range
                self.pendingNoteRange = nil
                self.removeGreyPreviewHighlight()
                let greyColor = UIColor(red: 0.58, green: 0.62, blue: 0.67, alpha: 1.0)
                self.addAndAnimateHighlight(range: selRange, color: greyColor, note: note)
                self.onAddNote?(selRange, note)
                self.selectedRange = NSRange(location: selRange.location, length: 0)
                self.hideCustomMenu()
            },
            onStartAddNote: { [weak self, weak vm] in
                guard let self = self else { return }
                let selRange = self.currentMenuRange ?? range
                guard selRange.length > 0 else { return }
                self.pendingNoteRange = selRange
                self.showGreyPreviewHighlight(for: selRange)
                
                let noteSize = CGSize(width: 285, height: 128)
                let p = self.menuPosition(for: selRange, menuSize: noteSize)
                vm?.isAbove = p.isAbove
                vm?.selectionMidX = p.pointerMidX
                vm?.textViewWidth = self.bounds.width
                
                if let window = self.window {
                    let boxes = self.rects(for: selRange)
                    if let first = boxes.first {
                        let unionRect = boxes.dropFirst().reduce(first) { $0.union($1) }
                        let globalHighlightFrame = self.convert(unionRect, to: window)
                        NotificationCenter.default.post(name: NSNotification.Name("FocusedTextInputMaxY"), object: nil, userInfo: ["maxY": globalHighlightFrame.maxY])
                    }
                }
            },
            onCancelAddNote: { [weak self, weak vm] in
                guard let self = self else { return }
                self.removeGreyPreviewHighlight()
                self.pendingNoteRange = nil
                
                let selRange = self.currentMenuRange ?? range
                let paletteSize = CGSize(width: 264, height: 46)
                let p = self.menuPosition(for: selRange, menuSize: paletteSize)
                vm?.isAbove = p.isAbove
                vm?.selectionMidX = p.pointerMidX
                vm?.textViewWidth = self.bounds.width
            },
            onSizeChange: { [weak self, weak vm] newSize in
                guard let self = self, let host = self.customMenuHostingController else { return }
                let r = self.pendingNoteRange ?? self.currentMenuRange ?? range
                let p = self.menuPosition(for: r, menuSize: newSize)
                
                withAnimation(.spring(response: 0.44, dampingFraction: 0.74, blendDuration: 0.12)) {
                    vm?.isAbove = p.isAbove
                    vm?.selectionMidX = p.pointerMidX
                    vm?.textViewWidth = self.bounds.width
                }
                
                UIView.animate(withDuration: 0.44, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0.1, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
                    host.view.frame = p.frame
                }
                
                if let r = self.pendingNoteRange, let window = self.window {
                    let boxes = self.rects(for: r)
                    if let first = boxes.first {
                        let unionRect = boxes.dropFirst().reduce(first) { $0.union($1) }
                        let globalHighlightFrame = self.convert(unionRect, to: window)
                        NotificationCenter.default.post(name: NSNotification.Name("FocusedTextInputMaxY"), object: nil, userInfo: ["maxY": globalHighlightFrame.maxY])
                    }
                }
            }
        )
        
        let host = UIHostingController(rootView: menuView)
        host.view.backgroundColor = .clear
        host.view.frame = pos.frame
        host.view.isUserInteractionEnabled = true
        host.view.clipsToBounds = false
        host.view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        host.view.alpha = 0
        self.addSubview(host.view)
        self.customMenuHostingController = host
        
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            host.view.transform = .identity
            host.view.alpha = 1
        }
    }
    
    func hideCustomMenu() {
        removeGreyPreviewHighlight()
        pendingNoteRange = nil
        currentMenuRange = nil
        customMenuHostingController?.view.removeFromSuperview()
        customMenuHostingController = nil
        currentMenuViewModel = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        highlightsOverlay.frame = self.bounds
        self.bringSubviewToFront(highlightsOverlay)
        if let host = customMenuHostingController {
            self.bringSubviewToFront(host.view)
        }
        if let host = activeActionHostingController {
            self.bringSubviewToFront(host.view)
        }
        drawHighlights()
    }
    
    func updateHighlights(_ highlights: [HighlightRange]) {
        self.currentHighlights = highlights
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func rects(for range: NSRange) -> [CGRect] {
        var results: [CGRect] = []
        
        // Method 1: TextKit 2 (iOS 15 / 16+)
        if #available(iOS 15.0, *), let tlm = self.textLayoutManager {
            let docStart = tlm.documentRange.location
            if let start = tlm.location(docStart, offsetBy: range.location),
               let end = tlm.location(start, offsetBy: range.length),
               let textRange = NSTextRange(location: start, end: end) {
                tlm.enumerateTextSegments(in: textRange, type: .standard, options: .rangeNotRequired) { _, segmentRect, _, _ in
                    if segmentRect.width > 0 && segmentRect.height > 0 {
                        results.append(segmentRect)
                    }
                    return true
                }
            }
        }
        
        // Method 2: TextKit 1 (fallback)
        if results.isEmpty {
            let lm = self.layoutManager
            let tc = self.textContainer
            let glyphRange = lm.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            lm.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, gRange, _ in
                let intersection = NSIntersectionRange(glyphRange, gRange)
                if intersection.length > 0 {
                    let box = lm.boundingRect(forGlyphRange: intersection, in: tc)
                    if box.width > 0 && box.height > 0 {
                        results.append(box)
                    }
                }
            }
        }
        
        // Method 3: UITextInput selectionRects
        if results.isEmpty {
            if let start = position(from: beginningOfDocument, offset: range.location),
               let end = position(from: start, offset: range.length),
               let textRange = textRange(from: start, to: end) {
                let selRects = selectionRects(for: textRange)
                for r in selRects {
                    if r.rect.width > 0 && r.rect.height > 0 {
                        results.append(r.rect)
                    }
                }
            }
        }
        
        return results
    }
    
    func addAndAnimateHighlight(range: NSRange, color: UIColor, note: String? = nil) {
        let hr = HighlightRange(range: range, color: color, note: note)
        currentHighlights.removeAll(where: { $0.range == range })
        currentHighlights.append(hr)
        
        if let existing = highlightViewsMap.removeValue(forKey: range) {
            existing.forEach { $0.removeFromSuperview() }
        }
        
        let boundingBoxes = rects(for: range)
        guard !boundingBoxes.isEmpty else { return }
        
        var views: [UIView] = []
        
        for (index, box) in boundingBoxes.enumerated() {
            let expanded = box.insetBy(dx: -2, dy: -1)
            
            let v = UIView()
            v.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            v.frame = expanded
            v.backgroundColor = color.withAlphaComponent(0.32)
            v.layer.cornerRadius = 4
            v.layer.masksToBounds = true
            v.isUserInteractionEnabled = false
            
            v.transform = CGAffineTransform(scaleX: 0.001, y: 1.0)
            v.alpha = 0.0
            
            highlightsOverlay.addSubview(v)
            views.append(v)
            
            let staggerDelay = Double(index) * 0.12
            
            UIView.animate(
                withDuration: 0.6,
                delay: staggerDelay,
                options: [.curveEaseInOut],
                animations: {
                    v.transform = .identity
                    v.alpha = 1.0
                },
                completion: nil
            )
        }
        
        highlightViewsMap[range] = views
    }
    
    private func drawHighlights() {
        let currentRanges = Set(currentHighlights.map { $0.range })
        let drawnRanges = Set(highlightViewsMap.keys)
        
        let added = currentHighlights.filter { !drawnRanges.contains($0.range) }
        let removed = drawnRanges.subtracting(currentRanges)
        
        for range in removed {
            if let views = highlightViewsMap.removeValue(forKey: range) {
                views.forEach { $0.removeFromSuperview() }
            }
        }
        
        for hr in added {
            let boundingBoxes = rects(for: hr.range)
            var views: [UIView] = []
            
            for box in boundingBoxes {
                let expanded = box.insetBy(dx: -2, dy: -1)
                let v = UIView()
                v.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
                v.frame = expanded
                v.backgroundColor = hr.color.withAlphaComponent(0.32)
                v.layer.cornerRadius = 4
                v.layer.masksToBounds = true
                v.isUserInteractionEnabled = false
                v.transform = .identity
                v.alpha = 1.0
                highlightsOverlay.addSubview(v)
                views.append(v)
            }
            highlightViewsMap[hr.range] = views
        }
        
        for hr in currentHighlights {
            guard let views = highlightViewsMap[hr.range] else { continue }
            let boundingBoxes = rects(for: hr.range)
            if boundingBoxes.count == views.count {
                for (i, box) in boundingBoxes.enumerated() {
                    let v = views[i]
                    if v.transform == .identity {
                        v.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
                        v.frame = box.insetBy(dx: -2, dy: -1)
                    }
                }
            }
        }
    }
}

struct SelectableTextView: UIViewRepresentable {
    var attributedText: AttributedString
    var font: UIFont
    var textColor: UIColor
    var lineSpacing: CGFloat = 6.0
    var tintColor: UIColor = .systemBlue
    @Binding var highlightedRanges: [HighlightRange]
    var isTextSelectable: Bool = true
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        var parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func handleHighlight(range: NSRange, color: UIColor) {
            let hr = HighlightRange(range: range, color: color)
            if !parent.highlightedRanges.contains(where: { $0.range == range }) {
                parent.highlightedRanges.append(hr)
            }
        }
        
        func handleAddNote(range: NSRange, note: String) {
            let greyColor = UIColor(red: 0.58, green: 0.62, blue: 0.67, alpha: 1.0)
            let hr = HighlightRange(range: range, color: greyColor, note: note)
            parent.highlightedRanges.removeAll(where: { $0.range == range })
            parent.highlightedRanges.append(hr)
        }
        
        func handleDeleteHighlight(range: NSRange) {
            parent.highlightedRanges.removeAll(where: { $0.range == range })
        }
    }
    
    func makeUIView(context: Context) -> CustomSelectableTextView {
        let textView = CustomSelectableTextView()
        textView.isEditable = false
        textView.isSelectable = isTextSelectable
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = tintColor
        textView.clipsToBounds = false
        
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let coordinator = context.coordinator
        textView.onHighlight = { [weak coordinator] range, color in
            DispatchQueue.main.async {
                coordinator?.handleHighlight(range: range, color: color)
            }
        }
        textView.onAddNote = { [weak coordinator] range, note in
            DispatchQueue.main.async {
                coordinator?.handleAddNote(range: range, note: note)
            }
        }
        textView.onDeleteHighlight = { [weak coordinator] range in
            DispatchQueue.main.async {
                coordinator?.handleDeleteHighlight(range: range)
            }
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: CustomSelectableTextView, context: Context) {
        context.coordinator.parent = self
        
        if uiView.isSelectable != isTextSelectable {
            uiView.isSelectable = isTextSelectable
        }
        
        let nsAttributedString = try? NSAttributedString(attributedText, including: \.uiKit)
        let mutableString = NSMutableAttributedString(attributedString: nsAttributedString ?? NSAttributedString())
        
        mutableString.enumerateAttributes(in: NSRange(location: 0, length: mutableString.length), options: .longestEffectiveRangeNotRequired) { attributes, range, _ in
            if attributes[.font] == nil {
                mutableString.addAttribute(.font, value: font, range: range)
            }
            if attributes[.foregroundColor] == nil {
                mutableString.addAttribute(.foregroundColor, value: textColor, range: range)
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        mutableString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutableString.length))
        
        uiView.attributedText = mutableString
        uiView.tintColor = tintColor
        
        uiView.updateHighlights(highlightedRanges)
    }
    
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CustomSelectableTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingExpandedSize.height)
        let size = uiView.sizeThatFits(fittingSize)
        return size
    }
}
