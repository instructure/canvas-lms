/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

class ExplodingParticle {
  constructor(x, y) {
    this.animationDuration = 1000

    this.position = {
      x,
      y,
    }

    this.speed = {
      x: -3 + Math.random() * 6,
      y: -3 + Math.random() * 6,
    }

    this.radius = 3 + Math.random() * 3

    this.life = 30 + Math.random() * 10
    this.remainingLife = this.life
    this.startTime = Date.now()
  }

  getStartTime() {
    return this.startTime
  }

  doneAnimating() {
    const percent = (Date.now() - this.startTime) / this.animationDuration
    return percent > 1
  }

  draw(ctx) {
    if (this.remainingLife > 0 && this.radius > 0) {
      ctx.beginPath()
      ctx.arc(this.position.x, this.position.y, this.radius, 0, Math.PI * 2)
      ctx.fillStyle = 'rgb(255, 0, 0, 1)'
      ctx.fill()

      this.remainingLife--
      this.radius -= 0.25
      this.position.x += this.speed.x
      this.position.y += this.speed.y
    }
  }
}

export default class ParticleFactory {
  constructor() {
    this.particles = []
  }

  createParticles(x, y, amount) {
    for (let i = 0; i < amount; i++) {
      const particle = new ExplodingParticle(x, y)
      this.particles.push(particle)
    }
  }

  updateParticles(ctx) {
    this.particles = this.particles.filter(particle => {
      particle.draw(ctx)
      return !particle.doneAnimating()
    })
  }
}
