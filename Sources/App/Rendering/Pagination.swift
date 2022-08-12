import Leaf
import Foundation

struct PaginationTag: LeafTag, UnsafeUnescapedLeafTag {
    struct PaginationError: Error { }
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let metadata = ctx.parameters[0].dictionary else {
            throw PaginationError()
        }
        guard let page = metadata["page"]?.int else {
            throw PaginationError()
        }
        guard let per = metadata["per"]?.int else {
            throw PaginationError()
        }
        guard let total = metadata["total"]?.int else {
            throw PaginationError()
        }
        let letsShow = 5

        let pageCount = Int(ceil(Float(total) / Float(per)))

        var str = #"<div class="flex flex-row rounded border border-cloud-400 px-6 py-4 space-x-5">"#

        if pageCount <= letsShow {
            for i in 1...pageCount {
                str += #"<a class="block" href="?page=\#(i)"> \#(i) </a>"#
            }
        } else {
            if page-2 > 1 {
                str += #"<a class="block" href="?page=1"> 1 </a>"#
                str += #"<span>...</span>"#
            }
            for i in max(page-2, 1)...min(page+2, pageCount) {
                str += #"<a class="block" href="?page=\#(i)"> \#(i) </a>"#
            }
            if page+2 < pageCount {
                str += #"<span>...</span>"#
                str += #"<a class="block" href="?page=\#(pageCount)"> \#(pageCount) </a>"#
            }
        }

        str += "</div>"

        return LeafData.string(str)
    }
}
