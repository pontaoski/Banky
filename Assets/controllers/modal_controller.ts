import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    open() {
        this.element.classList.add("visible")
    }
    close() {
        this.element.classList.remove("visible")
    }
}
