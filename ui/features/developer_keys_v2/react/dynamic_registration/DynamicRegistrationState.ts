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

import create, {type StoreApi} from 'zustand'
import {
  type RegistrationToken,
  getRegistrationByUUID,
  updateRegistrationOverlay,
} from './registrationApi'
import {type LtiRegistration} from '../../model/LtiRegistration'
import {
  type RegistrationOverlay,
  type RegistrationOverlayStore,
  createRegistrationOverlayStore,
} from '../RegistrationSettings/RegistrationOverlayState'
import {deleteDeveloperKey, updateDeveloperKeyWorkflowState} from './developerKeyApi'

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
   * @param registrationToken The registration token from canvas
   * @returns
   */
  register: (accountId: string, registrationToken: RegistrationToken) => void
  loadingRegistrationToken: () => void
  loadingRegistration: (
    registrationToken: RegistrationToken,
    dynamicRegistrationUrl: string
  ) => void
  confirm: (registration: LtiRegistration, overlayStore: StoreApi<RegistrationOverlayStore>) => void
  enableAndClose: (
    contextId: string,
    registration: LtiRegistration,
    overlay: RegistrationOverlay
  ) => Promise<unknown>
  closeAndSaveOverlay: (
    accountId: string,
    registration: LtiRegistration,
    overlay: RegistrationOverlay
  ) => Promise<unknown>
  deleteKey: (registration: LtiRegistration) => Promise<unknown>
  error: (error?: Error) => void
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
      tag: 'loading_registration_token'
      dynamicRegistrationUrl: string
    }
  | {
      tag: 'registering'
      dynamicRegistrationUrl: string
      registrationToken: RegistrationToken
    }
  | {
      tag: 'loading_registration'
      dynamicRegistrationUrl: string
      registrationToken: RegistrationToken
    }
  | {
      tag: 'error'
      error?: Error
    }
  | ConfirmationState<'confirming'>
  | ConfirmationState<'enabling_and_closing'>
  | ConfirmationState<'closing_and_saving'>
  | ConfirmationState<'deleting'>

type ConfirmationTag = 'confirming' | 'enabling_and_closing' | 'closing_and_saving' | 'deleting'
/**
 * Helper for constructing a 'confirmation' state (a substate of the confirmation screen)
 */
type ConfirmationState<Tag extends ConfirmationTag> = {
  tag: Tag
  registration: LtiRegistration
  overlayStore: StoreApi<RegistrationOverlayStore>
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

const errorState = (error?: Error): DynamicRegistrationState => ({
  tag: 'error',
  error,
})

/**
 * Helper for constructing a 'closed' state
 */
const notOpened: DynamicRegistrationState = {
  tag: 'closed',
}

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
const loadingRegistrationToken = (dynamicRegistrationUrl: string): DynamicRegistrationState => ({
  tag: 'loading_registration_token',
  dynamicRegistrationUrl,
})

/**
 * Helper for constructing a 'registering' state
 * @param dynamicRegistrationUrl
 * @returns
 */
const registering = (
  dynamicRegistrationUrl: string,
  registrationToken: RegistrationToken
): DynamicRegistrationState => ({
  tag: 'registering',
  dynamicRegistrationUrl,
  registrationToken,
})

const loadingRegistration = (
  registrationToken: RegistrationToken,
  dynamicRegistrationUrl: string
): DynamicRegistrationState => ({
  tag: 'loading_registration',
  dynamicRegistrationUrl,
  registrationToken,
})

/**
 * Helper for constructing a 'confirming' state
 * @param tag
 * @returns
 */
const confirmationState =
  <Tag extends ConfirmationTag>(tag: Tag) =>
  (registration: LtiRegistration, overlayStore: StoreApi<RegistrationOverlayStore>) =>
    ({
      tag,
      registration,
      overlayStore,
    } as const)

const confirming = confirmationState('confirming')
const enablingAndClosing = confirmationState('enabling_and_closing')
const closingAndSaving = confirmationState('closing_and_saving')
const deleting = confirmationState('deleting')

/**
 * Helper for constructing a state from another state.
 * If the previous state is not current, the new state will not be applied
 * A "lens" into a zustand state.
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
  open: url => set(stateFor(opened(url || ''))),
  close: () => set(stateFor(notOpened)),
  loadingRegistrationToken: () =>
    set(stateFrom('opened')(state => loadingRegistrationToken(state.dynamicRegistrationUrl))),
  setUrl: url => set(stateFor(opened(url))),
  register: (accountId: string, registrationToken: RegistrationToken) =>
    set(
      stateFrom('loading_registration_token')((state, {loadingRegistration, confirm, error}) => {
        const onMessage = (message: MessageEvent) => {
          if (
            message.data.subject === 'org.imsglobal.lti.close' &&
            message.origin === originOfUrl(state.dynamicRegistrationUrl)
          ) {
            window.removeEventListener('message', onMessage)
            loadingRegistration(registrationToken, state.dynamicRegistrationUrl)
            getRegistrationByUUID(accountId, registrationToken.uuid)
              .then(reg => {
                const store = createRegistrationOverlayStore(reg.client_name, reg)
                confirm(reg, store)
              })
              .catch(err => {
                error(err instanceof Error ? err : undefined)
              })
          }
        }
        window.addEventListener('message', onMessage)
        return registering(state.dynamicRegistrationUrl, registrationToken)
      })
    ),
  loadingRegistration: (registrationToken: RegistrationToken, dynamicRegistrationUrl: string) =>
    set(stateFor(loadingRegistration(registrationToken, dynamicRegistrationUrl))),
  confirm: (registration: LtiRegistration, overlayStore: StoreApi<RegistrationOverlayStore>) =>
    set(stateFor(confirming(registration, overlayStore))),
  enableAndClose: (
    accountId: string,
    registration: LtiRegistration,
    overlay: RegistrationOverlay
  ) => {
    set(
      stateFrom('confirming')(state => enablingAndClosing(state.registration, state.overlayStore))
    )
    return Promise.all([
      updateRegistrationOverlay(accountId, registration.id, overlay),
      updateDeveloperKeyWorkflowState(accountId, registration.developer_key_id, 'on'),
    ]).catch(err => set(stateFor(errorState(err))))
  },
  closeAndSaveOverlay: (
    accountId: string,
    registration: LtiRegistration,
    overlay: RegistrationOverlay
  ) => {
    set(stateFrom('confirming')(state => closingAndSaving(state.registration, state.overlayStore)))
    return updateRegistrationOverlay(accountId, registration.id, overlay).catch(err =>
      set(stateFor(errorState(err)))
    )
  },
  deleteKey: (registration: LtiRegistration) => {
    set(stateFrom('confirming')(state => deleting(state.registration, state.overlayStore)))
    return deleteDeveloperKey(registration.developer_key_id).catch(err =>
      set(stateFor(errorState(err)))
    )
  },
  error: (error?: Error) => set(stateFor(errorState(error))),
}))

const originOfUrl = (urlStr: string) => {
  const url = new URL(urlStr)
  return url.origin
}
