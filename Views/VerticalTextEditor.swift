import SwiftUI
import UIKit

/// 縦書き対応のNSLayoutManager（アンダーラインを右側に描画）
class VerticalLayoutManager: NSLayoutManager {
    override func drawUnderline(forGlyphRange glyphRange: NSRange, underlineType underlineVal: NSUnderlineStyle, baselineOffset: CGFloat, lineFragmentRect lineRect: CGRect, lineFragmentGlyphRange lineGlyphRange: NSRange, containerOrigin: CGPoint) {
        
        guard let container = textContainers.first else { return }
        
        // 文字の描画範囲を取得
        let rect = self.boundingRect(forGlyphRange: glyphRange, in: container)
        
        // 縦書きの場合：文字の右端に線を引く
        // Viewを回転させていない前提の座標計算
        var underlineRect = rect
        underlineRect.origin.x += (rect.width - 1.5) // 右側にオフセット
        underlineRect.size.width = 1.0               // 線の太さ
        
        // コンテナの原点を加算
        underlineRect.origin.x += containerOrigin.x
        underlineRect.origin.y += containerOrigin.y

        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
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
        // 1. 各コンポーネントを独立して生成
        let storage = NSTextStorage()
        let layoutManager = VerticalLayoutManager()
        let container = NSTextContainer(size: .zero)
        
        // 2. 正しい順序で接続（重要！）
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        
        // 3. このコンテナを使ってTextViewを生成
        let textView = UITextView(frame: .zero, textContainer: container)
        
        // 基本設定
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0)
        textView.textColor = .black
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        
        // 縦書きは横スクロールになるため
        textView.alwaysBounceHorizontal = true
        textView.alwaysBounceVertical = false
        
        // キーボード入力を受け取るための設定
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        
        // 通常の左揃え
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
            storage.setAttributedString(attributedString)
        }
        
        // 非同期でfirst responderにする
        DispatchQueue.main.async {
            textView.becomeFirstResponder()
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // テキストの内容が変わった場合のみ更新
        let currentText = uiView.textStorage.string
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
            
            // storageに設定（textStorageは常に存在する）
            uiView.textStorage.setAttributedString(attributedString)
            
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
            
            // textStorageから文字列を取得
            parent.text = textView.textStorage.string
            
            // カーソル位置が見えるようにスクロール
            if let selectedRange = textView.selectedTextRange {
                let cursorRect = textView.caretRect(for: selectedRange.start)
                textView.scrollRectToVisible(cursorRect, animated: true)
            }
        }
        
        // テキスト変更が許可されるか
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return true
        }
    }
}
