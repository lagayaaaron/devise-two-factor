// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy(event) {
    event.preventDefault()
    
    const text = this.sourceTarget.textContent.trim()
    
    navigator.clipboard.writeText(text).then(() => {
      const originalText = this.buttonTarget.innerHTML
      this.buttonTarget.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Copied!
      `
      
      setTimeout(() => {
        this.buttonTarget.innerHTML = originalText
      }, 2000)
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }
}