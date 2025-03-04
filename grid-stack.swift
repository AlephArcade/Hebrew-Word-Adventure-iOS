import SwiftUI

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content
    
    init(rows: Int = 2, columns: Int = 2, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
    }
    
    init(gridSize: Int, @ViewBuilder content: @escaping () -> Content) where Content == ForEach<Range<Int>, Int, Button<ZStack<TupleView<(Text, Optional<ZStack<TupleView<(Text, Circle)>>>)>>>> {
        self.rows = gridSize
        self.columns = gridSize
        self.content = { _, _ in content() }
    }
    
    var body: some View {
        VStack {
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<columns, id: \.self) { column in
                        content(row, column)
                    }
                }
            }
        }
    }
}
