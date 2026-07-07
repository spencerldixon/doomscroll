import { Controller } from "@hotwired/stimulus"

// Filters items by free-text query (data-name/data-description) and/or
// category pills (data-category). Both conditions combine when present.
export default class extends Controller {
  static targets = ["input", "item", "tab"]
  static values = { category: String }

  connect() {
    this.category = this.categoryValue || ""
    this.apply()
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

  // Stamp the currently selected category onto a feed card's subscribe/
  // unsubscribe form before Turbo reads its FormData, so the full-page
  // redirect back to Discover can restore the same filter instead of
  // resetting to "All". Must run on the native "submit" event (not
  // turbo:submit-start) since Turbo snapshots FormData before that fires.
  preserveCategory(event) {
    if (!this.category) return
    const form = event.target
    let input = form.querySelector('input[name="category"]')
    if (!input) {
      input = document.createElement("input")
      input.type = "hidden"
      input.name = "category"
      form.appendChild(input)
    }
    input.value = this.category
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
