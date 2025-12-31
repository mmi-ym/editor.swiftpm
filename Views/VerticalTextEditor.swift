import SwiftUI
import UIKit

/// 縦書き対応のUITextView（未確定文字のアンダーバーを右に表示）
class VerticalUITextView: UITextView {
    override var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            // 未確定文字（変換中の文字）のスタイルを取得
            let style = super.markedTextStyle ?? [:]
            var modifiedStyle = style
            
            // 右揃えのparagraphStyleを設定
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            paragraphStyle.baseWritingDirection = .rightToLeft
            modifiedStyle[.paragraphStyle] = paragraphStyle
            
            return modifiedStyle
        }
        set {
            super.markedTextStyle = newValue
        }
    }
}

/// 縦書きテキストエディタ
struct VerticalTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> VerticalUITextView {
        let textView = VerticalUITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0)
        textView.textColor = .black
        textView.isScrollEnabled = true
        
        // 縦書き設定（+90度回転 = 時計回り）
        textView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        // 書字方向を右から左に設定（未確定文字のアンダーバーが右に表示される）
        textView.textAlignment = .right
        
        // フォント設定
        let font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
        
        // 縦書き用の属性を設定
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .rightToLeft
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .verticalGlyphForm: true  // 縦書き用のグリフ形式
        ]
        
        textView.typingAttributes = attributes
        
        // パディング設定
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // 初期テキストがある場合は属性付きで設定
        if !text.isEmpty {
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            textView.attributedText = attributedString
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: VerticalUITextView, context: Context) {
        // テキストの内容が変わった場合のみ更新
        let currentText = uiView.attributedText?.string ?? ""
        if currentText != text {
            let font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            paragraphStyle.baseWritingDirection = .rightToLeft
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            
            // カーソル位置を保存
            let selectedRange = uiView.selectedRange
            
            // 更新フラグを設定して無限ループを防ぐ
            context.coordinator.isUpdating = true
            uiView.attributedText = attributedString
            context.coordinator.isUpdating = false
            
            // カーソル位置を復元（範囲チェック）
            if selectedRange.location <= text.count {
                uiView.selectedRange = selectedRange
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: VerticalTextEditor
        var isUpdating = false
        
        init(_ parent: VerticalTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // プログラムからの更新中は無視
            guard !isUpdating else { return }
            
            // attributedTextから文字列を取得
            parent.text = textView.attributedText?.string ?? ""
            
            // カーソル位置が見えるようにスクロール
            if let selectedRange = textView.selectedTextRange {
                let cursorRect = textView.caretRect(for: selectedRange.start)
                textView.scrollRectToVisible(cursorRect, animated: true)
            }
        }
    }
}
