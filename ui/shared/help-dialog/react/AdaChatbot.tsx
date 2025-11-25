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
  subscribeEvent: (eventKey: string, callback: (data: any) => void) => Promise<number>
}

type AdaChatbotProps = {
  onDialogClose: () => void
}

const CHAT_CLOSED_KEY = 'persistedAdaClosed' // User explicitly ended conversation
const DRAWER_OPEN_KEY = 'persistedAdaDrawerOpen' // Drawer was open (vs minimized)

let initializationPromise: Promise<void> | null = null
let initializedAdaEmbed: AdaEmbed | null = null

function getAdaEmbed(): AdaEmbed | null {
  return (window as any).adaEmbed ?? null
}

function wasClosedByUser(): boolean {
  return localStorage.getItem(CHAT_CLOSED_KEY) === 'true'
}

function markChatClosed(): void {
  localStorage.setItem(CHAT_CLOSED_KEY, 'true')
}

function markChatActive(): void {
  localStorage.setItem(CHAT_CLOSED_KEY, 'false')
}

function wasDrawerOpen(): boolean {
  return localStorage.getItem(DRAWER_OPEN_KEY) === 'true'
}

function markDrawerOpen(): void {
  localStorage.setItem(DRAWER_OPEN_KEY, 'true')
}

function markDrawerClosed(): void {
  localStorage.setItem(DRAWER_OPEN_KEY, 'false')
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
    onAdaEmbedLoaded: () => {
      adaEmbed.subscribeEvent('ada:end_conversation', () => {
        markChatClosed()
        markDrawerClosed()
      })
    },
    adaReadyCallback: async () => {
      try {
        const info = await adaEmbed.getInfo()
        const shouldRestoreDrawer = !wasClosedByUser() && wasDrawerOpen()

        if (info.hasActiveChatter) {
          ;(window as any).adaSettings = {
            ...(window as any).adaSettings,
            hideMask: true,
          }
        }

        if (shouldRestoreDrawer && !info.isChatOpen) {
          adaEmbed.toggle()
        }

        if (info.isChatOpen || shouldRestoreDrawer) {
          markChatActive()
          markDrawerOpen()
        } else {
          markDrawerClosed()
        }
      } catch (error) {
        console.warn('Ada ready callback failed:', error)
      }
    },
    toggleCallback: (isOpen: boolean) => {
      if (isOpen) {
        markChatActive()
        markDrawerOpen()
      } else {
        markDrawerClosed()
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
    markChatActive()
    markDrawerOpen()
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
