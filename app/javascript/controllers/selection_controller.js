import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "input"]
  static values = { multiple: { type: Boolean, default: true }, name: String }

  toggle(event) {
    const card = event.currentTarget
    const id = card.dataset.id

    if (this.multipleValue) {
      card.classList.toggle("selected")
      if (card.classList.contains("selected")) {
        this.addInput(id)
      } else {
        this.removeInput(id)
      }
    } else {
      this.cardTargets.forEach(c => c.classList.remove("selected"))
      this.inputTargets.forEach(i => i.remove())
      card.classList.add("selected")
      this.addInput(id)
    }
  }

  addInput(value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.nameValue
    input.value = value
    input.dataset.selectionTarget = "input"
    this.element.appendChild(input)
  }

  removeInput(value) {
    this.inputTargets
      .filter(i => i.value === value)
      .forEach(i => i.remove())
  }
}
