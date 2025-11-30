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

type WindowInfo = {
  isChatOpen: boolean
  isDrawerOpen: boolean
  hasActiveChatter: boolean
  hasClosedChat: boolean
}

type AdaEmbed = {
  start: (config: any) => Promise<void>
  getInfo: () => Promise<WindowInfo>
  toggle: () => Promise<void>
  stop?: () => Promise<void>
  subscribeEvent: (eventKey: string, callback: (data: any) => void) => Promise<number>
}

type AdaChatbotProps = {
  onDialogClose: () => void
}

const CHAT_CLOSED_KEY = 'persistedAdaClosed' // User explicitly ended conversation
const DRAWER_OPEN_KEY = 'persistedAdaDrawerOpen' // Drawer was open (vs minimized)
const ADA_TIMEOUT = 30000 // 30 seconds

let initializationPromise: Promise<void> | null = null
let initializedAdaEmbed: AdaEmbed | null = null
let adaReadyPromise: Promise<void> | null = null
let resolveAdaReady: (() => void) | null = null

function updateChatState({
  isOpen,
  hasActiveChatter,
  hasClosedChat,
}: {
  isOpen: boolean
  hasActiveChatter: boolean
  hasClosedChat?: boolean
}) {
  if (hasClosedChat) {
    markChatClosed()
  }
  if (hasActiveChatter) {
    ;(window as any).adaSettings = {
      ...(window as any).adaSettings,
      hideMask: true,
    }
  }
  if (isOpen) {
    markChatActive()
    markDrawerOpen()
  } else {
    // Soft close, unless explicitly ended conversation
    markDrawerClosed()
  }
}

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

/**
 * Creates a promise that rejects after the specified timeout
 */
function withTimeout<T>(promise: Promise<T>, timeoutMs: number, errorMessage: string): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_resolve, reject) =>
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs),
    ),
  ])
}

/**
 * Initializes Ada embed and restores drawer/chat state if needed
 */
async function initializeAda(waitForReady: boolean = true): Promise<void> {
  const adaEmbed = getAdaEmbed()
  if (initializationPromise && initializedAdaEmbed === adaEmbed) {
    await initializationPromise
    if (waitForReady && adaReadyPromise) await adaReadyPromise
    return
  }
  if (!adaEmbed) return
  initializedAdaEmbed = adaEmbed

  // Only create ready promise if we actually need to wait for it
  if (waitForReady) {
    adaReadyPromise = withTimeout(
      new Promise<void>(resolve => {
        resolveAdaReady = resolve
      }),
      ADA_TIMEOUT,
      'Ada ready callback timed out',
    )
  } else {
    adaReadyPromise = Promise.resolve()
    resolveAdaReady = () => {}
  }

  initializationPromise = adaEmbed.start({
    ...((window as any).adaSettings || {}),
    handle: 'instructure-gen',
    onAdaEmbedLoaded: () => {
      // Subscribe to end_conversation event - only this marks chat as closed
      adaEmbed
        .subscribeEvent('ada:end_conversation', () => {
          updateChatState({
            isOpen: false,
            hasActiveChatter: false,
            hasClosedChat: true,
          })
          if (typeof adaEmbed.stop === 'function') {
            withTimeout(adaEmbed.stop(), ADA_TIMEOUT, 'Ada stop timed out').catch(err =>
              console.warn('Ada stop failed on end_conversation:', err),
            )
          }
        })
        .catch(err => console.warn('Ada subscribe end_conversation failed', err))

      // Subscribe to minimize_chat - drawer minimized but chat still active
      adaEmbed
        .subscribeEvent('ada:minimize_chat', () => {
          updateChatState({
            isOpen: false,
            hasActiveChatter: false,
            hasClosedChat: false,
          })
        })
        .catch(err => console.warn('Ada subscribe minimize_chat failed', err))

      // Subscribe to close_chat - drawer closed but chat may still be active
      adaEmbed
        .subscribeEvent('ada:close_chat', () => {
          updateChatState({
            isOpen: false,
            hasActiveChatter: false,
            hasClosedChat: false,
          })
        })
        .catch(err => console.warn('Ada subscribe close_chat failed', err))
    },
    adaReadyCallback: async () => {
      try {
        const adaWindowInfo = await adaEmbed.getInfo()
        if (adaWindowInfo.hasClosedChat && typeof adaEmbed.stop === 'function') {
          // If Ada reports closed on ready, ensure the session is stopped
          adaEmbed.stop().catch(err => console.warn('Ada stop failed in ready callback:', err))
        }
        const shouldRestoreDrawer = !wasClosedByUser() && wasDrawerOpen()
        if (shouldRestoreDrawer && !adaWindowInfo.isChatOpen) {
          await adaEmbed.toggle()
          const freshAdaWindowInfo = await adaEmbed.getInfo()
          updateChatState({
            isOpen: freshAdaWindowInfo.isChatOpen,
            hasActiveChatter: freshAdaWindowInfo.hasActiveChatter,
            hasClosedChat: freshAdaWindowInfo.hasClosedChat,
          })
        } else {
          updateChatState({
            isOpen: adaWindowInfo.isChatOpen,
            hasActiveChatter: adaWindowInfo.hasActiveChatter,
            hasClosedChat: adaWindowInfo.hasClosedChat,
          })
        }
        resolveAdaReady?.()
      } catch (error) {
        console.warn('Ada ready callback failed:', error)
        resolveAdaReady?.()
      }
    },
    toggleCallback: (isOpen: boolean) => {
      updateChatState({
        isOpen,
        hasActiveChatter: false,
        hasClosedChat: false,
      })
    },
  })
  await withTimeout(initializationPromise, ADA_TIMEOUT, 'Ada initialization timed out')
  if (waitForReady && adaReadyPromise) {
    await adaReadyPromise.catch(err => {
      console.warn('Ada ready promise rejected:', err)
    })
  }
}

/**
 * Opens Ada chatbot and restores drawer state
 */
async function openAda(onDialogClose?: () => void): Promise<void> {
  try {
    const adaEmbed = getAdaEmbed()
    if (!adaEmbed) throw new Error('Ada embed script not available')
    await initializeAda(false).catch(err => {
      console.warn('initializeAda failed in openAda:', err)
      throw err
    })
    if (getAdaEmbed() !== initializedAdaEmbed) {
      await initializeAda(false).catch(err => {
        console.warn('Re-initializeAda failed in openAda:', err)
        throw err
      })
    }
    const adaWindowInfo = await withTimeout(
      adaEmbed.getInfo(),
      ADA_TIMEOUT,
      'Ada getInfo timed out in openAda',
    )
    if (!adaWindowInfo.isChatOpen) {
      await withTimeout(adaEmbed.toggle(), ADA_TIMEOUT, 'Ada toggle timed out in openAda')
    }
    updateChatState({isOpen: true, hasActiveChatter: adaWindowInfo.hasActiveChatter})
    if (adaReadyPromise) {
      await adaReadyPromise.catch(err => {
        console.warn('Ada ready promise rejected in openAda:', err)
      })
    }
  } catch (error) {
    console.error('Failed to open Ada chatbot:', error)
  } finally {
    onDialogClose?.()
  }
}

/**
 * Auto-restore Ada if it was open in a previous session.
 * Should be called after main app initialization.
 */
let hasAutoRestored = false
export function autoRestoreAda(): void {
  if (!hasAutoRestored && !wasClosedByUser()) {
    hasAutoRestored = true
    initializeAda().catch(error => {
      console.error('Failed to auto-restore Ada:', error)
    })
  }
}

/**
 * AdaChatbot opens the Ada chatbot when the user selects it from the help menu.
 * Ada will persist across navigation once started, until the user manually closes it.
 */
function AdaChatbot({onDialogClose}: AdaChatbotProps) {
  const onDialogCloseRef = useRef(onDialogClose)
  const mountedRef = useRef(true)
  useEffect(() => {
    onDialogCloseRef.current = onDialogClose
  }, [onDialogClose])
  useEffect(() => {
    openAda(() => {
      if (mountedRef.current) onDialogCloseRef.current?.()
    })
    return () => {
      mountedRef.current = false
    }
  }, []) // Only open once on mount; ref always has latest onDialogClose
  return null
}

export default AdaChatbot
