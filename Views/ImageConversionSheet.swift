import SwiftUI
import UIKit

struct ImageConversionSheet: View {
    @Binding var isPresented: Bool
    let text: String
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    ProgressView("画像を生成中...")
                        .padding()
                } else if let image = generatedImage {
                    ScrollView {
                        VStack(spacing: 16) {
                            // プレビュー
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 500)
                                .border(Color.gray.opacity(0.3), width: 1)
                                .padding()
                            
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
                if let image = generatedImage {
                    ShareSheet(items: [image])
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
        
        // 非同期で画像生成
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = TextImageGenerator.generateBookPageImage(from: text),
               let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.generatedImage = image
                    self.isGenerating = false
                }
            } else {
                DispatchQueue.main.async {
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
