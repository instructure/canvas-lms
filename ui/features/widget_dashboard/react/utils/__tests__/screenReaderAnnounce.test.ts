/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {announceToScreenReader} from '../screenReaderAnnounce'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

const mockShowFlashAlert = vi.mocked(showFlashAlert)

const SR_HOLDER_ID = 'flash_screenreader_holder'

describe('announceToScreenReader', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    mockShowFlashAlert.mockClear()
    document.getElementById(SR_HOLDER_ID)?.remove()
  })

  afterEach(() => {
    vi.useRealTimers()
    document.getElementById(SR_HOLDER_ID)?.remove()
  })

  it('does not announce immediately', () => {
    announceToScreenReader('Widget moved up')

    expect(mockShowFlashAlert).not.toHaveBeenCalled()
  })

  it('announces after the 1s delay', () => {
    announceToScreenReader('Widget moved up')

    vi.advanceTimersByTime(1000)

    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: 'Widget moved up',
      srOnly: true,
      politeness: 'polite',
    })
  })

  it('cancels pending announcement on rapid calls', () => {
    announceToScreenReader('first message')
    vi.advanceTimersByTime(500)

    announceToScreenReader('second message')
    vi.advanceTimersByTime(1000)

    expect(mockShowFlashAlert).toHaveBeenCalledTimes(1)
    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: 'second message',
      srOnly: true,
      politeness: 'polite',
    })
  })

  it('does not announce cancelled message', () => {
    announceToScreenReader('cancelled message')
    vi.advanceTimersByTime(500)

    announceToScreenReader('replacement')
    vi.advanceTimersByTime(500)

    // Only 500ms into the second call's 1000ms delay
    expect(mockShowFlashAlert).not.toHaveBeenCalled()
  })

  it('removes the SR holder before announcing to prevent accumulation', () => {
    // Create a fake SR holder with accumulated content
    const holder = document.createElement('div')
    holder.id = SR_HOLDER_ID
    holder.textContent = 'old accumulated message'
    document.body.appendChild(holder)

    announceToScreenReader('new message')
    vi.advanceTimersByTime(1000)

    // Old holder should have been removed
    expect(holder.parentNode).toBeNull()
    // showFlashAlert should still be called (it recreates the holder)
    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: 'new message',
      srOnly: true,
      politeness: 'polite',
    })
  })
})
