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

import {useEffect, useRef} from 'react'

type AdaEmbed = {
  start: (config: any) => Promise<void>
  getInfo: () => Promise<{isChatOpen: boolean; hasActiveChatter: boolean}>
  toggle: () => void
}

type AdaChatbotProps = {
  onDialogClose: () => void
}

const PERSIST_KEY = 'persistedAdaClosed'

let initializationPromise: Promise<void> | null = null
let initializedAdaEmbed: AdaEmbed | null = null

function getAdaEmbed(): AdaEmbed | null {
  return (window as any).adaEmbed ?? null
}

function wasClosedByUser(): boolean {
  return localStorage.getItem(PERSIST_KEY) === 'true'
}

function markChatOpen(): void {
  localStorage.setItem(PERSIST_KEY, 'false')
}

function markChatClosed(): void {
  localStorage.setItem(PERSIST_KEY, 'true')
}

async function initializeAda(): Promise<void> {
  const adaEmbed = getAdaEmbed()

  // Return cached promise if we're already initializing the same instance
  if (initializationPromise && initializedAdaEmbed === adaEmbed) {
    return initializationPromise
  }

  if (!adaEmbed) return

  initializedAdaEmbed = adaEmbed

  initializationPromise = adaEmbed.start({
    ...((window as any).adaSettings || {}),
    handle: 'instructure-gen',
    hideMascot: true,
    adaReadyCallback: async () => {
      try {
        const info = await adaEmbed.getInfo()

        if (info.isChatOpen || (info.hasActiveChatter && !wasClosedByUser())) {
          if (!info.isChatOpen) adaEmbed.toggle()
          markChatOpen()
        }
      } catch (error) {
        console.warn('Ada ready callback failed:', error)
      }
    },
    toggleCallback: (isOpen: boolean) => {
      if (isOpen) {
        markChatOpen()
      } else {
        markChatClosed()
      }
    },
  })

  return initializationPromise
}

async function openAda(onDialogClose?: () => void): Promise<void> {
  try {
    const adaEmbed = getAdaEmbed()
    if (!adaEmbed) throw new Error('Ada embed script not available')

    await initializeAda()

    const info = await adaEmbed.getInfo()
    if (!info.isChatOpen) {
      adaEmbed.toggle()
    }
    markChatOpen()
  } catch (error) {
    console.error('Failed to open Ada chatbot:', error)
  } finally {
    onDialogClose?.()
  }
}

// Auto-restore Ada if it was open in a previous session
if (!wasClosedByUser()) {
  initializeAda().catch(error => console.error('Failed to auto-restore Ada:', error))
}

/**
 * AdaChatbot opens the Ada chatbot when the user selects it from the help menu.
 * Ada will persist across navigation once started, until the user manually closes it.
 */
function AdaChatbot({onDialogClose}: AdaChatbotProps) {
  const onDialogCloseRef = useRef(onDialogClose)
  useEffect(() => {
    onDialogCloseRef.current = onDialogClose
  }, [onDialogClose])

  useEffect(() => {
    openAda(onDialogCloseRef.current)
    // Intentionally empty deps so we only open once on mount,
    // and rely on the ref to always have the latest onDialogClose
  }, [])

  return null
}

export default AdaChatbot
