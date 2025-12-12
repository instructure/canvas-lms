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
  type DynamicRegistrationActions,
  ConfirmationStateType,
} from './DynamicRegistrationWizardState'
import {IconConfirmationWrapper} from '../lti_1p3_registration_form/components/IconConfirmationWrapper'
import {NamingConfirmationWrapper} from '../lti_1p3_registration_form/components/NamingConfirmationWrapper'
import {PermissionConfirmationWrapper} from '../lti_1p3_registration_form/components/PermissionConfirmationWrapper'
import {PlacementsConfirmationWrapper} from '../lti_1p3_registration_form/components/PlacementsConfirmationWrapper'
import {PrivacyConfirmationWrapper} from '../lti_1p3_registration_form/components/PrivacyConfirmationWrapper'
import {ReviewScreenWrapper} from '../lti_1p3_registration_form/components/ReviewScreenWrapper'
import {isUnsuccessful} from '../../common/lib/apiResult/ApiResult'
import {Footer} from '../registration_wizard_forms/Footer'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import {Header} from '../registration_wizard_forms/Header'
import {isLtiPlacementWithIcon} from '../model/LtiPlacement'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'
import {getInputIdForField} from '../registration_overlay/validateLti1p3RegistrationOverlayState'
import {Lti1p3RegistrationWizardStep} from '../lti_1p3_registration_form/Lti1p3RegistrationWizardState'

const I18n = createI18nScope('lti_registrations')

export type DynamicRegistrationWizardProps = {
  dynamicRegistrationUrl: string
  accountId: AccountId
  unifiedToolId?: UnifiedToolId
  onDismiss: () => boolean
  onSuccessfulRegistration: (id: LtiRegistrationId) => void
  service: DynamicRegistrationWizardService
  registrationId?: LtiRegistrationId
}

export const DynamicRegistrationWizard = (props: DynamicRegistrationWizardProps) => {
  const {
    accountId,
    dynamicRegistrationUrl,
    service,
    unifiedToolId,
    registrationId,
    onSuccessfulRegistration,
  } = props
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
    if (props.onDismiss() && !editing && isReviewingState(state)) {
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

  const onPreviousClicked = useCallback(() => {
    if (
      state._type === 'WaitingForTool' ||
      state._type === 'LoadingRegistration' ||
      state._type === 'RequestingToken'
    ) {
      props.onDismiss()
    } else if (state._type === 'PermissionConfirmation') {
      if (props.onDismiss() && !props.registrationId) {
        dynamicRegistrationWizardState
          .deleteKey(state._type, accountId, state.registration.id)
          .then(result => {
            if (isUnsuccessful(result)) {
              showFlashAlert({
                message: I18n.t(
                  'Something went wrong deleting the registration. The registration can still be deleted manually on the Manage page.',
                ),
                type: 'error',
              })
            }
          })
      }
    } else if (isReviewingState(state)) {
      dynamicRegistrationWizardState.previousStep(state._type)
    }
  }, [state, dynamicRegistrationWizardState, accountId, props])

  const onNextClicked = useCallback(() => {
    dynamicRegistrationWizardState.advanceStep(
      accountId,
      errors => {
        if (errors.length > 0) {
          // focus the first error
          document.getElementById(getInputIdForField(errors[0].field))?.focus()
        }
      },
      registrationId,
      onSuccessfulRegistration,
    )
  }, [dynamicRegistrationWizardState, accountId, registrationId, onSuccessfulRegistration])

  return (
    <>
      <Header onClose={onCancel} editing={editing} />
      {shouldShowProgressBar(state._type) && progressBar(state)}
      {renderStepContent(state, props, {
        transitionToConfirmationState: dynamicRegistrationWizardState.transitionToConfirmationState,
        transitionToReviewingState: dynamicRegistrationWizardState.transitionToReviewingState,
      })}
      {shouldShowFooter(state._type) && (
        <Footer
          currentScreen={getFooterCurrentScreen(state._type)}
          reviewing={isReviewingState(state) ? state.reviewing : false}
          onPreviousClicked={onPreviousClicked}
          onNextClicked={onNextClicked}
          disableNextButton={!dynamicRegistrationWizardState.canProceed()}
          updating={!!registrationId}
        />
      )}
    </>
  )
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

const getFooterCurrentScreen = (stateType: DynamicRegistrationWizardState['_type']) => {
  switch (stateType) {
    case 'RequestingToken':
    case 'WaitingForTool':
    case 'PermissionConfirmation':
      return 'first'
    case 'Reviewing':
      return 'last'
    default:
      return 'intermediate'
  }
}

const shouldShowProgressBar = (stateType: DynamicRegistrationWizardState['_type']) => {
  return stateType !== 'DeletingDevKey' && stateType !== 'Error'
}

const shouldShowFooter = (stateType: DynamicRegistrationWizardState['_type']) => {
  return !['DeletingDevKey', 'Enabling', 'Updating', 'Error'].includes(stateType)
}

const renderStepContent = (
  state: DynamicRegistrationWizardState,
  props: DynamicRegistrationWizardProps,
  actions: {
    transitionToConfirmationState: DynamicRegistrationActions['transitionToConfirmationState']
    transitionToReviewingState: DynamicRegistrationActions['transitionToReviewingState']
  },
) => {
  switch (state._type) {
    case 'RequestingToken':
    case 'LoadingRegistration':
      return (
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
            <Flex.Item>
              {state._type === 'RequestingToken'
                ? I18n.t('Loading')
                : I18n.t('Loading Registration')}
            </Flex.Item>
          </Flex>
        </RegistrationModalBody>
      )
    case 'WaitingForTool':
      return (
        <RegistrationModalBody padding="none" bottomSpacing={false}>
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
      )
    case 'PermissionConfirmation':
      return (
        <PermissionConfirmationWrapper
          internalConfig={state.registration.configuration}
          overlayStore={state.overlayStore}
          scopesSupported={state.registration.configuration.scopes}
          showAllSettings={false}
        />
      )
    case 'PrivacyLevelConfirmation':
      return (
        <PrivacyConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.configuration}
        />
      )
    case 'PlacementsConfirmation':
      return (
        <PlacementsConfirmationWrapper
          internalConfig={state.registration.configuration}
          overlayStore={state.overlayStore}
          supportedPlacements={state.registration.configuration.placements.map(p => p.placement)}
        />
      )
    case 'NamingConfirmation':
      return (
        <NamingConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.configuration}
        />
      )
    case 'IconConfirmation':
      return (
        <IconConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.configuration}
          reviewing={state.reviewing}
          includeFooter={false}
        />
      )
    case 'Reviewing':
      return (
        <ReviewScreenWrapper
          includeLaunchSettings={false}
          overlayStore={state.overlayStore}
          internalConfig={state.registration.configuration}
          transitionTo={step => {
            // Map Lti1p3RegistrationWizardStep to ConfirmationStateType
            const stepMapping: Partial<
              Record<Lti1p3RegistrationWizardStep, ConfirmationStateType>
            > = {
              Permissions: 'PermissionConfirmation',
              DataSharing: 'PrivacyLevelConfirmation',
              Placements: 'PlacementsConfirmation',
              Naming: 'NamingConfirmation',
              Icons: 'IconConfirmation',
            }
            const mappedStep = stepMapping[step]
            if (mappedStep) {
              actions.transitionToConfirmationState('Reviewing', mappedStep, true)
            }
          }}
        />
      )
    case 'DeletingDevKey':
    case 'Enabling':
    case 'Updating':
      return (
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={loadingText(state._type)} />
            </Flex.Item>
            <Flex.Item>{loadingText(state._type)}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      )
    case 'Error':
      return (
        <RegistrationModalBody>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Dynamic Registration error')}
            errorCategory="Dynamic Registration"
            errorMessage={state.message}
          />
        </RegistrationModalBody>
      )
    default:
      return null
  }
}

const loadingText = (step: 'Enabling' | 'Updating' | 'DeletingDevKey') => {
  switch (step) {
    case 'Enabling':
      return I18n.t('Enabling App')
    case 'Updating':
      return I18n.t('Updating App')
    case 'DeletingDevKey':
      return I18n.t('Deleting App')
  }
}
