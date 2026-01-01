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
            let margin: CGFloat = 120  // 上下左右のマージン
            let textRect = CGRect(
                x: margin,
                y: margin,
                width: pageSize.width - (margin * 2),
                height: pageSize.height - (margin * 2)
            )
            
            // フォント設定（縦書き用）
            let fontSize: CGFloat = 42
            let font = UIFont(name: "HiraMinProN-W3", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            
            // 行間設定
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 20
            
            // 縦書き属性
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle,
                .verticalGlyphForm: true
            ]
            
            // テキストを描画（縦書き）
            drawVerticalText(text, in: textRect, with: attributes, context: context.cgContext)
        }
        
        // JPEGデータに変換（品質: 0.9）
        return image.jpegData(compressionQuality: 0.9)
    }
    
    /// 縦書きテキストを描画
    private static func drawVerticalText(_ text: String, in rect: CGRect, with attributes: [NSAttributedString.Key: Any], context: CGContext) {
        context.saveGState()
        
        // 座標系を回転（縦書き用）
        context.translateBy(x: rect.maxX, y: rect.minY)
        context.rotate(by: .pi / 2)
        
        // 回転後の矩形
        let rotatedRect = CGRect(
            x: 0,
            y: 0,
            width: rect.height,
            height: rect.width
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
