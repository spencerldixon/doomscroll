import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]
  static values = { deadline: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const diff = new Date(this.deadlineValue) - new Date()
    if (diff <= 0) {
      this.daysTarget.textContent = "00"
      this.hoursTarget.textContent = "00"
      this.minutesTarget.textContent = "00"
      this.secondsTarget.textContent = "00"
      return
    }
    const d = Math.floor(diff / 86400000)
    const h = Math.floor((diff % 86400000) / 3600000)
    const m = Math.floor((diff % 3600000) / 60000)
    const s = Math.floor((diff % 60000) / 1000)
    this.daysTarget.textContent    = String(d).padStart(2, "0")
    this.hoursTarget.textContent   = String(h).padStart(2, "0")
    this.minutesTarget.textContent = String(m).padStart(2, "0")
    this.secondsTarget.textContent = String(s).padStart(2, "0")
  }
}
