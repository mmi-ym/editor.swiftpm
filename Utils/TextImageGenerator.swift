import UIKit
import CoreText

class TextImageGenerator {
    
    static let pageSize = CGSize(width: 1240, height: 1748)
    
    /// 画像生成と描画された文字数を返す
    /// - Returns: (画像データ, 描画された文字数)
    static func generateBookPageImageWithCharCount(from text: String, title: String? = nil, author: String? = nil, pageNumber: Int? = nil) -> (data: Data?, charCount: Int) {
        var renderedCharCount = 0
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // 1. 背景描画
            UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            // 2. 座標系変換
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // --- 本文の描画領域の設定 ---
            let margin: CGFloat = 140
            let bodyRect = CGRect(
                x: margin,
                y: margin + 40,
                width: pageSize.width - (margin * 2),
                height: pageSize.height - (margin * 2.5)
            )
            
            let fontSize: CGFloat = 44
            let font = UIFont(name: "HiraMinProN-W3", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            
            // 3. --- 修正ポイント：縦書き用の属性設定 ---
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                // 縦書き用グリフ指定 (NSNumberの1)
                .verticalGlyphForm: NSNumber(value: 1),
                NSAttributedString.Key(rawValue: kCTVerticalFormsAttributeName as String): true
            ]
            
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            
            // 4. --- 修正ポイント：縦書き用のパス作成 ---
            // Core Textの縦書きでは、描画領域自体を「縦横入れ替えた」座標で作る必要があります
            let columnPath = CGMutablePath()
            // widthとheightを入れ替える
            let flippedRect = CGRect(x: 0, y: 0, width: bodyRect.height, height: bodyRect.width)
            columnPath.addRect(flippedRect)
            
            // 縦書き（右から左へ進む）を明示
            let frameAttributes = [
                kCTFrameProgressionAttributeName: CTFrameProgression.rightToLeft.rawValue
            ] as CFDictionary
            
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), columnPath, frameAttributes)
            
            // 5. --- 修正ポイント：描画位置の調整 ---
            // パスを回転させて元の位置（bodyRect）に合わせる
            cgContext.saveGState()
            cgContext.translateBy(x: bodyRect.origin.x, y: bodyRect.origin.y)
            // 90度回転させて縦長にする
            cgContext.rotate(by: CGFloat.pi / -2.0)
            cgContext.translateBy(x: -bodyRect.height, y: 0)
            
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            renderedCharCount = visibleRange.length
            
            CTFrameDraw(frame, cgContext)
            cgContext.restoreGState() // 回転の解除
            
            cgContext.restoreGState() // 座標系全体の解除
            
            // --- タイトル・ページ番号（以下変更なし） ---
            let subFont = UIFont(name: "HiraMinProN-W3", size: 30) ?? UIFont.systemFont(ofSize: 30)
            let subAttributes: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor.gray]
            
            if let title = title {
                let titleSize = title.size(withAttributes: subAttributes)
                title.draw(at: CGPoint(x: (pageSize.width - titleSize.width) / 2, y: 80), withAttributes: subAttributes)
            }
            
            if let author = author {
                author.draw(at: CGPoint(x: 100, y: pageSize.height - 100), withAttributes: subAttributes)
            }
            
            if let page = pageNumber {
                let pageStr = "- \(page) -"
                let pageSizeStr = pageStr.size(withAttributes: subAttributes)
                pageStr.draw(at: CGPoint(x: (pageSize.width - pageSizeStr.width) / 2, y: pageSize.height - 100), withAttributes: subAttributes)
            }
        }
        
        return (image.jpegData(compressionQuality: 0.9), renderedCharCount)
    }
    
    /// 後方互換性のための関数
    static func generateBookPageImage(from text: String, title: String? = nil, author: String? = nil, pageNumber: Int? = nil) -> Data? {
        return generateBookPageImageWithCharCount(from: text, title: title, author: author, pageNumber: pageNumber).data
    }
}
