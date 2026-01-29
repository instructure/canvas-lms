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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import {
  useSettingDependency,
  SETTING_MESSAGES,
} from '@canvas/assignments/react/hooks/useSettingDependency'

describe('useSettingDependency', () => {
  it('calls onDisabled when message with enabled: false is received', async () => {
    const onDisabled = vi.fn()
    const onEnabled = vi.fn()

    renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled,
        onEnabled,
      }),
    )

    await act(async () => {
      window.postMessage({subject: SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, enabled: false}, '*')
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    expect(onDisabled).toHaveBeenCalledTimes(1)
    expect(onEnabled).not.toHaveBeenCalled()
  })

  it('calls onEnabled when message with enabled: true is received', async () => {
    const onDisabled = vi.fn()
    const onEnabled = vi.fn()

    renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled,
        onEnabled,
      }),
    )

    await act(async () => {
      window.postMessage({subject: SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, enabled: true}, '*')
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    expect(onEnabled).toHaveBeenCalledTimes(1)
    expect(onDisabled).not.toHaveBeenCalled()
  })

  it('does not call handlers when enabled is undefined', async () => {
    const onDisabled = vi.fn()
    const onEnabled = vi.fn()

    renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled,
        onEnabled,
      }),
    )

    await act(async () => {
      window.postMessage({subject: SETTING_MESSAGES.TOGGLE_PEER_REVIEWS}, '*')
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    expect(onDisabled).not.toHaveBeenCalled()
    expect(onEnabled).not.toHaveBeenCalled()
  })

  it('ignores messages with different subjects', async () => {
    const onDisabled = vi.fn()

    renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled,
      }),
    )

    await act(async () => {
      window.postMessage({subject: 'SOME_OTHER_SUBJECT', enabled: false}, '*')
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    expect(onDisabled).not.toHaveBeenCalled()
  })

  it('cleans up event listener on unmount', () => {
    const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener')

    const {unmount} = renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled: vi.fn(),
      }),
    )

    unmount()

    expect(removeEventListenerSpy).toHaveBeenCalledWith('message', expect.any(Function))
    removeEventListenerSpy.mockRestore()
  })

  it('works without onEnabled callback', async () => {
    const onDisabled = vi.fn()

    renderHook(() =>
      useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
        onDisabled,
      }),
    )

    await act(async () => {
      window.postMessage({subject: SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, enabled: true}, '*')
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    expect(onDisabled).not.toHaveBeenCalled()
  })
})
