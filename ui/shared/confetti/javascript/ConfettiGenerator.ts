/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

// Based on https://github.com/Agezao/confetti-js

import {generateParticle} from './confetti.utils'
import type {ConfettiObject, Particle} from '../types'

const PARTICLE_COUNT = 160
const PARTICLE_SPEED = 50

const defaultColors = [
  [165, 104, 246],
  [230, 61, 135],
  [0, 199, 228],
  [253, 214, 126],
]

class ConfettiGenerator {
  private colors: number[][]

  private props: (string | ConfettiObject)[]

  private ctx: CanvasRenderingContext2D | null

  private animationsActive: boolean = true

  private cachedImageAssets: Record<string, HTMLImageElement> = {}

  constructor(
    props: (string | ConfettiObject)[],
    colors: number[][] | null,
    mountPoint: HTMLCanvasElement
  ) {
    this.colors = colors ?? defaultColors
    this.props = props

    if (!mountPoint || !(mountPoint instanceof HTMLCanvasElement)) {
      throw new ReferenceError('The target element does not exist or is not a canvas element')
    }
    this.ctx = mountPoint.getContext('2d')
    if (!this.ctx) {
      throw new ReferenceError('Could not get canvas context')
    }
  }

  private drawParticle(p: Particle | undefined): void {
    if (!p || !this.ctx) return

    this.ctx.fillStyle = this.ctx.strokeStyle = `rgba(${p.color.join(', ')}, 1)`
    this.ctx.beginPath()
    switch (p.prop) {
      case 'square':
        this.ctx.save()
        this.ctx.translate(p.x + 15, p.y + 5)
        this.ctx.rotate(p.rotation)
        this.ctx.fillRect(-15, -5, 15, 5)
        this.ctx.restore()
        break
      case 'svg':
      case 'image': {
        this.ctx.save()
        let image: HTMLImageElement
        if (typeof p.src !== 'undefined' && p.src in this.cachedImageAssets) {
          image = this.cachedImageAssets[p.src]
        } else {
          image = new Image()
          image.src = p.src as string
          this.cachedImageAssets[p.src as string] = image
        }
        const size = p.size || 15
        const scaledWidth = image.width > image.height ? size : size * (image.width / image.height)
        const scaledHeight = image.width > image.height ? size * (image.height / image.width) : size
        this.ctx.translate(p.x + scaledWidth / 2, p.y + scaledHeight / 2)
        this.ctx.drawImage(image, -(size / 2), -(size / 2), scaledWidth, scaledHeight)
        this.ctx.restore()
        break
      }
    }
  }

  clear(): void {
    this.animationsActive = false
    if (!this.ctx || !this.ctx.canvas) return

    requestAnimationFrame(() => {
      if (!this.ctx || !this.ctx.canvas) return
      this.ctx.clearRect(0, 0, this.ctx.canvas.width, this.ctx.canvas.height)
      const w = this.ctx.canvas.width
      this.ctx.canvas.width = 1
      this.ctx.canvas.width = w
    })
  }

  render(): number {
    if (!this.ctx || !this.ctx.canvas) return 0

    this.ctx.canvas.width = window.innerWidth
    this.ctx.canvas.height = window.innerHeight
    const particles: (Particle | undefined)[] = []

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      particles.push(generateParticle(this.props, this.colors, PARTICLE_SPEED))
    }

    const update = (): void => {
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        const p = particles[i]
        if (p) {
          if (this.animationsActive) p.y += p.speed
          if ((p.speed >= 0 && p.y > window.innerHeight) || (p.speed < 0 && p.y < 0)) {
            particles[i] = undefined
          }
        }
      }

      if (particles.every(p => p === undefined)) {
        this.clear()
      }
    }

    const draw = (): void => {
      this.ctx?.clearRect(0, 0, window.innerWidth, window.innerHeight)

      for (const i in particles) {
        this.drawParticle(particles[i])
      }

      update()

      if (this.animationsActive) requestAnimationFrame(draw)
    }

    return requestAnimationFrame(draw)
  }
}

export default ConfettiGenerator
