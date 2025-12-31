import SwiftUI
import UIKit

/// 縦書き対応のNSLayoutManager（アンダーラインを右側に描画）
class VerticalLayoutManager: NSLayoutManager {
    override func drawUnderline(forGlyphRange glyphRange: NSRange, underlineType underlineVal: NSUnderlineStyle, baselineOffset: CGFloat, lineFragmentRect lineRect: CGRect, lineFragmentGlyphRange lineGlyphRange: NSRange, containerOrigin: CGPoint) {
        
        // 縦書きの場合のみ処理をカスタマイズ
        // (TextView側で文字の向きを縦にしている前提)
        
        let firstGlyphIndex = glyphRange.location
        let lastGlyphIndex = NSMaxRange(glyphRange) - 1
        
        let firstRect = self.boundingRect(forGlyphRange: NSRange(location: firstGlyphIndex, length: 1), in: textContainers.first!)
        let lastRect = self.boundingRect(forGlyphRange: NSRange(location: lastGlyphIndex, length: 1), in: textContainers.first!)
        
        // アンダーラインの描画範囲を計算
        // 通常は文字の下（横書きの場合）だが、縦書きでは文字の右側に線を引くように調整します
        // デフォルトでは左側に引かれるため、widthの右端にオフセットさせます
        var underlineRect = firstRect.union(lastRect)
        underlineRect.origin.x += (underlineRect.width - 1.0) // 1.0は線の太さを固定
        underlineRect.size.width = 1.0 // 線の太さを固定
        
        // コンテナの原点を加算
        underlineRect.origin.x += containerOrigin.x
        underlineRect.origin.y += containerOrigin.y
        
        // 描画
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            // 未確定文字列らしい色（Apple標準に近い青など）を指定
            // 属性文字から色を取得して使うこともできます
            context.setFillColor(UIColor.systemBlue.cgColor)
            context.fill(underlineRect)
            context.restoreGState()
        }
    }
}

/// 縦書きテキストエディタ
struct VerticalTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        // カスタムLayoutManagerを使用
        let layoutManager = VerticalLayoutManager()
        let textContainer = NSTextContainer()
        let textStorage = NSTextStorage()
        
        textContainer.lineFragmentPadding = 0
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let textView = UITextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0)
        textView.textColor = .black
        textView.isScrollEnabled = true
        
        // 縦書き設定（+90度回転 = 時計回り）
        textView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        // 通常の左揃え（回転後は上揃えになる）
        textView.textAlignment = .left
        
        // フォント設定
        let font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
        
        // 縦書き用の属性を設定
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
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
            let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
            textStorage.setAttributedString(attributedString)
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
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true
            ]
            
            let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
            
            // カーソル位置を保存
            let selectedRange = uiView.selectedRange
            
            // 更新フラグを設定して無限ループを防ぐ
            context.coordinator.isUpdating = true
            
            // textStorageに設定
            if let textStorage = uiView.textStorage {
                textStorage.setAttributedString(attributedString)
            } else {
                uiView.attributedText = attributedString
            }
            
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
