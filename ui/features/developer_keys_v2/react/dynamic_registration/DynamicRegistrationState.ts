/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import create from 'zustand'

/**
 * Steps are:
 * 1. Open modal, prompting for url
 * 2. User enters url, clicks "register," and an iframe is inserted, pointed at /api/lti/register
 * 3. When the app responds with a postMessage done, the iframe is removed, and we show the
 *    created dev key along with the permissions it has
 */

/**
 * Actions for the dynamic registration modal
 */
interface DynamicRegistrationActions {
  /**
   * Opens the modal for a user to enter a dynamic registration url
   * @returns
   */
  open: (url?: string) => void
  /**
   * Closes the modal
   * @returns
   */
  close: () => void
  /**
   * Updates the url the user is entering
   * @param url
   * @returns
   */
  setUrl: (url: string) => void
  /**
   * Embeds an iframe to the tool's dynamic registration UI at the given url.
   * @param url The dynamic registration url
   * @param onFinish A callback to run when the app responds with a postMessage done
   * @returns
   */
  register: (url: string, onFinish: () => void) => void
}

/**
 * ADT for the state of the dynamic registration modal
 *
 * 'closed' means the modal is not open
 * 'opened' means the modal is open, and the user is entering a url
 * 'registering' means the modal is open, and the user has entered a url and clicked "register"
 *    and we are waiting for the app to respond with a postMessage
 */
export type DynamicRegistrationState =
  | {
      tag: 'closed'
    }
  | {
      tag: 'opened'
      dynamicRegistrationUrl: string
    }
  | {
      tag: 'registering'
      dynamicRegistrationUrl: string
    }

/**
 * Helper for constructing an 'opened' state
 * @param dynamicRegistrationUrl
 * @returns
 */
const opened = (dynamicRegistrationUrl: string): DynamicRegistrationState => ({
  tag: 'opened',
  dynamicRegistrationUrl,
})

/**
 * Helper for constructing a 'closed' state
 */
const notOpened: DynamicRegistrationState = {
  tag: 'closed',
}

/**
 * Helper for constructing a 'registering' state
 * @param dynamicRegistrationUrl
 * @returns
 */
const registering = (dynamicRegistrationUrl: string): DynamicRegistrationState => ({
  tag: 'registering',
  dynamicRegistrationUrl,
})

/**
 * Wraps a value into an object with a state key, for use with Zustand
 * @param state
 * @returns
 */
const stateFor =
  <A>(state: A) =>
  () => ({state})

/**
 * Lens for Zustand to update a specific state
 * The new state will only be applied if the current state has the same tag
 *
 * @example
 *
 * const state = stateFrom('opened')(openedState => {
 *   return
 * })
 *
 * @param tag
 * @returns
 */
const stateFrom =
  <T extends DynamicRegistrationState['tag']>(tag: T) =>
  (
    mkNewState: (
      oldState: Extract<DynamicRegistrationState, {tag: T}>,
      actions: DynamicRegistrationActions
    ) => DynamicRegistrationState
  ) =>
  (oldState: {state: DynamicRegistrationState} & DynamicRegistrationActions) => {
    if (oldState.state.tag === tag) {
      return {
        state: mkNewState(oldState.state as Extract<DynamicRegistrationState, {tag: T}>, oldState),
      }
    } else {
      return oldState
    }
  }

/**
 * Zustand store for the state of the dynamic registration modal
 */
export const useDynamicRegistrationState = create<
  {state: DynamicRegistrationState} & DynamicRegistrationActions
>(set => ({
  state: {tag: 'closed'},
  open: (url?: string) => set(stateFor(opened(url || ''))),
  close: () => set(stateFor(notOpened)),
  setUrl: url => set(stateFor(opened(url))),
  register: (url: string, onClose: () => void) =>
    set(
      stateFrom('opened')((state, {close}) => {
        const onMessage = (message: MessageEvent) => {
          if (
            message.data.subject === 'org.imsglobal.lti.close' &&
            message.origin === originOfUrl(url)
          ) {
            window.removeEventListener('message', onMessage)
            onClose()
            close()
          }
        }
        window.addEventListener('message', onMessage)
        return registering(url)
      })
    ),
}))

const originOfUrl = (urlStr: string) => {
  const url = new URL(urlStr)
  return url.origin
}
