import UIKit

/// 文庫本風のテキスト画像生成
class TextImageGenerator {
    
    /// 文庫本のページサイズ（A6サイズ、300dpi）
    /// 実際の文庫本: 105mm × 148mm
    static let pageSize = CGSize(width: 1240, height: 1748)
    
    /// テキストを文庫本風の画像に変換
    /// - Parameter text: 変換するテキスト
    /// - Returns: 生成されたJPEG画像データ
    static func generateBookPageImage(from text: String) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            // 背景色（クリーム色の紙）
            UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            // テキスト領域の設定
            let cgContext = context.gcContext
            cgContext.translateBy(x: 0, y:imageSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)

            // 1. 属性津き文字列の作成
            let paragraphStyle = NSMutableParagraphStyle()
            // フォント設定（縦書き用）
            let fontSize: CGFloat = 42

            let font = UIFont(name: "HiraMinProN-W3", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true  // 縦書きグリフ形式
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)

            let renderRect = CGRect(x: 100, y: 150, width: imageSize.width - 200, height: imageSize.height - 300)
            let path = CGPath(rect: renderRect, transform: nil)
            
            // 行間設定
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 10
            paragraphStyle.alignment = .left
            
            // 縦書き属性
            let frameAttributes = [
                kCTFrameProgressionAttributeName: CTFrameProgression.rightToLeft.rawValue
            ] as CFDictionary
            let frame = CTFramesetter, CFRangeMake(0, attrString.length), path, frameAttributes)
            // テキストを描画（縦書き）
            CTFrameDraw(frame, cgContext)
        }
        
        // JPEGデータに変換（品質: 0.9）
        return image.jpegData(compressionQuality: 0.9)
    }
    
    /// 縦書きテキストを描画（+90度回転方式）
    private static func drawVerticalText(_ text: String, in rect: CGRect, with attributes: [NSAttributedString.Key: Any], context: CGContext) {
        context.saveGState()
        
        // 座標系を+90度回転（時計回り）して縦書きに
        // 右上を起点にするため、まず右上に移動してから回転
        context.translateBy(x: rect.maxX, y: rect.minY)
        context.rotate(by: .pi / 2)  // +90度（時計回り）
        
        // 回転後の矩形（幅と高さが入れ替わる）
        let rotatedRect = CGRect(
            x: 0,
            y: 0,
            width: rect.height,  // 元の高さが新しい幅
            height: rect.width   // 元の幅が新しい高さ
        )
        
        // テキストを描画
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rotatedRect)
        
        context.restoreGState()
    }
    
    /// 画像をファイルに保存
    /// - Parameters:
    ///   - imageData: 画像データ
    ///   - filename: ファイル名（拡張子なし）
    /// - Returns: 保存されたファイルのURL
    static func saveImage(_ imageData: Data, filename: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentsDirectory?.appendingPathComponent("\(filename).jpg")
        
        guard let url = fileURL else { return nil }
        
        do {
            try imageData.write(to: url)
            return url
        } catch {
            print("画像の保存に失敗しました: \(error)")
            return nil
        }
    }
}
