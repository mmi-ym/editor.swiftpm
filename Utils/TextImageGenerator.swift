import UIKit
import CoreText

class TextImageGenerator {
    
    static let pageSize = CGSize(width: 1240, height: 1748)
    
    static func generateBookPageImage(from text: String, title: String? = nil, pageNumber: Int? = nil) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // 1. 背景描画 (クリーム色)
            UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            // 2. Core Text用の座標系変換 (左下原点へ)
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // --- 本文の描画 ---
            let margin: CGFloat = 140
            let bodyRect = CGRect(
                x: margin,
                y: margin + 40, // 下側の余白（ページ番号用）
                width: pageSize.width - (margin * 2),
                height: pageSize.height - (margin * 2.5) // 上側の余白（タイトル用）
            )
            
            let fontSize: CGFloat = 44
            let font = UIFont(name: "HiraMinProN-W3", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            
            // 行間などのスタイル設定
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 12
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true // 縦書き用グリフ（句読点などの位置）
            ]
            
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            let path = CGPath(rect: bodyRect, transform: nil)
            
            // 縦書き（右から左へ行が進む）設定
            let frameAttributes = [
                kCTFrameProgressionAttributeName: CTFrameProgression.rightToLeft.rawValue
            ] as CFDictionary
            
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, frameAttributes)
            CTFrameDraw(frame, cgContext)
            
            cgContext.restoreGState() // 座標系を一旦UIKit（左上原点）に戻す
            
            // --- タイトル・ページ番号の描画 (UIKitの標準描画を使用) ---
            let subFont = UIFont(name: "HiraMinProN-W3", size: 30) ?? UIFont.systemFont(ofSize: 30)
            let subAttributes: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor.gray
            ]
            
            // タイトルの描画 (ヘッダー中央)
            if let title = title {
                let titleSize = title.size(withAttributes: subAttributes)
                title.draw(at: CGPoint(x: (pageSize.width - titleSize.width) / 2, y: 80), withAttributes: subAttributes)
            }
            
            // ページ番号の描画 (フッター中央)
            if let page = pageNumber {
                let pageStr = "- \(page) -"
                let pageSizeStr = pageStr.size(withAttributes: subAttributes)
                pageStr.draw(at: CGPoint(x: (pageSize.width - pageSizeStr.width) / 2, y: pageSize.height - 100), withAttributes: subAttributes)
            }
        }
        
        return image.jpegData(compressionQuality: 0.9)
    }
}
