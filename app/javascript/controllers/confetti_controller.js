import { Controller } from "@hotwired/stimulus"
import confetti from "@hiseb/confetti"

export default class extends Controller {
  connect() {
    confetti({ count: 150, velocity: 250 })
  }
}
