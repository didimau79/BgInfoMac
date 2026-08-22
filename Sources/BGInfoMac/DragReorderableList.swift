import SwiftUI
import UniformTypeIdentifiers

struct ReorderDropDelegate<Item: Identifiable & Equatable>: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    @Binding var draggingItem: Item?

    func dropEntered(info: DropInfo) {
        guard let draggingItem, draggingItem != item,
              let fromIndex = items.firstIndex(of: draggingItem),
              let toIndex = items.firstIndex(of: item) else { return }

        if items[toIndex] != draggingItem {
            withAnimation {
                items.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}

/// Modificador que convierte la vista a la que se aplica (normalmente solo
/// el ícono de agarre) en el disparador del drag de este item — separado a
/// propósito del resto del renglón. Si el `.onDrag` cubriera todo el
/// renglón, una lista anidada dentro de otra (como los campos dentro de
/// cada sección) quedaría con su gesto de arrastre "tapado" por el de la
/// lista exterior, y el reordenamiento interno dejaría de funcionar.
struct DragSourceModifier<Item: Identifiable>: ViewModifier {
    let item: Item
    @Binding var draggingItem: Item?

    func body(content: Content) -> some View {
        content.onDrag {
            draggingItem = item
            return NSItemProvider(object: NSString(string: String(describing: item.id)))
        }
    }
}

struct DragReorderableList<Item: Identifiable & Equatable, RowContent: View>: View {
    @Binding var items: [Item]
    @State private var draggingItem: Item?
    let rowContent: (Binding<Item>, DragSourceModifier<Item>) -> RowContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach($items) { $item in
                rowContent($item, DragSourceModifier(item: item, draggingItem: $draggingItem))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(draggingItem == item ? 0.4 : 1.0)
                    .onDrop(of: [.text], delegate: ReorderDropDelegate(item: item, items: $items, draggingItem: $draggingItem))
            }
        }
    }
}

struct DragHandle: View {
    var body: some View {
        Image(systemName: "line.3.horizontal")
            .foregroundColor(.secondary)
            .imageScale(.small)
    }
}
