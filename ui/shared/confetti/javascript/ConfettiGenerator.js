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

const TARGET_CANVAS = 'confetti-canvas'
const PARTICLE_COUNT = 160
const PARTICLE_SPEED = 50

const getRandomInt = (limit, floor) => {
  if (!limit) limit = 1
  const rand = Math.random() * limit
  return !floor ? rand : Math.floor(rand)
}

const getWeightedPropIndex = (props, totalWeight) => {
  let rand = Math.random() * totalWeight
  for (const i in props) {
    const weight = props[i].weight || 1
    if (rand < weight) return i
    rand -= weight
  }
}

export default function ConfettiGenerator(opts) {
  const options = {
    props: ['square'],
    colors: [
      [165, 104, 246],
      [230, 61, 135],
      [0, 199, 228],
      [253, 214, 126]
    ],
    ...opts
  }

  const cv = document.getElementById(TARGET_CANVAS)
  if (cv === null || !(cv instanceof HTMLCanvasElement)) {
    throw new ReferenceError('The target element does not exist or is not a canvas element')
  }
  const ctx = cv.getContext('2d')
  let animationsActive = true
  const cachedImageAssets = {}

  const totalWeight = options.props.reduce((weight, prop) => {
    return weight + (prop.weight || 1)
  }, 0)

  const generateParticle = () => {
    const prop = options.props[getWeightedPropIndex(options.props, totalWeight)]
    return {
      prop: prop.type ? prop.type : prop,
      x: getRandomInt(window.innerWidth),
      y: getRandomInt(window.innerHeight),
      src: prop.src,
      size: prop.size,
      color: options.colors[getRandomInt(options.colors.length, true)], // color
      rotation: (getRandomInt(360, true) * Math.PI) / 180,
      speed: getRandomInt(PARTICLE_SPEED / 7) + PARTICLE_SPEED / 30
    }
  }

  const drawParticle = p => {
    if (!p) {
      return
    }

    ctx.fillStyle = ctx.strokeStyle = 'rgba(' + p.color + ', 1)'
    ctx.beginPath()

    switch (p.prop) {
      case 'square': {
        ctx.save()
        ctx.translate(p.x + 15, p.y + 5)
        ctx.rotate(p.rotation)
        ctx.fillRect(-15, -5, 15, 5)
        ctx.restore()
        break
      }
      case 'svg': {
        ctx.save()
        let image
        if (p.src in cachedImageAssets) {
          image = cachedImageAssets[p.src]
        } else {
          image = new window.Image()
          image.src = p.src
          cachedImageAssets[p.src] = image
        }
        const size = p.size || 15
        ctx.translate(p.x + size / 2, p.y + size / 2)
        ctx.drawImage(image, -(size / 2), -(size / 2), size, size)
        ctx.restore()
        break
      }
    }
  }

  const _clear = () => {
    animationsActive = false

    requestAnimationFrame(() => {
      ctx.clearRect(0, 0, cv.width, cv.height)
      const w = cv.width
      cv.width = 1
      cv.width = w
    })
  }

  const _render = () => {
    cv.width = window.innerWidth
    cv.height = window.innerHeight
    const particles = []

    for (let i = 0; i < PARTICLE_COUNT; i++) particles.push(generateParticle())

    const update = () => {
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        const p = particles[i]

        if (p) {
          if (animationsActive) p.y += p.speed

          if ((p.speed >= 0 && p.y > window.innerHeight) || (p.speed < 0 && p.y < 0)) {
            particles[i] = undefined
          }
        }
      }

      if (particles.every(p => p === undefined)) {
        _clear()
      }
    }

    const draw = () => {
      ctx.clearRect(0, 0, window.innerWidth, window.innerHeight)

      for (const i in particles) drawParticle(particles[i])

      update()

      if (animationsActive) requestAnimationFrame(draw)
    }

    return requestAnimationFrame(draw)
  }

  return {
    render: _render,
    clear: _clear
  }
}
