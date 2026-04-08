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

import {useEffect, useMemo} from 'react'
import {debounce} from '@instructure/debounce'
import type {CardConfig, UseIframeMessagingOptions} from '../types'
import {fetchPreviewToken, toApiConfig} from '../api'

const DISCOVERY_PAGE_PREVIEW = 'DISCOVERY_PAGE_PREVIEW'
const DEBOUNCE_MS = 500

// hook to send a signed JWT preview token to an iframe via postMessage
// de-bounces API calls (~500ms) so rapid edits don’t hammer the token endpoint
export function useIframeMessaging({
  iframeRef,
  config,
  previewUrl,
}: UseIframeMessagingOptions): void {
  const targetOrigin = useMemo(() => {
    if (!previewUrl) return null

    try {
      return new URL(previewUrl).origin
    } catch {
      return null
    }
  }, [previewUrl])

  const sendToken = useMemo(
    () =>
      debounce(async (cfg: CardConfig) => {
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
      }, DEBOUNCE_MS),
    [iframeRef, targetOrigin],
  )

  useEffect(() => {
    sendToken(config)
  }, [config, sendToken])

  // cancel pending debounce on unmount
  useEffect(() => {
    return () => sendToken.cancel()
  }, [sendToken])
}
