import SwiftUI
import UIKit

struct ImageConversionSheet: View {
    @Binding var isPresented: Bool
    let text: String
    let novelTitle: String?  // 作品タイトル（オプション）
    let chapterTitle: String?  // 章タイトル（オプション）
    
    @State private var generatedImages: [UIImage] = []  // 複数ページ対応
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    
    // 画像生成オプション
    @State private var includeNovelTitle = true
    @State private var includeChapterTitle = true
    @State private var authorName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    ProgressView("画像を生成中...")
                        .padding()
                } else if !generatedImages.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            // ページ数表示
                            Text("\(generatedImages.count)ページ生成されました")
                                .font(.headline)
                                .padding(.top)
                            
                            // プレビュー（全ページ）
                            ForEach(Array(generatedImages.enumerated()), id: \.offset) { index, image in
                                VStack(spacing: 8) {
                                    Text("ページ \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 400)
                                        .border(Color.gray.opacity(0.3), width: 1)
                                }
                            }
                            .padding(.horizontal)
                            
                            // 共有ボタン
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("画像を共有", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("再試行") {
                            generateImage()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("文庫本風の画像を生成します")
                            .font(.headline)
                        
                        Text("選択されたテキストが縦書きで配置された\n文庫本ページの画像を作成します。")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // 設定フォーム
                        Form {
                            Section("ヘッダー設定") {
                                if let novelTitle = novelTitle {
                                    Toggle(isOn: $includeNovelTitle) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("作品タイトルを挿入")
                                            Text(novelTitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                if let chapterTitle = chapterTitle {
                                    Toggle(isOn: $includeChapterTitle) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("章タイトルを挿入")
                                            Text(chapterTitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            Section("作者情報") {
                                TextField("作者名", text: $authorName)
                                    .textContentType(.name)
                            }
                        }
                        .frame(height: 250)
                        .scrollContentBackground(.hidden)
                        
                        Button {
                            generateImage()
                        } label: {
                            Label("画像を生成", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("画像に変換")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !generatedImages.isEmpty {
                    ShareSheet(items: generatedImages)
                }
            }
        }
        .onAppear {
            // テキストが空の場合はエラー表示
            if text.isEmpty {
                errorMessage = "変換するテキストがありません"
            }
        }
    }
    
    private func generateImage() {
        guard !text.isEmpty else {
            errorMessage = "変換するテキストがありません"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        generatedImages = []
        
        // タイトル情報を組み立て
        let headerTitle: String? = {
            var titles: [String] = []
            if includeNovelTitle, let novelTitle = novelTitle {
                titles.append(novelTitle)
            }
            if includeChapterTitle, let chapterTitle = chapterTitle {
                titles.append(chapterTitle)
            }
            return titles.isEmpty ? nil : titles.joined(separator: " / ")
        }()
        
        // 非同期で画像生成
        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []
            let author = authorName.isEmpty ? nil : authorName
            
            // 全体を描画文字列として管理
            var drawingString = text
            var pageNumber = 1
            
            // drawingStringが空になるまで繰り返す
            while !drawingString.isEmpty {
                // drawingStringの先頭から1ページ描画し、描画された文字数を取得
                let result = TextImageGenerator.generateBookPageImageWithCharCount(
                    from: drawingString,
                    title: headerTitle,
                    author: author,
                    pageNumber: pageNumber
                )
                
                // 画像が生成できた場合
                if let imageData = result.data, let image = UIImage(data: imageData) {
                    images.append(image)
                    
                    // 描画された文字数分だけdrawingStringから除去
                    let renderedCharCount = result.charCount
                    if renderedCharCount > 0 && renderedCharCount <= drawingString.count {
                        let startIndex = drawingString.index(drawingString.startIndex, offsetBy: renderedCharCount)
                        drawingString = String(drawingString[startIndex...])
                    } else {
                        // 描画できる文字がない、または異常値の場合は終了
                        break
                    }
                } else {
                    // 画像生成に失敗した場合は終了
                    break
                }
                
                pageNumber += 1
                
                // 安全のため、30ページを超えたら停止
                if pageNumber > 30 {
                    break
                }
            }
            
            DispatchQueue.main.async {
                if !images.isEmpty {
                    self.generatedImages = images
                    self.isGenerating = false
                } else {
                    self.errorMessage = "画像の生成に失敗しました"
                    self.isGenerating = false
                }
            }
        }
    }
}

// 共有シート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
