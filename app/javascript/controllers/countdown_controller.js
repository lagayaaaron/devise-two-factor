// app/javascript/controllers/countdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = {
    seconds: Number
  }

  connect() {
    if (this.secondsValue > 0) {
      this.startCountdown()
    }
  }

  disconnect() {
    this.stopCountdown()
  }

  startCountdown() {
    this.updateDisplay()
    
    this.timer = setInterval(() => {
      this.secondsValue--
      
      if (this.secondsValue <= 0) {
        this.stopCountdown()
        this.handleExpiry()
      } else {
        this.updateDisplay()
      }
    }, 1000)
  }

  stopCountdown() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  updateDisplay() {
    if (this.hasDisplayTarget) {
      const minutes = Math.floor(this.secondsValue / 60)
      const seconds = this.secondsValue % 60
      this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
    }
  }

  handleExpiry() {
    // Redirect to login page
    window.location.href = '/users/sign_in'
  }
}