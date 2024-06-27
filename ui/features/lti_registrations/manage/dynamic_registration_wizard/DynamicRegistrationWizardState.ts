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
import {formatApiResultError, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'

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
export interface DynamicRegistrationActions {
  /**
   * Loads a registration token from the BE for the given account.
   * Changes states to keep track of the loading process.
   *
   * @param accountId The account id the tool is being registered for
   *    can be a account id, shard-relative id, or the string 'site_admin'
   * @param dynamicRegistrationUrl The url to use for dynamic registration
   * @param unifiedToolId Included in token if provided
   * @returns
   */
  loadRegistrationToken: (
    accountId: AccountId,
    dynamicRegistrationUrl: string,
    unifiedToolId?: string
  ) => void
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
    imsRegistrationId: LtiImsRegistrationId,
    registrationId: LtiRegistrationId,
    developerKeyId: DeveloperKeyId,
    overlay: RegistrationOverlay,
    adminNickname: string,
    onSuccess: () => void
  ) => Promise<unknown>

  /**
   * Deletes the Developer Key for the given id
   * and closes the modal. The previous state must be a confirmation state.
   *
   * @param prevState The previous state of the modal
   * @param developerKeyId The id of the developer key to delete
   * @returns The result of the delete operation
   */
  deleteKey: (
    prevState: ReviewingStateType,
    developerKeyId: DeveloperKeyId
  ) => Promise<ApiResult<unknown>>
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
    newState: ConfirmationStateType,
    reviewing?: boolean
  ): void
  transitionToReviewingState(prevState: ConfirmationStateType): void
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
      message: string
    }
  | ConfirmationState<'PermissionConfirmation'>
  | ConfirmationState<'PrivacyLevelConfirmation'>
  | ConfirmationState<'PlacementsConfirmation'>
  | ConfirmationState<'NamingConfirmation'>
  | ConfirmationState<'IconConfirmation'>
  | ConfirmationState<'Reviewing'>
  | ConfirmationState<'Enabling'>
  | ConfirmationState<'DeletingDevKey'>

export type ConfirmationStateType = Exclude<
  DynamicRegistrationWizardState['_type'],
  'RequestingToken' | 'WaitingForTool' | 'LoadingRegistration' | 'Error'
>
type ReviewingStateType = Exclude<ConfirmationStateType, 'Enabling' | 'DeletingDevKey'>

/**
 * Helper for constructing a 'confirmation' state (a substate of the confirmation screen)
 */
export type ConfirmationState<Tag extends string> = {
  _type: Tag
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
  reviewing: boolean
}

const errorState = (message: string): DynamicRegistrationWizardState => ({
  _type: 'Error',
  message,
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
    (set: StateUpdater, get) => ({
      state: {_type: 'RequestingToken'},
      /**
       * Fetches a registration token from the dynamic registration URL
       * sets the state to 'registering'
       * and listens for a message from the tool
       *
       * @param accountId
       * @param dynamicRegistrationUrl
       * @param unifiedToolId included in token. optional.
       */
      loadRegistrationToken: (
        accountId: AccountId,
        dynamicRegistrationUrl: string,
        unifiedToolId: string = ''
      ) => {
        set(stateFor({_type: 'RequestingToken'}))
        // eslint-disable-next-line promise/catch-or-return
        service.fetchRegistrationToken(accountId, unifiedToolId).then(resp => {
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
                    set(stateFor(errorState(formatApiResultError(reg))))
                  }
                })
              }
            }
            global.addEventListener('message', onMessage)
          } else {
            set(stateFor(errorState(formatApiResultError(resp))))
          }
        })
      },
      enableAndClose: async (
        accountId: AccountId,
        imsRegistrationId: LtiImsRegistrationId,
        registrationId: LtiRegistrationId,
        developerKeyId: DeveloperKeyId,
        overlay: RegistrationOverlay,
        adminNickname: string,
        onSuccess: () => void
      ) => {
        set(stateFrom('Reviewing')(state => enabling(state.registration, state.overlayStore)))
        const [a, b, c] = await Promise.all([
          service.updateRegistrationOverlay(accountId, imsRegistrationId, overlay),
          service.updateDeveloperKeyWorkflowState(accountId, developerKeyId, 'on'),
          service.updateAdminNickname(accountId, registrationId, adminNickname),
        ])
        if (a._type !== 'success') {
          set(stateFor(errorState(formatApiResultError(a))))
        } else if (b._type !== 'success') {
          set(stateFor(errorState(formatApiResultError(b))))
        } else if (c._type !== 'success') {
          set(stateFor(errorState(formatApiResultError(c))))
        } else {
          onSuccess()
        }
      },
      deleteKey: async (prevState: ReviewingStateType, developerKeyId: DeveloperKeyId) => {
        set(stateFrom(prevState)(state => deleting(state.registration, state.overlayStore)))
        const result = await service.deleteDeveloperKey(developerKeyId)
        if (result._type !== 'success') {
          set(stateFor(errorState(formatApiResultError(result))))
        }
        return result
      },
      transitionToConfirmationState: (
        prevState: ConfirmationStateType,
        newState: ConfirmationStateType,
        reviewing?: boolean
      ) =>
        set(
          stateFrom(prevState)(a => ({
            ...a,
            reviewing: reviewing ?? a.reviewing,
            _type: newState,
          }))
        ),
      transitionToReviewingState: (prevState: ConfirmationStateType) =>
        set(
          stateFrom(prevState)(a => ({
            ...a,
            _type: 'Reviewing',
            reviewing: true,
          }))
        ),
    })
  )

const originOfUrl = (urlStr: string) => {
  const url = new URL(urlStr)
  return url.origin
}
