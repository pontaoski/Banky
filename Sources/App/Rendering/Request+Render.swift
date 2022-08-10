import Vapor
import Leaf

extension Application.Views.Provider {
    public static var wrappedLeaf: Self {
        .init {
            $0.views.use {
                WrappedRenderer(inner: $0.leaf.renderer)
            }
        }
    }
}
