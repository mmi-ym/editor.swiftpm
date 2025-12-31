import SwiftUI
import UIKit

/// 縦書きテキストエディタ
struct VerticalTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont(name: "HiraMinProN-W3", size: 20) ?? UIFont.systemFont(ofSize: 20)
        textView.backgroundColor = UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0)
        textView.textColor = .black
        
        // 縦書き設定
        textView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        textView.isScrollEnabled = true
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
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
