import SwiftUI
import UIKit

/// 縦書きテキストエディタ
struct VerticalTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0)
        textView.textColor = .black
        textView.isScrollEnabled = true
        
        // 縦書き設定（+90度回転 = 時計回り）
        textView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        // フォント設定
        let font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
        
        // 縦書き用の属性を設定
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byCharWrapping  // 文字単位の折り返し
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .verticalGlyphForm: true  // 縦書き用のグリフ形式
        ]
        
        textView.typingAttributes = attributes
        
        // 未確定テキストのスタイル設定（初期設定）
        textView.markedTextStyle = [
            NSAttributedString.Key.backgroundColor: UIColor.systemBlue.withAlphaComponent(0.2)
        ]
        
        // 折り返しを文字単位に設定
        textView.textContainer.lineBreakMode = .byCharWrapping
        
        // パディング設定
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // 初期テキストがある場合は属性付きで設定
        if !text.isEmpty {
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            textView.attributedText = attributedString
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // テキストの内容が変わった場合のみ更新
        let currentText = uiView.attributedText?.string ?? ""
        if currentText != text {
            let font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byCharWrapping  // 文字単位の折り返し
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            
            // カーソル位置を保存
            let selectedRange = uiView.selectedRange
            
            uiView.attributedText = attributedString
            
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
        
        init(_ parent: VerticalTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
