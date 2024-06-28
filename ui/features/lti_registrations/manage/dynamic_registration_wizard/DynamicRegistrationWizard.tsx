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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import React from 'react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import type {AccountId} from '../model/AccountId'
import {
  mkUseDynamicRegistrationWizardState,
  type DynamicRegistrationWizardState,
} from './DynamicRegistrationWizardState'
import type {DynamicRegistrationWizardService} from './DynamicRegistrationWizardService'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {PermissionConfirmation} from './components/PermissionConfirmation'
import {PrivacyConfirmation} from './components/PrivacyConfirmation'
import {PlacementsConfirmation} from './components/PlacementsConfirmation'
import {NamingConfirmation} from './components/NamingConfirmation'
import {IconConfirmation} from './components/IconConfirmation'
import {ReviewScreen} from './components/ReviewScreen'
import {ProgressBar} from '@instructure/ui-progress'

const I18n = useI18nScope('lti_registrations')

export type DynamicRegistrationWizardProps = {
  dynamicRegistrationUrl: string
  accountId: AccountId
  unregister: () => void
  service: DynamicRegistrationWizardService
}

export const DynamicRegistrationWizard = (props: DynamicRegistrationWizardProps) => {
  const {accountId, dynamicRegistrationUrl, service} = props
  const useDynamicRegistrationWizardState = React.useMemo(() => {
    return mkUseDynamicRegistrationWizardState(service)
  }, [service])
  const dynamicRegistrationWizardState = useDynamicRegistrationWizardState()

  const {loadRegistrationToken} = dynamicRegistrationWizardState

  React.useEffect(() => {
    loadRegistrationToken(accountId, dynamicRegistrationUrl)
  }, [accountId, dynamicRegistrationUrl, loadRegistrationToken])

  const state = dynamicRegistrationWizardState.state

  switch (state._type) {
    case 'RequestingToken':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <View as="div" height="20rem" data-testid="dynamic-reg-modal-loading-registration">
              <Flex justifyItems="center" alignItems="center" height="100%">
                <Flex.Item>
                  <Spinner renderTitle={I18n.t('Loading')} />
                </Flex.Item>
                <Flex.Item>{I18n.t('Loading')}</Flex.Item>
              </Flex>
            </View>
          </Modal.Body>
          <Modal.Footer>
            <Button color="secondary" type="submit" onClick={props.unregister}>
              {I18n.t('Cancel')}
            </Button>
            <Button margin="small" color="primary" type="submit" disabled={true}>
              {I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'WaitingForTool':
      return (
        <>
          {progressBar(state)}
          <iframe
            src={addParams(props.dynamicRegistrationUrl, {
              openid_configuration: state.registrationToken.oidc_configuration_url,
              registration_token: state.registrationToken.token,
            })}
            style={{
              width: '100%',
              height: '600px',
              border: '0',
              display: 'block',
            }}
            title={I18n.t('Register App')}
            data-testid="dynamic-reg-wizard-iframe"
          />
          <Modal.Footer>
            <Button color="secondary" type="submit" onClick={props.unregister}>
              {I18n.t('Cancel')}
            </Button>
            <Button margin="small" color="primary" type="submit" disabled={true}>
              {I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'LoadingRegistration':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <View as="div" height="20rem" data-testid="dynamic-reg-modal-loading-registration">
              <Flex justifyItems="center" alignItems="center" height="100%">
                <Flex.Item>
                  <Spinner renderTitle={I18n.t('Loading')} />
                </Flex.Item>
                <Flex.Item>{I18n.t('Loading Registration')}</Flex.Item>
              </Flex>
            </View>
          </Modal.Body>
        </>
      )
    case 'PermissionConfirmation':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <PermissionConfirmation
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </Modal.Body>
          <Modal.Footer>
            <Button
              margin="small"
              color="secondary"
              type="submit"
              disabled={false}
              onClick={async () => {
                props.unregister()
                const result = await dynamicRegistrationWizardState.deleteKey(
                  state._type,
                  state.registration.developer_key_id
                )
                if (result._type !== 'success') {
                  showFlashAlert({
                    message: I18n.t(
                      'Something went wrong deleting the registration. The registration can still be deleted manually on the Manage page.'
                    ),
                    type: 'error',
                  })
                }
              }}
            >
              {I18n.t('Cancel')}
            </Button>
            <Button
              margin="small"
              color="primary"
              type="submit"
              onClick={() => {
                if (state.reviewing) {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'Reviewing'
                  )
                } else {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'PrivacyLevelConfirmation'
                  )
                }
              }}
            >
              {state.reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'PrivacyLevelConfirmation':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <PrivacyConfirmation
              overlayStore={state.overlayStore}
              toolName={state.registration.client_name}
            />
          </Modal.Body>
          <Modal.Footer>
            <Button
              margin="small"
              color="secondary"
              type="submit"
              onClick={() => {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'PermissionConfirmation'
                )
              }}
            >
              {I18n.t('Previous')}
            </Button>
            <Button
              margin="small"
              color="primary"
              type="submit"
              onClick={() => {
                if (state.reviewing) {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'Reviewing'
                  )
                } else {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'PlacementsConfirmation'
                  )
                }
              }}
            >
              {state.reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'PlacementsConfirmation':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <PlacementsConfirmation
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </Modal.Body>
          <Modal.Footer>
            <Button
              margin="small"
              color="secondary"
              type="submit"
              onClick={() => {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'PrivacyLevelConfirmation'
                )
              }}
            >
              {I18n.t('Previous')}
            </Button>
            <Button
              margin="small"
              color="primary"
              type="submit"
              onClick={() => {
                if (state.reviewing) {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'Reviewing'
                  )
                } else {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'NamingConfirmation'
                  )
                }
              }}
            >
              {state.reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'NamingConfirmation':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <NamingConfirmation
              registration={state.registration}
              overlayStore={state.overlayStore}
            />
          </Modal.Body>
          <Modal.Footer>
            <Button
              margin="small"
              color="secondary"
              type="submit"
              onClick={() => {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'PlacementsConfirmation'
                )
              }}
            >
              {I18n.t('Previous')}
            </Button>
            <Button
              margin="small"
              color="primary"
              type="submit"
              onClick={() => {
                if (state.reviewing) {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'Reviewing'
                  )
                } else {
                  dynamicRegistrationWizardState.transitionToConfirmationState(
                    state._type,
                    'IconConfirmation'
                  )
                }
              }}
            >
              {state.reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'IconConfirmation':
      return (
        <>
          {progressBar(state)}
          <IconConfirmation
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
          {progressBar(state)}
          <Modal.Body>
            <ReviewScreen
              overlayStore={state.overlayStore}
              registration={state.registration}
              transitionToConfirmationState={
                dynamicRegistrationWizardState.transitionToConfirmationState
              }
            />
          </Modal.Body>
          <Modal.Footer>
            <Button
              color="secondary"
              type="submit"
              onClick={() => {
                dynamicRegistrationWizardState.transitionToConfirmationState(
                  state._type,
                  'IconConfirmation'
                )
              }}
            >
              {I18n.t('Previous')}
            </Button>
            <Button
              margin="small"
              color="primary"
              type="submit"
              onClick={() => {
                dynamicRegistrationWizardState.enableAndClose(
                  accountId,
                  state.registration.id,
                  state.registration.lti_registration_id,
                  state.registration.developer_key_id,
                  state.overlayStore.getState().state.registration,
                  state.overlayStore.getState().state.adminNickname ??
                    state.registration.client_name,
                  props.unregister
                )
              }}
            >
              {I18n.t('Install Developer Key')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'DeletingDevKey':
      return (
        <Modal.Body>
          <View as="div" height="20rem" data-testid="dynamic-reg-modal-loading-registration">
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Deleting Registration')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Deleting Registration')}</Flex.Item>
            </Flex>
          </View>
        </Modal.Body>
      )
    case 'Enabling':
      return (
        <>
          {progressBar(state)}
          <Modal.Body>
            <View as="div" height="20rem" data-testid="dynamic-reg-modal-loading-registration">
              <Flex justifyItems="center" alignItems="center" height="100%">
                <Flex.Item>
                  <Spinner renderTitle={I18n.t('Enabling Registration')} />
                </Flex.Item>
                <Flex.Item>{I18n.t('Enabling Registration')}</Flex.Item>
              </Flex>
            </View>
          </Modal.Body>
        </>
      )
    case 'Error':
      return (
        <div>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Dynamic Registration error')}
            errorCategory="Dynamic Registration"
            errorMessage={state.message}
          />
        </div>
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

const ProgressLevels = {
  RequestingToken: 0,
  WaitingForTool: 1,
  LoadingRegistration: 1,
  PermissionConfirmation: 2,
  PrivacyLevelConfirmation: 3,
  PlacementsConfirmation: 4,
  NamingConfirmation: 5,
  IconConfirmation: 6,
  Reviewing: 7,
  Enabling: 7,
  DeletingDevKey: 7,
  Error: 0,
}

const progressBar = (state: DynamicRegistrationWizardState) => (
  <ProgressBar
    meterColor="info"
    shouldAnimate={true}
    size="x-small"
    screenReaderLabel={I18n.t('Installation Progress')}
    valueNow={ProgressLevels[state._type]}
    valueMax={TotalProgressLevels}
    themeOverride={{
      trackBottomBorderWidth: '0',
    }}
    margin="0"
  />
)
