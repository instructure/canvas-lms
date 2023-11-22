/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import '@testing-library/jest-dom'
import Adapter from 'enzyme-adapter-react-16'
import Enzyme from 'enzyme'
import {vi} from 'vitest'

Enzyme.configure({adapter: new Adapter()})

vi.stubGlobal('ENV', {
  FEATURES: {},
})

vi.stubGlobal(
  'IntersectionObserver',
  class IntersectionObserver {
    observe() {}

    unobserve() {}
  }
)

vi.stubGlobal(
  'ResizeObserver',
  class ResizeObserver {
    observe() {}

    unobserve() {}

    disconnect() {}
  }
)

vi.stubGlobal('matchMedia', () => ({
  matches: false,
  addListener() {},
  removeListener() {},
  onchange() {},
  media: '',
}))

vi.stubGlobal('jest', vi)

HTMLCanvasElement.prototype.getContext = vi.fn().mockImplementation(() => ({
  fillRect: vi.fn(),
  clearRect: vi.fn(),
  getImageData: vi.fn().mockReturnValue({
    data: new Array(100),
  }),
  putImageData: vi.fn(),
  createImageData: vi.fn().mockReturnValue([]),
  setTransform: vi.fn(),
  drawImage: vi.fn(),
  save: vi.fn(),
  fillText: vi.fn(),
  restore: vi.fn(),
  beginPath: vi.fn(),
  moveTo: vi.fn(),
  lineTo: vi.fn(),
  closePath: vi.fn(),
  stroke: vi.fn(),
  translate: vi.fn(),
  scale: vi.fn(),
  rotate: vi.fn(),
  arc: vi.fn(),
  fill: vi.fn(),
  measureText: vi.fn().mockReturnValue({width: 0}),
  transform: vi.fn(),
  rect: vi.fn(),
  clip: vi.fn(),
}))
