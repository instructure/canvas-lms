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
import type {WindowInfo} from './adaTypes'

type AdaChatbotProps = {
  onDialogClose: () => void
}

const ADA_STATE_KEY = 'persistedAdaState' // localStorage key for Ada state

type AdaState = 'closed' | 'open' | 'minimized'

let adaReadyPromise: Promise<void> | null = null
let adaScriptLoadPromise: Promise<void> | null = null
let isRestoringDrawer = false
let isOpeningAda = false
let adaEventsBound = false

/**
 * Loads the Ada embed script dynamically.
 * Returns a promise that resolves when the script is loaded.
 */
function loadAdaScript(): Promise<void> {
  if (adaScriptLoadPromise) return adaScriptLoadPromise

  // If adaEmbed is available, resolve without trying to load the script
  if (typeof window !== 'undefined' && window.adaEmbed) {
    adaScriptLoadPromise = Promise.resolve()
    return adaScriptLoadPromise
  }

  adaScriptLoadPromise = new Promise((resolve, reject) => {
    const existingScript = document.getElementById('__ada')
    if (existingScript) {
      resolve()
      return
    }

    const script = document.createElement('script')
    script.id = '__ada'
    script.src = 'https://static.ada.support/embed2.js'
    script.async = true
    script.setAttribute('data-lazy', '')
    script.setAttribute('data-handle', 'instructure-gen')

    const handleError = () => {
      adaScriptLoadPromise = null
      reject(new Error('Failed to load Ada embed script'))
    }

    script.onload = () => resolve()
    script.onerror = handleError

    document.body.appendChild(script)
  })

  return adaScriptLoadPromise
}

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

function getAdaState(): AdaState {
  try {
    const state = localStorage.getItem(ADA_STATE_KEY)
    if (state === 'closed' || state === 'open' || state === 'minimized') {
      return state
    }
  } catch (e) {
    console.warn('Ada localStorage get failed; defaulting to closed', e)
  }
  return 'closed' // Default state
}

function setAdaState(state: AdaState): void {
  try {
    localStorage.setItem(ADA_STATE_KEY, state)
  } catch (e) {
    console.warn('Ada localStorage set failed', e)
  }
}

/**
 * Gets the Ada settings based on current user and environment.
 */
function getAdaSettings() {
  const user = window.ENV?.current_user || {}
  const roles: string[] = window.ENV?.current_user_roles || []
  const roleSet = new Set(roles)
  const domainRootAccountUuid = window.ENV?.DOMAIN_ROOT_ACCOUNT_UUID || ''

  return {
    crossWindowPersistence: true,
    metaFields: {
      institutionUrl: window.location.origin,
      email: user.email || '',
      name: user.display_name || '',
      canvasRoles: roles.join(','),
      canvasUUID: domainRootAccountUuid,
      isRootAdmin: roleSet.has('root_admin'),
      isAdmin: roleSet.has('admin'),
      isTeacher: roleSet.has('teacher'),
      isStudent: roleSet.has('student'),
      isObserver: roleSet.has('observer'),
    },
  }
}

/**
 * Checks if Ada chatbot is enabled via feature flag
 * If not enabled, silently skips initialization.
 */
function isAdaEnabled(): boolean {
  if (typeof window === 'undefined' || !window.ENV) {
    return false
  }
  return window.ENV.ADA_CHATBOT_ENABLED === true
}

/**
 * Initializes Ada embed and restores drawer/chat state if needed.
 * Returns a promise that resolves when Ada is ready to use.
 */
async function initializeAda(): Promise<void> {
  if (!isAdaEnabled()) {
    return
  }

  if (adaReadyPromise) return adaReadyPromise

  adaReadyPromise = (async () => {
    try {
      await loadAdaScript()

      // With data-lazy, call adaEmbed.start() to initialize
      if (!window.adaEmbed?.start) {
        throw new Error('adaEmbed.start not available after script load')
      }

      return await new Promise<void>((resolve, reject) => {
        window
          .adaEmbed!.start({
            ...getAdaSettings(),
            handle: 'instructure-gen',
            onAdaEmbedLoaded: () => {
              const adaEmbed = window.adaEmbed
              if (!adaEmbed) {
                reject(new Error('adaEmbed not available in onAdaEmbedLoaded'))
                return
              }

              // Subscribe to end_conversation event - only this marks chat as closed
              const endConversationHandler = () => {
                updateChatState({
                  isOpen: false,
                  hasActiveChatter: false,
                  hasClosedChat: true,
                })
                if (typeof adaEmbed.stop === 'function') {
                  adaEmbed
                    .stop()
                    .catch((err: Error) => {
                      console.warn('Ada stop failed on end_conversation:', err)
                    })
                    .finally(() => {
                      adaReadyPromise = null // Allow reinitialization after stop
                      isRestoringDrawer = false
                      isOpeningAda = false
                      adaEventsBound = false
                    })
                } else {
                  adaReadyPromise = null
                  isRestoringDrawer = false
                  isOpeningAda = false
                  adaEventsBound = false
                }
              }

              adaEmbed
                .subscribeEvent('ada:end_conversation', endConversationHandler)
                .catch((err: Error) => console.warn('Ada subscribe end_conversation failed', err))

              // Subscribe to drawer-close events (minimize or close)
              ;['ada:minimize_chat', 'ada:close_chat']
                .map(event => {
                  const handler = () => {
                    updateChatState({
                      isOpen: false,
                      hasActiveChatter: false,
                      hasClosedChat: false,
                    })
                  }
                  return adaEmbed.subscribeEvent(event, handler)
                })
                .forEach(p =>
                  p.catch((err: Error) => console.warn('Ada subscribe drawer event failed', err)),
                )
              adaEventsBound = true
            },
            adaReadyCallback: () => {
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
          .catch(reject)
      })
    } catch (err) {
      console.warn('Ada start failed:', err)
      // Reset promise so initialization can be retried
      adaReadyPromise = null
      adaEventsBound = false
      throw err
    }
  })()

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
    await initializeAda()

    if (!window.adaEmbed) throw new Error('Ada embed not available after initialization')
    const adaEmbed = window.adaEmbed

    const adaWindowInfo: WindowInfo = await adaEmbed.getInfo()
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
    if (window.adaEmbed && adaState === 'open') {
      const adaEmbed = window.adaEmbed
      const adaWindowInfo: WindowInfo = await adaEmbed.getInfo()
      if (!adaWindowInfo.isChatOpen) {
        await adaEmbed.toggle()
        const freshAdaWindowInfo: WindowInfo = await adaEmbed.getInfo()
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

// Test helper to reset module state between tests
export function _resetForTesting(): void {
  adaReadyPromise = null
  adaScriptLoadPromise = null
  isRestoringDrawer = false
  isOpeningAda = false
  adaEventsBound = false
}

// Test helper to pre-cache script load promise (prevents real network requests in tests)
export function _setScriptLoadedForTesting(): void {
  adaScriptLoadPromise = Promise.resolve()
}

export default AdaChatbot
