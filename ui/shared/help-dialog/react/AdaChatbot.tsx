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
import type {AdaEmbed} from './adaTypes'

type AdaChatbotProps = {
  onDialogClose: () => void
}

const ADA_STATE_KEY = 'persistedAdaState' // 'closed' | 'open' | 'minimized'

type AdaState = 'closed' | 'open' | 'minimized'

let adaReadyPromise: Promise<void> | null = null
let isRestoringDrawer = false
let isOpeningAda = false

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
    setAdaState('closed')
  } else if (isOpen) {
    setAdaState('open')
  } else {
    // Drawer minimized but chat still active
    setAdaState('minimized')
  }

  if (hasActiveChatter) {
    window.adaSettings = {
      ...window.adaSettings,
      hideMask: true,
    }
  }
}

function getAdaEmbed(): AdaEmbed | null {
  // When using data-lazy, Ada exposes AdaEmbed.start() instead of adaEmbed
  if (window.adaEmbed) {
    return window.adaEmbed
  }
  if (window.AdaEmbed?.start) {
    window.adaEmbed = window.AdaEmbed.start({
      ...(window.adaSettings || {}),
      handle: 'instructure-gen',
    })
    return window.adaEmbed ?? null
  }
  return null
}

function getAdaState(): AdaState {
  const state = localStorage.getItem(ADA_STATE_KEY)
  if (state === 'closed' || state === 'open' || state === 'minimized') {
    return state
  }
  return 'closed' // Default state
}

function setAdaState(state: AdaState): void {
  localStorage.setItem(ADA_STATE_KEY, state)
}

/**
 * Initializes Ada embed and restores drawer/chat state if needed.
 * Returns a promise that resolves when Ada is ready to use.
 */
function initializeAda(): Promise<void> {
  if (adaReadyPromise) return adaReadyPromise

  const adaEmbed = getAdaEmbed()
  if (!adaEmbed) return Promise.reject(new Error('Ada embed not available'))

  // Resolves when Ada is ready
  adaReadyPromise = new Promise((resolve, reject) => {
    adaEmbed
      .start({
        ...(window.adaSettings || {}),
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
                adaEmbed
                  .stop()
                  .catch(err => {
                    console.warn('Ada stop failed on end_conversation:', err)
                  })
                  .finally(() => {
                    adaReadyPromise = null // Allow reinitialization after stop
                    isRestoringDrawer = false
                    isOpeningAda = false
                  })
              } else {
                adaReadyPromise = null
                isRestoringDrawer = false
                isOpeningAda = false
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
          // Signal that Ada is ready
          resolve()
        },
        toggleCallback: (isOpen: boolean) => {
          updateChatState({
            isOpen,
            hasActiveChatter: false,
            hasClosedChat: false,
          })
        },
      })
      .catch(err => {
        console.warn('Ada start failed:', err)
        adaReadyPromise = null // Allow retry on failure
        reject(err)
      })
  })

  return adaReadyPromise
}

/**
 * Opens Ada chatbot and restores drawer state
 */
async function openAda(onDialogClose?: () => void): Promise<void> {
  if (isOpeningAda || isRestoringDrawer) {
    console.warn('Ada is already being opened')
    onDialogClose?.()
    return
  }

  isOpeningAda = true
  try {
    const adaEmbed = getAdaEmbed()
    if (!adaEmbed) throw new Error('Ada embed script not available')

    // Wait for Ada to be ready before calling methods
    await initializeAda()

    const adaWindowInfo = await adaEmbed.getInfo()
    if (!adaWindowInfo.isChatOpen) {
      await adaEmbed.toggle()
    }
    updateChatState({
      isOpen: true,
      hasActiveChatter: adaWindowInfo.hasActiveChatter,
      hasClosedChat: false,
    })
  } catch (error) {
    console.error('Failed to open Ada chatbot:', error)
  } finally {
    isOpeningAda = false
    onDialogClose?.()
  }
}

/**
 * Auto-restore Ada if it was open in a previous session.
 * Should be called after main app initialization.
 */
export async function autoRestoreAda(): Promise<void> {
  const adaState = getAdaState()

  if (adaState === 'closed') {
    return // User explicitly closed, don't restore
  }

  if (isRestoringDrawer || isOpeningAda) {
    console.warn('Ada restore/open already in progress')
    return
  }

  isRestoringDrawer = true
  try {
    await initializeAda()

    // After initialization, check if drawer should be restored
    const adaEmbed = getAdaEmbed()
    if (adaEmbed && adaState === 'open') {
      const adaWindowInfo = await adaEmbed.getInfo()
      if (!adaWindowInfo.isChatOpen) {
        await adaEmbed.toggle()
        const freshAdaWindowInfo = await adaEmbed.getInfo()
        updateChatState({
          isOpen: freshAdaWindowInfo.isChatOpen,
          hasActiveChatter: freshAdaWindowInfo.hasActiveChatter,
          hasClosedChat: freshAdaWindowInfo.hasClosedChat,
        })
      }
    }
    // If state is 'minimized', Ada initializes but stays minimized (default behavior)
  } catch (err) {
    console.warn('Auto-restore Ada failed:', err)
  } finally {
    isRestoringDrawer = false
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
