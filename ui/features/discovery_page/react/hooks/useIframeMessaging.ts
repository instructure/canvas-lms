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

import {useCallback, useEffect, useMemo, useRef} from 'react'
import {debounce} from '@instructure/debounce'
import type {CardConfig, UseIframeMessagingOptions} from '../types'
import {fetchPreviewToken, toApiConfig} from '../api'

const DISCOVERY_PAGE_PREVIEW = 'DISCOVERY_PAGE_PREVIEW'
const DISCOVERY_PAGE_READY = 'DISCOVERY_PAGE_READY'
const DEBOUNCE_MS = 500

// hook to send a signed JWT preview token to an iframe via postMessage
// de-bounces API calls (~500ms) so rapid edits don’t hammer the token endpoint
// also responds immediately when the iframe signals DISCOVERY_PAGE_READY
export function useIframeMessaging({
  iframeRef,
  config,
  previewUrl,
}: UseIframeMessagingOptions): void {
  const configRef = useRef(config)
  useEffect(() => {
    configRef.current = config
  })

  const isReadyRef = useRef(false)
  const targetOrigin = useMemo(() => {
    if (!previewUrl) return null

    try {
      return new URL(previewUrl).origin
    } catch {
      return null
    }
  }, [previewUrl])

  const doSend = useCallback(
    async (cfg: CardConfig) => {
      if (!iframeRef.current?.contentWindow || !targetOrigin) return

      try {
        const token = await fetchPreviewToken(toApiConfig(cfg))
        iframeRef.current.contentWindow.postMessage(
          {type: DISCOVERY_PAGE_PREVIEW, token},
          targetOrigin,
        )
      } catch (err) {
        console.error('Failed to send preview token:', err)
      }
    },
    [iframeRef, targetOrigin],
  )

  const sendToken = useMemo(() => debounce(doSend, DEBOUNCE_MS), [doSend])

  // send on config changes (debounced), but only after the iframe has signalled ready
  useEffect(() => {
    if (isReadyRef.current) {
      sendToken(config)
    }
  }, [config, sendToken])

  // wait for the iframe’s READY signal before sending anything
  // reset isReady and cancel pending sends whenever targetOrigin changes
  // so a newly-mounted iframe always goes through the handshake
  useEffect(() => {
    if (!targetOrigin) {
      isReadyRef.current = true
      return
    }

    isReadyRef.current = false
    // the config-change effect runs before this one (effects fire in declaration
    // order), so it may have queued a send with the new sendToken before we had
    // a chance to reset isReadyRef; cancel it here so the first send is always
    // the immediate one triggered by DISCOVERY_PAGE_READY
    sendToken.cancel()

    const handleReady = (event: MessageEvent) => {
      if (event.origin !== targetOrigin) return
      if (event.data?.type !== DISCOVERY_PAGE_READY) return

      isReadyRef.current = true
      void doSend(configRef.current)
    }

    window.addEventListener('message', handleReady)
    return () => {
      window.removeEventListener('message', handleReady)
      isReadyRef.current = false
      sendToken.cancel()
    }
  }, [targetOrigin, doSend, sendToken])
}
