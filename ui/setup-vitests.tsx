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

// @ts-expect-error
HTMLCanvasElement.prototype.getContext = vi.fn()
