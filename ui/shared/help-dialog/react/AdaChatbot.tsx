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

const CHAT_CLOSED_KEY = 'persistedAdaClosed' // User explicitly ended conversation
const DRAWER_OPEN_KEY = 'persistedAdaDrawerOpen' // Drawer was open (vs minimized)

let adaReadyPromise: Promise<void> | null = null

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
  } else if (hasClosedChat === false) {
    // Explicitly keep chat active for soft closes
    markChatActive()
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
                adaEmbed
                  .stop()
                  .catch(err => {
                    console.warn('Ada stop failed on end_conversation:', err)
                  })
                  .finally(() => {
                    adaReadyPromise = null // Allow reinitialization after stop
                  })
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

          try {
            const adaWindowInfo = await adaEmbed.getInfo()
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
          } catch (error) {
            console.warn('Ada ready callback failed:', error)
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
    updateChatState({isOpen: true, hasActiveChatter: adaWindowInfo.hasActiveChatter})
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
export function autoRestoreAda(): void {
  if (!wasClosedByUser()) {
    initializeAda().catch(err => {
      console.warn('Auto-restore Ada failed:', err)
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
