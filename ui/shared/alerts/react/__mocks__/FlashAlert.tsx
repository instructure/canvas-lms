/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {vi as viType} from 'vitest'
declare const vi: typeof viType | undefined

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockFn: any = typeof vi !== 'undefined' ? vi.fn : jest.fn

export const showFlashAlert = mockFn()
export const showFlashError = mockFn(() => mockFn())
export const showFlashSuccess = mockFn(() => mockFn())
export const showFlashWarning = mockFn(() => mockFn())
export const destroyContainer = mockFn()

export default class FlashAlert {
  static defaultProps = {
    variant: 'info',
    timeout: 10000,
    screenReaderOnly: false,
    dismissible: true,
  }

  render() {
    return null
  }
}
