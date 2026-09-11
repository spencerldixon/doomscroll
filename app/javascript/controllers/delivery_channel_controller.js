import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="delivery-channel"
export default class extends Controller {
  static targets = ["panel"]

  show(event) {
    const id = event.currentTarget.dataset.id

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.channel !== id
    })
  }
}
