// app/javascript/controllers/otp_input_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitBtn", "backupCodeForm"]

  connect() {
    console.log("OTP Input controller connected")
  }

  formatInput(event) {
    // Only allow numbers
    const value = event.target.value.replace(/\D/g, '')
    event.target.value = value
    
    // Auto-submit when 6 digits are entered
    if (value.length === 6) {
      this.submitBtnTarget.focus()
    }
  }

  handleEnter(event) {
    if (event.key === 'Enter' && event.target.value.length === 6) {
      event.preventDefault()
      this.submitBtnTarget.click()
    }
  }

  showBackupCode(event) {
    event.preventDefault()
    this.backupCodeFormTarget.classList.remove('hidden')
    this.inputTarget.placeholder = "Enter backup code"
    this.inputTarget.maxLength = 10
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}