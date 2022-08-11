import { Controller } from "@hotwired/stimulus"
import ModalController from "./modal_controller"

export default class extends Controller {
    static targets = ["modal"]
    declare readonly modalTarget: HTMLElement

    open() {
        const modalController = this.application.getControllerForElementAndIdentifier(this.modalTarget, "modal") as ModalController
        modalController.open()
    }
}
