import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "counter"]
  static values = {
    snippetId: Number,
    vote: String
  }

  connect() {
    this.vote = JSON.parse(this.voteValue)
    this.#toggleBorder()
  }

  async handleClick(event) {
    event.preventDefault()

    const formData = new FormData(event.currentTarget.parentElement)
    const reaction = event.currentTarget.dataset.reactionType

    if (reaction === this.vote?.reaction_type) {
      await this.#deleteReaction(formData)
    } else if (this.vote) {
      await this.#updateReaction(reaction, formData)
    } else {
      await this.#createReaction(formData)
    }

    this.#toggleBorder()
  }

  #updateCounter(modifier) {
    const counter = this.counterTargets.find(span => span.dataset.reactionType === this.vote.reaction_type)
    counter.innerText = modifier + Number(counter.innerText)
  }

  #toggleBorder() {
    this.buttonTargets.forEach(button => {
      if (button.dataset.reactionType === this.vote?.reaction_type) {
        button.classList.add("border-aoc-green", "bg-aoc-green/20")
        button.classList.remove("border-aoc-gray-darker")
      } else {
        button.classList.add("border-aoc-gray-darker")
        button.classList.remove("border-aoc-green", "bg-aoc-green/20")
      }
    })
  }

  async #createReaction(body) {
    try {
      const response = await fetch(`/snippets/${this.snippetIdValue}/reactions`, {
        method: "POST",
        headers: {
          Accept: "application/json"
        },
        body
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.errors)
      }

      const data = await response.json()
      this.vote = data.reaction
      this.#updateCounter(1)
    } catch (error) {
      console.log(error)
    }
  }

  async #updateReaction(reaction, body) {
    try {
      const response = await fetch(`/reactions/${this.vote.id}`, {
        method: "PATCH",
        headers: {
          Accept: "application/json"
        },
        body
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.errors)
      }

      const data = await response.json()
      this.#updateCounter(-1)
      this.vote = data.reaction
      this.#updateCounter(1)
    } catch (error) {
      console.log(error)
    }
  }

  async #deleteReaction(body) {
    await fetch(`/reactions/${this.vote.id}`, {
      method: "DELETE",
      headers: {
        Accept: "application/json"
      },
      body
    })

    this.#updateCounter(-1)
    this.vote = null
  }
}
