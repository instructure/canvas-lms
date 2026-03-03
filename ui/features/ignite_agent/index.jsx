/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect, useRef} from 'react'
import {render} from '@canvas/react'
import {captureException} from '@sentry/browser'
import {getCurrentTheme} from '@instructure/theme-registry'
import {Portal} from '@instructure/ui-portal'
import ready from '@instructure/ready'
import {FallbackChatOverlay} from './FallbackChatOverlay'

// Define constants for DOM element IDs
const AGENT_CONTAINER_ID = 'ignite-agent-root'
const CHAT_OVERLAY_CONTAINER_ID = 'ignite-agent-chat-overlay-container'

/**
 * Main IgniteAgent component that auto-loads the agent
 */
function IgniteAgent({chatOverlayMountPoint}) {
  const [error, setError] = useState(null)
  const chatOverlayRef = useRef(chatOverlayMountPoint)

  useEffect(() => {
    loadAgent()

    return () => {
      if (chatOverlayRef.current) {
        chatOverlayRef.current.remove()
      }
    }
  }, [])

  const loadAgent = async () => {
    console.log('[Ignite Agent] Loading remote module...')

    try {
      console.log("[Ignite Agent] Importing remote 'igniteagent/appInjector'...")
      const module = await import('igniteagent/appInjector')
      console.log('[Ignite Agent] Remote module loaded successfully:', module.default)

      if (typeof module.render === 'function') {
        const props = {hostTheme: getCurrentTheme()}
        module.render(chatOverlayRef.current, props)
        console.log('[Ignite Agent] Remote module rendered successfully')
      } else {
        const renderError = new Error('Remote module does not have a render function')
        captureException(renderError)
        setError(renderError)
      }
    } catch (loadError) {
      console.error('Failed to load Ignite Agent remote module:', loadError)
      captureException(loadError)
      setError(loadError)
    }
  }

  const handleCloseError = () => {
    setError(null)
    if (chatOverlayRef.current) {
      chatOverlayRef.current.innerHTML = ''
    }
  }

  return (
    <Portal mountPoint={chatOverlayRef.current} open={error !== null}>
      <FallbackChatOverlay error={error} onClose={handleCloseError} />
    </Portal>
  )
}

/**
 * Initialize the Ignite Agent
 */
function initIgniteAgent() {
  // Find or create mount point for the main component
  let agentMountPoint = document.getElementById(AGENT_CONTAINER_ID)
  if (!agentMountPoint) {
    agentMountPoint = document.createElement('div')
    agentMountPoint.id = AGENT_CONTAINER_ID
    document.body.appendChild(agentMountPoint)
  }

  // Find or create mount point for the chat overlay
  let chatOverlayMountPoint = document.getElementById(CHAT_OVERLAY_CONTAINER_ID)
  if (!chatOverlayMountPoint) {
    chatOverlayMountPoint = document.createElement('div')
    chatOverlayMountPoint.id = CHAT_OVERLAY_CONTAINER_ID
    document.body.appendChild(chatOverlayMountPoint)
  }

  render(<IgniteAgent chatOverlayMountPoint={chatOverlayMountPoint} />, agentMountPoint)
  console.log('[Ignite Agent] Component initialized with auto-load.')
}

// Start the initialization process
ready(() => {
  initIgniteAgent()
})
