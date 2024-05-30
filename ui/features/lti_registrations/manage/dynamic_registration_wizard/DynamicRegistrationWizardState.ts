/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import type {AccountId} from '../model/AccountId'
import type {DynamicRegistrationToken} from '../model/DynamicRegistrationToken'
import type {RegistrationOverlay} from '../model/RegistrationOverlay'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import type {LtiImsRegistration} from '../model/lti_ims_registration/LtiImsRegistration'
import type {LtiImsRegistrationId} from '../model/lti_ims_registration/LtiImsRegistrationId'
import {
  createRegistrationOverlayStore,
  type RegistrationOverlayStore,
} from '../registration_wizard/registration_settings/RegistrationOverlayState'
import type {DynamicRegistrationWizardService} from './DynamicRegistrationWizardService'

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
   * Loads a registration token from the BE for the given account.
   * Changes states to keep track of the loading process.
   *
   * @param accountId The account id the tool is being registered for
   *    can be a account id, shard-relative id, or the string 'site_admin'
   * @param dynamicRegistrationUrl The url to use for dynamic registration
   * @returns
   */
  loadRegistrationToken: (accountId: AccountId, dynamicRegistrationUrl: string) => void
  /**
   * Enables the developer key for the given registration
   * and closes the modal
   *
   * @param accountId The account id the tool is being registered for
   * @param registration The registration to enable
   * @param overlay The overlay to apply to the registration
   * @returns
   */
  enableAndClose: (
    accountId: AccountId,
    registrationId: LtiImsRegistrationId,
    developerKeyId: DeveloperKeyId,
    overlay: RegistrationOverlay
  ) => Promise<unknown>

  /**
   * Deletes the Developer Key for the given id
   * and closes the modal
   *
   * @param developerKeyId The id of the developer key to delete
   * @returns
   */
  deleteKey: (developerKeyId: DeveloperKeyId) => Promise<unknown>
  /**
   * Transition to a new confirmation state, copying the
   * state from the previous confirmation state
   * Only applies the new state if the previous state
   * is currently active
   *
   * @param prevState The previous state
   * @param newState The new state
   */
  transitionToConfirmationState(
    prevState: ConfirmationStateType,
    newState: ConfirmationStateType
  ): void
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
export type DynamicRegistrationWizardState =
  | {
      _type: 'RequestingToken'
    }
  | {
      _type: 'WaitingForTool'
      registrationToken: DynamicRegistrationToken
    }
  | {
      _type: 'LoadingRegistration'
      registrationToken: DynamicRegistrationToken
    }
  | {
      _type: 'Error'
      error?: Error | string
    }
  | ConfirmationState<'PermissionConfirmation'>
  | ConfirmationState<'PrivacyLevelConfirmation'>
  | ConfirmationState<'PlacementsConfirmation'>
  | ConfirmationState<'NamingConfirmation'>
  | ConfirmationState<'IconConfirmation'>
  | ConfirmationState<'Reviewing'>
  | ConfirmationState<'Enabling'>
  | ConfirmationState<'DeletingDevKey'>

type ConfirmationStateType = Exclude<
  DynamicRegistrationWizardState['_type'],
  'RequestingToken' | 'WaitingForTool' | 'LoadingRegistration' | 'Error'
>

/**
 * Helper for constructing a 'confirmation' state (a substate of the confirmation screen)
 */
type ConfirmationState<Tag extends string> = {
  _type: Tag
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
  reviewing: boolean
}

const errorState = (
  error?:
    | {
        _type: 'ApiParseError' | 'GenericError'
        message: string
      }
    | {
        _type: 'Exception'
        error: Error
      }
): DynamicRegistrationWizardState => ({
  _type: 'Error',
  error: error ? (error._type === 'Exception' ? error.error : error.message) : undefined,
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
 * Wraps a value into an object with a state key, for use with Zustand
 * @param state
 * @returns
 */
const stateForTag =
  <K extends DynamicRegistrationWizardState['_type']>(
    _type: K,
    value: Omit<Extract<DynamicRegistrationWizardState, {_type: K}>, '_type'>
  ) =>
  () => ({state: {_type, ...value}})

/**
 * Helper for constructing a 'confirming' state
 * @param tag
 * @returns
 */
const confirmationState =
  <Tag extends ConfirmationStateType>(_type: Tag) =>
  (
    registration: LtiImsRegistration,
    overlayStore: RegistrationOverlayStore,
    reviewing = false
  ): DynamicRegistrationWizardState => ({
    _type,
    registration,
    overlayStore,
    reviewing,
  })

const enabling = confirmationState('Enabling')
const deleting = confirmationState('DeletingDevKey')

/**
 * Helper for constructing a state from another state.
 * The new state will only be applied if the current state has the same tag
 *
 * @example
 *
 * const state = stateFrom('PermissionConfirmation`)(state => {
 *   return state;
 * })
 *
 * @param tag
 * @returns
 */
const stateFrom =
  <T extends DynamicRegistrationWizardState['_type']>(_type: T) =>
  (
    mkNewState: (
      oldState: Extract<DynamicRegistrationWizardState, {_type: T}>,
      actions: DynamicRegistrationActions
    ) => DynamicRegistrationWizardState
  ) =>
  (oldState: {state: DynamicRegistrationWizardState} & DynamicRegistrationActions) => {
    if (oldState.state._type === _type) {
      return {
        state: mkNewState(
          oldState.state as Extract<DynamicRegistrationWizardState, {_type: T}>,
          oldState
        ),
      }
    } else {
      return oldState
    }
  }

type StateUpdater = (
  updater: (s: {state: DynamicRegistrationWizardState} & DynamicRegistrationActions) => {
    state: DynamicRegistrationWizardState
  }
) => void

/**
 * Zustand store for the state of the dynamic registration modal
 */
export const mkUseDynamicRegistrationWizardState = (service: DynamicRegistrationWizardService) =>
  create<{state: DynamicRegistrationWizardState} & DynamicRegistrationActions>(
    (set: StateUpdater) => ({
      state: {_type: 'RequestingToken'},
      /**
       * Fetches a registration token from the dynamic registration URL
       * sets the state to 'registering'
       * and listens for a message from the tool
       *
       * @param accountId
       * @param dynamicRegistrationUrl
       */
      loadRegistrationToken: (accountId: AccountId, dynamicRegistrationUrl: string) => {
        set(stateFor({_type: 'RequestingToken'}))
        // eslint-disable-next-line promise/catch-or-return
        service.fetchRegistrationToken(accountId).then(resp => {
          if (resp._type === 'success') {
            set(stateFor({_type: 'WaitingForTool', registrationToken: resp.data}))
            const onMessage = (message: MessageEvent) => {
              if (
                message.data &&
                typeof message.data.subject === 'string' &&
                message.data.subject === 'org.imsglobal.lti.close' &&
                message.origin === originOfUrl(dynamicRegistrationUrl)
              ) {
                global.removeEventListener('message', onMessage)
                set(
                  stateForTag('LoadingRegistration', {
                    registrationToken: resp.data,
                  })
                )
                // eslint-disable-next-line promise/catch-or-return
                service.getRegistrationByUUID(accountId, resp.data.uuid).then(reg => {
                  if (reg._type === 'success') {
                    const store: RegistrationOverlayStore = createRegistrationOverlayStore(
                      reg.data.client_name,
                      reg.data
                    )
                    set(stateFor(confirmationState('PermissionConfirmation')(reg.data, store)))
                  } else {
                    set(stateFor(errorState(reg)))
                  }
                })
              }
            }
            global.addEventListener('message', onMessage)
          } else if (resp._type === 'Exception') {
            set(stateFor(errorState(resp)))
          } else {
            set(stateFor({_type: 'Error'}))
          }
        })
      },
      enableAndClose: (
        accountId: AccountId,
        registrationId: LtiImsRegistrationId,
        developerKeyId: DeveloperKeyId,
        overlay: RegistrationOverlay
      ) => {
        set(stateFrom('Reviewing')(state => enabling(state.registration, state.overlayStore)))
        return Promise.all([
          service.updateRegistrationOverlay(accountId, registrationId, overlay),
          service.updateDeveloperKeyWorkflowState(accountId, developerKeyId, 'on'),
        ]).then(([a, b]) => {
          if (a._type !== 'success') {
            set(stateFor(errorState(a)))
          } else if (b._type !== 'success') {
            set(stateFor(errorState(b)))
          }
        })
      },
      deleteKey: (developerKeyId: DeveloperKeyId) => {
        set(stateFrom('Reviewing')(state => deleting(state.registration, state.overlayStore)))
        return service.deleteDeveloperKey(developerKeyId).then(result => {
          if (result._type !== 'success') {
            set(stateFor(errorState(result)))
          }
        })
      },
      transitionToConfirmationState: (
        prevState: ConfirmationStateType,
        newState: ConfirmationStateType
      ) =>
        set(
          stateFrom(prevState)(a => ({
            ...a,
            _type: newState,
          }))
        ),
      error: (error?: Error) =>
        set(
          stateFor({
            _type: 'Error',
            error,
          })
        ),
    })
  )

const originOfUrl = (urlStr: string) => {
  const url = new URL(urlStr)
  return url.origin
}
