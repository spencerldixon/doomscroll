import { Controller } from "@hotwired/stimulus"

// Filters items by free-text query (data-name/data-description) and/or
// category pills (data-category). Both conditions combine when present.
export default class extends Controller {
  static targets = ["input", "item", "tab"]

  connect() {
    this.category = ""
  }

  filter() {
    this.apply()
  }

  selectCategory(event) {
    this.category = event.currentTarget.dataset.category || ""
    this.tabTargets.forEach(tab => {
      const active = tab === event.currentTarget
      tab.classList.toggle("btn-sm-primary", active)
      tab.classList.toggle("btn-sm-outline", !active)
      tab.setAttribute("aria-pressed", active)
    })
    this.apply()
  }

  apply() {
    const query = this.hasInputTarget ? this.inputTarget.value.toLowerCase() : ""

    this.itemTargets.forEach(item => {
      const name = (item.dataset.name || "").toLowerCase()
      const description = (item.dataset.description || "").toLowerCase()
      const matchesQuery = query.length === 0 || name.includes(query) || description.includes(query)
      const matchesCategory = this.category === "" || item.dataset.category === this.category
      item.hidden = !(matchesQuery && matchesCategory)
    })
  }
}
