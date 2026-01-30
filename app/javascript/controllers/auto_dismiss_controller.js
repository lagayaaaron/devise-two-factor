// app/javascript/controllers/auto_dismiss_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.classList.add('opacity-0', 'transition-opacity', 'duration-500')
      setTimeout(() => {
        this.element.remove()
      }, 500)
    }, 5000) // Dismiss after 5 seconds
  }
}