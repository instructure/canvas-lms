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
import assetFactory from '@canvas/confetti/react/assetFactory'

jest.useFakeTimers()
beforeAll(() => {
  HTMLCanvasElement.prototype.getContext = () => ({})
  const htmlCanvasElement = document.createElement('canvas')
  htmlCanvasElement.id = 'confetti-canvas'
  document.body.appendChild(htmlCanvasElement)
})
let confettiOpts
let asset1
let asset2
let basicColors

describe('ConfettiGenerator', () => {
  beforeEach(() => {
    basicColors = [
      [165, 104, 246],
      [230, 61, 135]
    ]
    asset1 = {
      key: 'panda',
      type: 'svg',
      src: assetFactory('panda'),
      weight: 0.05,
      size: 40
    }
    asset2 = {
      key: 'gnome',
      type: 'svg',
      src: assetFactory('gnome'),
      weight: 0.05,
      size: 40
    }
    confettiOpts = {
      colors: basicColors,
      props: ['square', asset1, asset2].filter(p => p !== null)
    }
  })

  it('calls the generator and returns the action', () => {
    const confetti = new ConfettiGenerator(confettiOpts)
    expect(confetti).toBeDefined()
  })

  it('returns a number with the render command', () => {
    const confetti = new ConfettiGenerator()
    expect(typeof confetti.render()).toBe('number')
  })

  it('returns a number with the clear command', () => {
    const confetti = new ConfettiGenerator()
    expect(typeof confetti.clear()).toBe('undefined')
  })
})
