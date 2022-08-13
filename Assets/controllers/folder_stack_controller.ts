import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
    push(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement

        const id = el.dataset["id"]
        const src = el.href

        const srcAttr = document.createAttribute("src")
        srcAttr.value = src

        const idAttr = document.createAttribute("id")
        idAttr.value = id

        const it = document.createElement("turbo-frame")
        it.attributes.setNamedItem(srcAttr)
        it.attributes.setNamedItem(idAttr)
        it.classList.add("folder")
        it.classList.add("folder-nest")

        this.element.appendChild(it)

        Turbo.visit(src)
    }
    pop(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement
        const id = el.dataset["id"]
        let rem: HTMLElement
        
        while (rem = this.element.lastElementChild as HTMLElement) {
            if (rem.getAttribute("id") === id || rem.getAttribute("src") === el.href || rem === this.element.firstElementChild) {
                Turbo.visit(el.href)
                break
            } else {
                this.element.removeChild(rem)
            }
        }
    }
}
