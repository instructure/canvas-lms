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

import {act, renderHook} from '@testing-library/react-hooks'
import {useIframeMessaging} from '../useIframeMessaging'
import {fetchPreviewToken} from '../../api'
import type {CardConfig} from '../../types'

vi.mock('../../api', () => ({
  fetchPreviewToken: vi.fn().mockResolvedValue('test-token'),
  toApiConfig: vi.fn().mockReturnValue({discovery_page: {primary: [], secondary: []}}),
}))

const PREVIEW_URL = 'https://preview.example.com/discovery'
const PREVIEW_ORIGIN = 'https://preview.example.com'
const makeConfig = (): CardConfig => ({
  discovery_page: {primary: [], secondary: []},
})
const fireReady = (origin = PREVIEW_ORIGIN) => {
  window.dispatchEvent(
    new MessageEvent('message', {
      origin,
      data: {type: 'DISCOVERY_PAGE_READY'},
    }),
  )
}

describe('useIframeMessaging', () => {
  let mockPostMessage: ReturnType<typeof vi.fn>
  let iframeRef: {current: HTMLIFrameElement}

  beforeEach(() => {
    vi.useFakeTimers()
    mockPostMessage = vi.fn()
    iframeRef = {
      current: {contentWindow: {postMessage: mockPostMessage}} as unknown as HTMLIFrameElement,
    }
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.clearAllMocks()
  })

  it('sends token immediately when iframe signals READY', async () => {
    renderHook(() => useIframeMessaging({iframeRef, config: makeConfig(), previewUrl: PREVIEW_URL}))
    act(() => fireReady())
    await act(async () => {}) // flush fetchPreviewToken promise
    expect(fetchPreviewToken).toHaveBeenCalledTimes(1)
    expect(mockPostMessage).toHaveBeenCalledWith(
      {type: 'DISCOVERY_PAGE_PREVIEW', token: 'test-token'},
      PREVIEW_ORIGIN,
    )
  })

  it('ignores READY from a different origin', async () => {
    renderHook(() => useIframeMessaging({iframeRef, config: makeConfig(), previewUrl: PREVIEW_URL}))
    act(() => fireReady('https://evil.example.com'))
    await act(async () => {
      vi.advanceTimersByTime(1000)
    })
    expect(fetchPreviewToken).not.toHaveBeenCalled()
  })

  it('ignores messages with an unexpected type from the correct origin', async () => {
    renderHook(() => useIframeMessaging({iframeRef, config: makeConfig(), previewUrl: PREVIEW_URL}))
    act(() => {
      window.dispatchEvent(
        new MessageEvent('message', {
          origin: PREVIEW_ORIGIN,
          data: {type: 'SOME_OTHER_MESSAGE'},
        }),
      )
    })
    await act(async () => {
      vi.advanceTimersByTime(1000)
    })
    expect(fetchPreviewToken).not.toHaveBeenCalled()
  })

  it('does not send before READY even when config changes', async () => {
    const config = makeConfig()
    const {rerender} = renderHook(
      ({cfg}) => useIframeMessaging({iframeRef, config: cfg, previewUrl: PREVIEW_URL}),
      {initialProps: {cfg: config}},
    )
    rerender({cfg: {...config}})
    await act(async () => {
      vi.advanceTimersByTime(600)
    })
    expect(fetchPreviewToken).not.toHaveBeenCalled()
  })

  // simulates the ConfigureModal "config loaded" transition: previewUrl and config both change in
  // the same render (isLoadingConfig flips false)
  // the config-change effect fires before the READY effect (declaration order), so it may queue
  // a send with the new sendToken before isReadyRef is reset — the READY effect must cancel it
  it('sends exactly once via READY when config and previewUrl resolve together', async () => {
    const config = makeConfig()
    const {rerender} = renderHook(
      ({cfg, url}: {cfg: typeof config; url: string | undefined}) =>
        useIframeMessaging({iframeRef, config: cfg, previewUrl: url}),
      {initialProps: {cfg: config, url: undefined as string | undefined}},
    )
    // both change in the same render, as they do when fetchDiscoveryConfig resolves
    rerender({cfg: {...config}, url: PREVIEW_URL})
    await act(async () => {
      vi.advanceTimersByTime(600)
    })
    expect(fetchPreviewToken).not.toHaveBeenCalled()
    act(() => fireReady())
    await act(async () => {})
    expect(fetchPreviewToken).toHaveBeenCalledTimes(1)
  })

  it('debounces token sends on rapid config changes after READY', async () => {
    const config = makeConfig()
    const {rerender} = renderHook(
      ({cfg}) => useIframeMessaging({iframeRef, config: cfg, previewUrl: PREVIEW_URL}),
      {initialProps: {cfg: config}},
    )
    act(() => fireReady())
    await act(async () => {}) // flush initial send
    vi.clearAllMocks()
    // three rapid config changes (all but the last should be cancelled)
    rerender({cfg: {...config}})
    rerender({cfg: {...config}})
    rerender({cfg: {...config}})
    expect(fetchPreviewToken).not.toHaveBeenCalled()
    await act(async () => {
      vi.advanceTimersByTime(600)
    })
    expect(fetchPreviewToken).toHaveBeenCalledTimes(1)
  })
})
