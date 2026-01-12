import UIKit
import CoreText

class TextImageGenerator {
    static let pageSize = CGSize(width: 1240, height: 1748)

    static func generateBookPageImageWithCharCount(from text: String, title: String? = nil, author: String? = nil, pageNumber: Int? = nil) -> (data: Data?, charCount: Int) {
        
        // レンダリング形式をメモリ節約モードに設定
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: pageSize, format: format)
        var renderedCharCount = 0
        
        let imageData = renderer.jpegData(withCompressionQuality: 0.8) { context in
            let cgContext = context.cgContext
            
            // 背景描画
            UIColor(red: 0.99, green: 0.98, blue: 0.97, alpha: 1.0).setFill()
            cgContext.fill(CGRect(origin: .zero, size: pageSize))
            
            // --- 本文の描画 ---
            let margin: CGFloat = 140
            let bodyRect = CGRect(
                x: margin,
                y: margin + 40,
                width: pageSize.width - (margin * 2),
                height: pageSize.height - (margin * 2.5)
            )
            
            let fontSize: CGFloat = 44
            let font = UIFont(name: "HiraMinProN-W3", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .verticalGlyphForm: NSNumber(value: 1)
            ]
            
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
            
            // Core Text用の座標系に変換
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // 縦書き用のパスを作成（widthとheightを入れ替え）
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: bodyRect.height, height: bodyRect.width))
            
            let frameAttrs = [kCTFrameProgressionAttributeName: CTFrameProgression.rightToLeft.rawValue] as CFDictionary
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, frameAttrs)
            
            // 描画位置を調整
            cgContext.translateBy(x: bodyRect.origin.x, y: bodyRect.origin.y)
            cgContext.rotate(by: -.pi / 2)
            cgContext.translateBy(x: -bodyRect.height, y: 0)
            
            renderedCharCount = CTFrameGetVisibleStringRange(frame).length
            CTFrameDraw(frame, cgContext)
            
            cgContext.restoreGState()
            
            // --- ヘッダー・フッター描画（UIKit座標系） ---
            let subFont = UIFont(name: "HiraMinProN-W3", size: 30) ?? UIFont.systemFont(ofSize: 30)
            let subAttributes: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor.gray
            ]
            
            // タイトル (ヘッダー中央)
            if let title = title {
                let titleSize = title.size(withAttributes: subAttributes)
                title.draw(at: CGPoint(x: (pageSize.width - titleSize.width) / 2, y: 80), withAttributes: subAttributes)
            }
            
            // 作者名 (フッター左下)
            if let author = author {
                author.draw(at: CGPoint(x: 100, y: pageSize.height - 100), withAttributes: subAttributes)
            }
            
            // ページ番号 (フッター中央下)
            if let page = pageNumber {
                let pageStr = "- \(page) -"
                let pageSizeStr = pageStr.size(withAttributes: subAttributes)
                pageStr.draw(at: CGPoint(x: (pageSize.width - pageSizeStr.width) / 2, y: pageSize.height - 100), withAttributes: subAttributes)
            }
        }
        
        return (imageData, renderedCharCount)
    }
    
    /// 後方互換性のための関数
    static func generateBookPageImage(from text: String, title: String? = nil, author: String? = nil, pageNumber: Int? = nil) -> Data? {
        return generateBookPageImageWithCharCount(from: text, title: title, author: author, pageNumber: pageNumber).data
    }
}
