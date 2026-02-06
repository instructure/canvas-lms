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

import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import * as React from 'react'
import {
  useInheritedKeyWizardState,
  type InheritedKeyWizardState,
  isInheritedStep,
} from './InheritedKeyRegistrationWizardState'
import type {InheritedKeyService} from './InheritedKeyService'
import type {AccountId} from '../model/AccountId'
import type {Lti1p3RegistrationWizardStep} from '../lti_1p3_registration_form/Lti1p3RegistrationWizardState'
import {InheritedKeyRegistrationReview} from './InheritedKeyRegistrationReview'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {formatApiResultError, UnsuccessfulApiResult} from '../../common/lib/apiResult/ApiResult'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {ProgressBar} from '@instructure/ui-progress'
import {Footer} from '../registration_wizard_forms/Footer'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {InheritedLaunchSettingsConfirmationWrapper} from './InheritedLaunchSettingsConfirmationWrapper'
import {InheritedIconConfirmationWrapper} from './InheritedIconConfirmationWrapper'
import {InheritedOverrideURIsConfirmationWrapper} from './InheritedOverrideURIsConfirmationWrapper'
import {PrivacyConfirmationWrapper} from '../lti_1p3_registration_form/components/PrivacyConfirmationWrapper'
import {PlacementsConfirmationWrapper} from '../lti_1p3_registration_form/components/PlacementsConfirmationWrapper'
import {NamingConfirmationWrapper} from '../lti_1p3_registration_form/components/NamingConfirmationWrapper'
import {ReviewScreenWrapper} from '../lti_1p3_registration_form/components/ReviewScreenWrapper'
import {Header} from '../registration_wizard_forms/Header'
import {PermissionConfirmationWrapper} from '../lti_1p3_registration_form/components/PermissionConfirmationWrapper'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = createI18nScope('lti_registrations')

export type InheritedKeyRegistrationWizardProps = {
  service: InheritedKeyService
  accountId: AccountId
}

export const InheritedKeyRegistrationWizard = (props: InheritedKeyRegistrationWizardProps) => {
  const {
    state,
    registerDependencies,
    install,
    close,
    loaded,
    advanceStep,
    previousStep,
    transitionToCustomizationState,
  } = useInheritedKeyWizardState()
  const label = I18n.t('Install App')
  const isTemplateFlagEnabled = window.ENV?.FEATURES?.lti_registrations_templates

  React.useEffect(() => {
    registerDependencies(
      props.service,
      props.accountId,
      () => {
        showFlashSuccess(I18n.t('App installed successfully.'))
      },
      (error: UnsuccessfulApiResult) => {
        showFlashError(formatApiResultError(error))
      },
    )
  }, [props.service, props.accountId, registerDependencies])

  const handlePreviousStep = React.useCallback(() => {
    if (isFirstScreen(state._type)) {
      close()
    }
    if (isInheritedStep(state._type)) {
      previousStep()
    }
  }, [previousStep, state._type, close])

  const handleTransitionTo = React.useCallback(
    (step: Lti1p3RegistrationWizardStep) => {
      if (state._type === 'Review' && isInheritedStep(step)) {
        transitionToCustomizationState(step)
      }
    },
    [transitionToCustomizationState, state._type],
  )

  if (isTemplateFlagEnabled) {
    return (
      <Modal label={label} open={state.open} size="medium">
        <Header onClose={close} />

        {shouldShowProgressBar(state._type) && progressBar(state._type)}

        {renderCustomizationBody(state, handleTransitionTo)}

        <Footer
          reviewing={state.reviewing}
          currentScreen={getFooterCurrentScreen(state._type)}
          onPreviousClicked={handlePreviousStep}
          onNextClicked={advanceStep}
          disableNextButton={['Error', 'Initial', 'RequestingRegistration', 'Installing'].includes(
            state._type,
          )}
          disablePreviousButton={state._type === 'Installing'}
        />
      </Modal>
    )
  }

  return (
    <Modal label={label} open={state.open} size="medium">
      <Header onClose={close} />

      {renderBody(state)}

      <Modal.Footer>
        <Button color="secondary" margin="0 xx-small 0 0" onClick={close}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          margin="0 0 0 xx-small"
          disabled={state._type !== 'RegistrationLoaded'}
          onClick={install}
        >
          {I18n.t('Install App')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const TotalProgressLevels = 8

const ProgressLevels: Record<InheritedKeyWizardState['_type'], number> = {
  Initial: 0,
  RequestingRegistration: 0,
  RegistrationLoaded: 0,
  Error: 0,
  LaunchSettings: 1,
  Permissions: 2,
  DataSharing: 3,
  Placements: 4,
  OverrideURIs: 5,
  Naming: 6,
  Icons: 7,
  Review: 8,
  Installing: 8,
}

const progressBar = (step: InheritedKeyWizardState['_type']) => (
  <ProgressBar
    meterColor="info"
    shouldAnimate={true}
    size="x-small"
    frameBorder="none"
    screenReaderLabel={I18n.t('Installation Progress')}
    valueNow={ProgressLevels[step]}
    valueMax={TotalProgressLevels}
    themeOverride={{
      trackBottomBorderWidth: '0',
    }}
    margin="0"
  />
)

const shouldShowProgressBar = (step: InheritedKeyWizardState['_type']) => {
  return step !== 'Initial' && step !== 'RequestingRegistration'
}

const isFirstScreen = (step: InheritedKeyWizardState['_type']) => {
  return ['RequestingRegistration', 'Initial', 'LaunchSettings', 'Error'].includes(step)
}

const getFooterCurrentScreen = (
  step: InheritedKeyWizardState['_type'],
): 'first' | 'intermediate' | 'last' => {
  if (isFirstScreen(step)) {
    return 'first'
  } else if (step === 'Review' || step === 'Installing') {
    return 'last'
  }
  return 'intermediate'
}

const renderCustomizationBody = (
  state: InheritedKeyWizardState,
  handleTransitionTo: (step: Lti1p3RegistrationWizardStep) => void,
) => {
  switch (state._type) {
    case 'RequestingRegistration':
    case 'Initial':
      return loadingScreen(I18n.t('Loading'))

    case 'LaunchSettings':
      return (
        <InheritedLaunchSettingsConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
        />
      )

    case 'Permissions':
      return (
        <PermissionConfirmationWrapper
          showAllSettings={true}
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
          scopesSupported={state.registration.overlaid_configuration.scopes}
        />
      )

    case 'DataSharing':
      return (
        <PrivacyConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
        />
      )

    case 'Placements':
      return (
        <PlacementsConfirmationWrapper
          internalConfig={state.registration.overlaid_configuration}
          overlayStore={state.overlayStore}
          supportedPlacements={state.registration.overlaid_configuration.placements.map(
            p => p.placement,
          )}
        />
      )

    case 'OverrideURIs':
      return <InheritedOverrideURIsConfirmationWrapper overlayStore={state.overlayStore} />

    case 'Icons':
      return (
        <InheritedIconConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
        />
      )

    case 'Naming':
      return (
        <NamingConfirmationWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
        />
      )

    case 'Review':
      return (
        <ReviewScreenWrapper
          overlayStore={state.overlayStore}
          internalConfig={state.registration.overlaid_configuration}
          transitionTo={handleTransitionTo}
          includeLaunchSettings={false}
          includeIconUrls={false}
        />
      )

    case 'Installing':
      return loadingScreen(I18n.t('Installing App...'))

    case 'Error': {
      const message = formatApiResultError(state.result as UnsuccessfulApiResult)
      return (
        <GenericErrorPage
          image={errorShipUrl}
          title={I18n.t('Error')}
          message={message}
          errorMessage={message}
        />
      )
    }

    default:
      return null
  }
}

const loadingScreen = (title: string) => (
  <RegistrationModalBody>
    <Flex
      justifyItems="center"
      alignItems="center"
      height="200px"
      data-testid="inherited-modal-loading-registration"
    >
      <Flex.Item>
        <Spinner renderTitle={title} />
      </Flex.Item>
      <Flex.Item>{title}</Flex.Item>
    </Flex>
  </RegistrationModalBody>
)

const renderBody = (state: InheritedKeyWizardState) => {
  switch (state._type) {
    case 'RequestingRegistration':
    case 'Initial':
      return loadingScreen(I18n.t('Loading'))

    case 'Error': {
      const message = formatApiResultError(state.result as UnsuccessfulApiResult)
      return (
        <GenericErrorPage
          image={errorShipUrl}
          title={I18n.t('Error')}
          message={message}
          errorMessage={message}
        />
      )
    }

    case 'RegistrationLoaded':
      return (
        <RegistrationModalBody>
          <InheritedKeyRegistrationReview result={state.result} />
        </RegistrationModalBody>
      )

    default:
      return null
  }
}
