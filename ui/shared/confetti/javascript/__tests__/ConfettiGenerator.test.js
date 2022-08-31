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
import ConfettiGenerator from '../ConfettiGenerator'

jest.useFakeTimers()
beforeAll(() => {
  HTMLCanvasElement.prototype.getContext = () => ({
    clearRect: jest.fn(),
    beginPath: jest.fn(),
    save: jest.fn(),
    translate: jest.fn(),
    rotate: jest.fn(),
    fillRect: jest.fn(),
    restore: jest.fn(),
    drawImage: jest.fn()
  })
  const htmlCanvasElement = document.createElement('canvas')
  htmlCanvasElement.id = 'confetti-canvas'
  document.body.appendChild(htmlCanvasElement)
})

const asset1 = {
  key: 'panda',
  type: 'svg',
  src: '/panda',
  weight: 0.05,
  size: 40
}

const asset2 = {
  key: 'gnome',
  type: 'svg',
  src: '/gnome',
  weight: 0.05,
  size: 40
}

const basicColors = [
  [165, 104, 246],
  [230, 61, 135]
]

const confettiOpts = {
  colors: basicColors,
  props: ['square', asset1, asset2].filter(p => p !== null)
}

const imageCreation = jest.fn()

describe('ConfettiGenerator', () => {
  beforeEach(() => {
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation(cb => cb())
    jest.spyOn(window, 'Image').mockImplementation(imageCreation)
  })

  afterEach(() => {
    window.requestAnimationFrame.mockRestore()
    window.Image.mockRestore()
    imageCreation.mockClear()
  })

  it('calls the generator and returns the action', () => {
    const confetti = new ConfettiGenerator(confettiOpts)
    expect(confetti).toBeDefined()
  })

  it('returns a number with the clear command', () => {
    const confetti = new ConfettiGenerator()
    expect(typeof confetti.clear()).toBe('undefined')
  })

  it('only instantiates the needed images', () => {
    const confetti = new ConfettiGenerator(confettiOpts)
    confetti.render()
    expect(imageCreation).toHaveBeenCalledTimes(2)
  })
})
