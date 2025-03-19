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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {ProgressBar} from '@instructure/ui-progress'
import {Spinner} from '@instructure/ui-spinner'
import React, {useCallback} from 'react'
import type {AccountId} from '../model/AccountId'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import type {DynamicRegistrationWizardService} from './DynamicRegistrationWizardService'
import {
  isReviewingState,
  mkUseDynamicRegistrationWizardState,
  type DynamicRegistrationWizardState,
} from './DynamicRegistrationWizardState'
import {IconConfirmationWrapper} from './components/IconConfirmationWrapper'
import {NamingConfirmationWrapper} from './components/NamingConfirmationWrapper'
import {PermissionConfirmationWrapper} from './components/PermissionConfirmationWrapper'
import {PlacementsConfirmationWrapper} from './components/PlacementsConfirmationWrapper'
import {PrivacyConfirmationWrapper} from './components/PrivacyConfirmationWrapper'
import {ReviewScreenWrapper} from './components/ReviewScreenWrapper'
import {isUnsuccessful} from '../../common/lib/apiResult/ApiResult'
import {Footer} from '../registration_wizard_forms/Footer'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import {Header} from '../registration_wizard_forms/Header'
import {isLtiPlacementWithIcon} from '../model/LtiPlacement'
import type {LtiPlacement} from '../model/LtiPlacement'

const I18n = createI18nScope('lti_registrations')

export type DynamicRegistrationWizardProps = {
  dynamicRegistrationUrl: string
  accountId: AccountId
  unifiedToolId?: UnifiedToolId
  unregister: () => void
  onSuccessfulRegistration: () => void
  service: DynamicRegistrationWizardService
  registrationId?: LtiRegistrationId
}

export const DynamicRegistrationWizard = (props: DynamicRegistrationWizardProps) => {
  const {accountId, dynamicRegistrationUrl, service, unifiedToolId, registrationId} = props
  const useDynamicRegistrationWizardState = React.useMemo(() => {
    return mkUseDynamicRegistrationWizardState(service)
  }, [service])
  const dynamicRegistrationWizardState = useDynamicRegistrationWizardState()

  const {loadRegistrationToken, loadRegistration} = dynamicRegistrationWizardState

  React.useEffect(() => {
    if (registrationId) {
      loadRegistration(accountId, registrationId)
    } else {
      loadRegistrationToken(accountId, dynamicRegistrationUrl, unifiedToolId)
    }
  }, [
    accountId,
    dynamicRegistrationUrl,
    loadRegistrationToken,
    unifiedToolId,
    registrationId,
    loadRegistration,
  ])

  const editing = !!props.registrationId

  const state = dynamicRegistrationWizardState.state

  const onCancel = useCallback(async () => {
    props.unregister()
    if (!editing && isReviewingState(state)) {
      const result = await dynamicRegistrationWizardState.deleteKey(
        state._type,
        accountId,
        state.registration.id,
      )

      if (isUnsuccessful(result)) {
        showFlashAlert({
          message: I18n.t(
            'Something went wrong deleting the registration. It can still be deleted manually on the Manage page.',
          ),
          type: 'error',
        })
      }
    }
  }, [editing, state, dynamicRegistrationWizardState, accountId, props])

  switch (state._type) {
    case 'RequestingToken':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <Flex
              justifyItems="center"
              alignItems="center"
              height="100%"
              data-testid="dynamic-reg-modal-loading-registration"
            >
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Loading')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Loading')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
          <Footer
            currentScreen="first"
            onPreviousClicked={onCancel}
            onNextClicked={() => {}}
            disableNextButton={true}
            reviewing={false}
          />
        </>
      )
    case 'WaitingForTool':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody padding="none">
            <iframe
              src={addParams(props.dynamicRegistrationUrl, {
                openid_configuration: state.registrationToken.oidc_configuration_url,
                registration_token: state.registrationToken.token,
              })}
              style={{
                width: '100%',
                height: '100%',
                border: '0',
                display: 'block',
              }}
              title={I18n.t('Register App')}
              data-testid="dynamic-reg-wizard-iframe"
            />
          </RegistrationModalBody>
          <Footer
            reviewing={false}
            currentScreen="first"
            onPreviousClicked={onCancel}
            onNextClicked={() => {}}
            disableNextButton={true}
          />
        </>
      )
    case 'LoadingRegistration':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <Flex
              justifyItems="center"
              alignItems="center"
              height="100%"
              data-testid="dynamic-reg-modal-loading-registration"
            >
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Loading')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Loading Registration')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
        </>
      )
    case 'PermissionConfirmation':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <PermissionConfirmationWrapper
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </RegistrationModalBody>
          <Footer
            reviewing={state.reviewing}
            currentScreen="first"
            onPreviousClicked={async () => {
              props.unregister()
              if (!props.registrationId) {
                const result = await dynamicRegistrationWizardState.deleteKey(
                  state._type,
                  accountId,
                  state.registration.id,
                )
                if (isUnsuccessful(result)) {
                  showFlashAlert({
                    message: I18n.t(
                      'Something went wrong deleting the registration. The registration can still be deleted manually on the Manage page.',
                    ),
                    type: 'error',
                  })
                }
              }
            }}
            onNextClicked={() => {
              if (state.reviewing) {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'Reviewing',
                )
              } else {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'PrivacyLevelConfirmation',
                )
              }
            }}
          />
        </>
      )
    case 'PrivacyLevelConfirmation':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <PrivacyConfirmationWrapper
              overlayStore={state.overlayStore}
              toolName={state.registration.name}
            />
          </RegistrationModalBody>
          <Footer
            currentScreen="intermediate"
            reviewing={state.reviewing}
            onPreviousClicked={() => {
              dynamicRegistrationWizardState.transitionToConfirmationState(
                state._type,
                'PermissionConfirmation',
                false,
              )
            }}
            onNextClicked={() => {
              if (state.reviewing) {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'Reviewing',
                )
              } else {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'PlacementsConfirmation',
                )
              }
            }}
          />
        </>
      )
    case 'PlacementsConfirmation':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <PlacementsConfirmationWrapper
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </RegistrationModalBody>
          <Footer
            reviewing={state.reviewing}
            currentScreen="intermediate"
            onPreviousClicked={() => {
              dynamicRegistrationWizardState.transitionToConfirmationState(
                state._type,
                'PrivacyLevelConfirmation',
                false,
              )
            }}
            onNextClicked={() => {
              if (state.reviewing) {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'Reviewing',
                )
              } else {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'NamingConfirmation',
                )
              }
            }}
          />
        </>
      )
    case 'NamingConfirmation':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <NamingConfirmationWrapper
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </RegistrationModalBody>
          <Footer
            currentScreen="intermediate"
            reviewing={state.reviewing}
            onPreviousClicked={() => {
              dynamicRegistrationWizardState.transitionToConfirmationState(
                state._type,
                'PlacementsConfirmation',
                false,
              )
            }}
            onNextClicked={() => {
              if (state.reviewing) {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'Reviewing',
                )
              } else {
                const placements = state.registration.configuration.placements.map(p => p.placement)
                const disabledPlacements =
                  state.overlayStore.getState().state.overlay.disabled_placements ?? []
                const enabledPlacements = placements.filter(p => !disabledPlacements.includes(p))

                if (enabledPlacements.some(p => isLtiPlacementWithIcon(p))) {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'IconConfirmation',
                  )
                } else {
                  dynamicRegistrationWizardState.transitionToReviewingState(state._type)
                }
              }
            }}
          />
        </>
      )
    case 'IconConfirmation':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <IconConfirmationWrapper
            overlayStore={state.overlayStore}
            registration={state.registration}
            reviewing={state.reviewing}
            transitionToConfirmationState={
              dynamicRegistrationWizardState.transitionToConfirmationState
            }
            transitionToReviewingState={dynamicRegistrationWizardState.transitionToReviewingState}
          />
        </>
      )
    case 'Reviewing':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <ReviewScreenWrapper
            overlayStore={state.overlayStore}
            registration={state.registration}
            transitionToConfirmationState={
              dynamicRegistrationWizardState.transitionToConfirmationState
            }
          />
          <Footer
            currentScreen="last"
            reviewing={state.reviewing}
            onPreviousClicked={() => {
              const placements = state.registration.configuration.placements.map(p => p.placement)
              const disabledPlacements =
                state.overlayStore.getState().state.overlay.disabled_placements ?? []
              const enabledPlacements = placements.filter(p => !disabledPlacements.includes(p))

              if (enabledPlacements.some(p => isLtiPlacementWithIcon(p))) {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'IconConfirmation',
                  false,
                )
              } else {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'NamingConfirmation',
                  false,
                )
              }
            }}
            onNextClicked={() => {
              if (registrationId) {
                dynamicRegistrationWizardState.updateAndClose(
                  accountId,
                  registrationId,
                  state.overlayStore.getState().state.overlay,
                  state.overlayStore.getState().state.adminNickname ?? state.registration.name,
                  props.onSuccessfulRegistration,
                )
              } else {
                dynamicRegistrationWizardState.enableAndClose(
                  accountId,
                  state.registration.id,
                  state.overlayStore.getState().state.overlay,
                  state.overlayStore.getState().state.adminNickname ?? state.registration.name,
                  props.onSuccessfulRegistration,
                )
              }
            }}
            updating={!!registrationId}
          />
        </>
      )
    case 'DeletingDevKey':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          <RegistrationModalBody>
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Deleting App')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Deleting App')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
        </>
      )
    case 'Enabling':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Enabling App')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Enabling App')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
        </>
      )
    case 'Updating':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          {progressBar(state)}
          <RegistrationModalBody>
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Updating App')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Updating App')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
        </>
      )
    case 'Error':
      return (
        <>
          <Header onClose={onCancel} editing={editing} />
          <RegistrationModalBody>
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('Dynamic Registration error')}
              errorCategory="Dynamic Registration"
              errorMessage={state.message}
            />
          </RegistrationModalBody>
        </>
      )
  }
}

const addParams = (url: string, params: Record<string, string>) => {
  const u = new URL(url)
  Object.entries(params).forEach(([key, value]) => {
    u.searchParams.set(key, value)
  })
  return u.toString()
}

const TotalProgressLevels = 7

const ProgressLevels: Record<DynamicRegistrationWizardState['_type'], number> = {
  RequestingToken: 0,
  WaitingForTool: 1,
  LoadingRegistration: 1,
  PermissionConfirmation: 2,
  PrivacyLevelConfirmation: 3,
  PlacementsConfirmation: 4,
  NamingConfirmation: 5,
  IconConfirmation: 6,
  Reviewing: 7,
  Updating: 7,
  Enabling: 7,
  DeletingDevKey: 7,
  Error: 0,
}

const progressBar = (state: DynamicRegistrationWizardState) => (
  <ProgressBar
    meterColor="info"
    shouldAnimate={true}
    size="x-small"
    frameBorder="none"
    screenReaderLabel={I18n.t('Installation Progress')}
    valueNow={ProgressLevels[state._type]}
    valueMax={TotalProgressLevels}
    themeOverride={{
      trackBottomBorderWidth: '0',
    }}
    margin="0"
  />
)
