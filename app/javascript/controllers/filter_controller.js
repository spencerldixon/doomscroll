import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item"]

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.itemTargets.forEach(item => {
      const name = (item.dataset.name || "").toLowerCase()
      const description = (item.dataset.description || "").toLowerCase()
      item.hidden = query.length > 0 && !name.includes(query) && !description.includes(query)
    })
  }
}
