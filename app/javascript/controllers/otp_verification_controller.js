// app/javascript/controllers/otp_verification_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitBtn", "label", "hint"]
  static values = {
    cooldown: Number
  }

  connect() {
    console.log("OTP Verification controller connected")
    this.inputTarget.focus()
    this.isBackupMode = false
  }

  formatInput(event) {
    let value = event.target.value.replace(/\s+/g, '') // Remove spaces
    
    if (this.isBackupMode) {
      // Backup codes are alphanumeric, 10 characters
      value = value.toUpperCase().slice(0, 10)
    } else {
      // OTP codes are numeric, 6 digits
      value = value.replace(/\D/g, '').slice(0, 6)
    }
    
    event.target.value = value
    
    // Auto-focus submit button when complete
    const requiredLength = this.isBackupMode ? 10 : 6
    if (value.length === requiredLength) {
      this.submitBtnTarget.focus()
    }
  }

  handleEnter(event) {
    const requiredLength = this.isBackupMode ? 10 : 6
    if (event.key === 'Enter' && this.inputTarget.value.length === requiredLength) {
      event.preventDefault()
      this.submitBtnTarget.click()
    }
  }

  toggleBackupCode(event) {
    event.preventDefault()
    this.isBackupMode = !this.isBackupMode
    
    if (this.isBackupMode) {
      // Switch to backup code mode
      this.labelTarget.textContent = "Backup Code"
      this.hintTarget.textContent = "Enter your 10-character backup code"
      this.inputTarget.placeholder = "XXXXXXXXXX"
      this.inputTarget.maxLength = 10
      this.inputTarget.value = ""
      this.inputTarget.classList.add("uppercase")
      event.target.textContent = "Use email code instead"
    } else {
      // Switch back to email OTP mode
      this.labelTarget.textContent = "Verification Code"
      this.hintTarget.textContent = "Enter the 6-digit code from your email"
      this.inputTarget.placeholder = "000000"
      this.inputTarget.maxLength = 6
      this.inputTarget.value = ""
      this.inputTarget.classList.remove("uppercase")
      event.target.textContent = "Use backup code instead"
    }
    
    this.inputTarget.focus()
  }
}