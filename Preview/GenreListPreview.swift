import SwiftUI

// プレビュー用のモックデータを含むView
struct GenreListPreview: View {
    var body: some View {
        NavigationView {
            List {
                // ファンタジージャンル
                GenrePreviewRow(
                    name: "ファンタジー",
                    color: Color(red: 1.0, green: 0.42, blue: 0.42),
                    novelCount: 5
                )
                
                // SFジャンル
                GenrePreviewRow(
                    name: "SF",
                    color: Color(red: 0.31, green: 0.80, blue: 0.77),
                    novelCount: 3
                )
                
                // ミステリージャンル
                GenrePreviewRow(
                    name: "ミステリー",
                    color: Color(red: 0.58, green: 0.88, blue: 0.83),
                    novelCount: 2
                )
                
                // 恋愛ジャンル
                GenrePreviewRow(
                    name: "恋愛",
                    color: Color.pink,
                    novelCount: 8
                )
                
                // ホラージャンル
                GenrePreviewRow(
                    name: "ホラー",
                    color: Color.purple,
                    novelCount: 1
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ジャンル一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                    } label: {
                        Label("執筆記録", systemImage: "calendar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct GenrePreviewRow: View {
    let name: String
    let color: Color
    let novelCount: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // カラーインジケーター
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "folder.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text("\(novelCount)作品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GenreListPreview()
}
