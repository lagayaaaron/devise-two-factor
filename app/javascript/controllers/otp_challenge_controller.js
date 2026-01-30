// app/javascript/controllers/otp_challenge_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitBtn", "label", "hint"]

  connect() {
    console.log("OTP Challenge controller connected")
    this.inputTarget.focus()
    this.isBackupMode = false
  }

  formatInput(event) {
    let value = event.target.value.replace(/\s+/g, '') // Remove spaces
    
    if (this.isBackupMode) {
      // Backup codes: alphanumeric, 10 characters
      value = value.toUpperCase().slice(0, 10)
    } else {
      // TOTP codes: numeric only, 6 digits
      value = value.replace(/\D/g, '').slice(0, 6)
    }
    
    event.target.value = value
    
    // Auto-focus submit when complete
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
    
    const button = event.currentTarget
    
    if (this.isBackupMode) {
      // Switch to backup code mode
      this.labelTarget.textContent = "Backup Code"
      this.hintTarget.textContent = "Enter your 10-character backup code"
      this.inputTarget.placeholder = "XXXXXXXXXX"
      this.inputTarget.maxLength = 10
      this.inputTarget.classList.add("uppercase")
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        Use authenticator code instead
      `
    } else {
      // Switch back to authenticator mode
      this.labelTarget.textContent = "Authentication Code"
      this.hintTarget.textContent = "The code refreshes every 30 seconds"
      this.inputTarget.placeholder = "000000"
      this.inputTarget.maxLength = 6
      this.inputTarget.classList.remove("uppercase")
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
        </svg>
        Use backup code instead
      `
    }
    
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}