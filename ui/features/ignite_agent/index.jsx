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
import {AgentButton} from './AgentButton'
import {AgentContainerProvider} from './AgentContainerContext'
import {FallbackChatOverlay} from './FallbackChatOverlay'
import {readFromSession, writeToSession} from './IgniteAgentSessionStorage'

// Define constants for DOM element IDs
const AGENT_CONTAINER_ID = 'ignite-agent-root'
const BUTTON_CONTAINER_ID = 'ignite-agent-button-container'
const CHAT_OVERLAY_CONTAINER_ID = 'ignite-agent-chat-overlay-container'

/**
 * Main IgniteAgent component that manages all states and rendering
 */
function IgniteAgent(props) {
  const [isLoading, setIsLoading] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [error, setError] = useState(null)

  // Store mount points in useRef
  const buttonMountPoint = useRef(props.buttonMountPoint)
  const chatOverlayMountPoint = useRef(props.chatOverlayMountPoint)

  useEffect(() => {
    // Check session storage to see if agent should be opened
    if (readFromSession('isOpen') ?? false) {
      console.log('[Ignite Agent] Session state is "open", loading module directly.')
      handleLoadAgent()
    }

    // Cleanup function
    return () => {
      if (buttonMountPoint.current) {
        buttonMountPoint.current.remove()
      }
      if (chatOverlayMountPoint.current) {
        chatOverlayMountPoint.current.remove()
      }
    }
  }, [])

  // Handle loading the remote agent module
  const handleLoadAgent = async () => {
    console.log('[Ignite Agent] Loading remote module...')
    setIsLoading(true)
    setError(null)

    // Set session storage state to "open"
    writeToSession('isOpen', true)

    try {
      console.log("[Ignite Agent] Importing remote 'igniteagent/appInjector'...")
      const module = await import('igniteagent/appInjector')
      console.log('[Ignite Agent] Remote module loaded successfully:', module.default)

      if (typeof module.render === 'function') {
        const props = {hostTheme: getCurrentTheme()}
        module.render(chatOverlayMountPoint.current, props)
        console.log('[Ignite Agent] Remote module rendered successfully')
        setIsOpen(true)
      } else {
        const renderError = new Error('Remote module does not have a render function')
        setError(renderError)
      }
    } catch (loadError) {
      console.error('Failed to load Ignite Agent remote module:', loadError)
      captureException(loadError)
      setError(loadError)
      setIsOpen(false)
      writeToSession('isOpen', false)
    } finally {
      setIsLoading(false)
    }
  }

  // Handle closing the error sidebar
  const handleCloseError = () => {
    setError(null)
    // Clear the sidebar content
    if (chatOverlayMountPoint.current) {
      chatOverlayMountPoint.current.innerHTML = ''
    }
  }

  // Don't render button if agent is open and loaded successfully
  const shouldShowButton = !isOpen && error === null

  return (
    <>
      <Portal mountNode={buttonMountPoint.current} open={shouldShowButton}>
        <AgentContainerProvider buttonMountPoint={buttonMountPoint.current}>
          <AgentButton isLoading={isLoading} onClick={handleLoadAgent} />
        </AgentContainerProvider>
      </Portal>
      <Portal mountPoint={chatOverlayMountPoint.current} open={error !== null}>
        <FallbackChatOverlay error={error} onClose={handleCloseError} />
      </Portal>
    </>
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

  let buttonMountPoint = document.getElementById(BUTTON_CONTAINER_ID)
  if (!buttonMountPoint) {
    buttonMountPoint = document.createElement('div')
    buttonMountPoint.id = BUTTON_CONTAINER_ID
    // Positioning is handled by the AgentButton component itself
    document.body.appendChild(buttonMountPoint)
  }
  let chatOverlayMountPoint = document.getElementById(CHAT_OVERLAY_CONTAINER_ID)
  if (!chatOverlayMountPoint) {
    chatOverlayMountPoint = document.createElement('div')
    chatOverlayMountPoint.id = CHAT_OVERLAY_CONTAINER_ID
    document.body.appendChild(chatOverlayMountPoint)
  }

  render(
    <IgniteAgent
      buttonMountPoint={buttonMountPoint}
      chatOverlayMountPoint={chatOverlayMountPoint}
    />,
    agentMountPoint,
  )
  console.log('[Ignite Agent] Main component initialized.')
}

// Start the initialization process
ready(() => {
  initIgniteAgent()
})
