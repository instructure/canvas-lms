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

import {useScope as createI18nScope} from '@canvas/i18n'
import * as React from 'react'
import {ProgressBar} from '@instructure/ui-progress'
import type {AccountId} from '../model/AccountId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {LaunchSettingsConfirmationWrapper} from './components/LaunchSettingsConfirmationWrapper'
import {
  createLti1p3RegistrationWizardState,
  type Lti1p3RegistrationWizardStep,
  type Lti1p3RegistrationWizardStore,
} from './Lti1p3RegistrationWizardState'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {PermissionConfirmationWrapper} from './components/PermissionConfirmationWrapper'
import {PlacementsConfirmationWrapper} from './components/PlacementsConfirmationWrapper'
import {PrivacyConfirmationWrapper} from './components/PrivacyConfirmationWrapper'
import {OverrideURIsConfirmationWrapper} from './components/OverrideURIsConfirmationWrapper'
import {NamingConfirmationWrapper} from './components/NamingConfirmationWrapper'
import {IconConfirmationWrapper} from './components/IconConfirmationWrapper'
import {ReviewScreenWrapper} from './components/ReviewScreenWrapper'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import type {Lti1p3RegistrationWizardService} from './Lti1p3RegistrationWizardService'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {toUndefined} from '../../common/lib/toUndefined'
import {Footer} from '../registration_wizard_forms/Footer'
import {Header} from '../registration_wizard_forms/Header'
import {LaunchTypeSpecificSettingsConfirmationWrapper} from './components/LaunchTypeSpecificSettingsConfirmationWrapper'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import {getInputIdForField} from '../registration_overlay/validateLti1p3RegistrationOverlayState'

const I18n = createI18nScope('lti_registrations')

const getFooterCurrentScreen = (step: Lti1p3RegistrationWizardStep) => {
  if (step === 'LaunchSettings') return 'first'
  if (step === 'Review') return 'last'
  return 'intermediate'
}

const shouldShowFooter = (step: Lti1p3RegistrationWizardStep) => {
  return !['Installing', 'Updating', 'Error'].includes(step)
}

const TotalProgressLevels = 9
const ProgressLevels: Record<Lti1p3RegistrationWizardStep, number> = {
  LaunchSettings: 1,
  Permissions: 2,
  DataSharing: 3,
  Placements: 4,
  EulaSettings: 5,
  OverrideURIs: 6,
  Naming: 7,
  Icons: 8,
  Review: 9,
  Installing: 9,
  Updating: 9,
  Error: 0,
}

const progressBar = (step: Lti1p3RegistrationWizardStep) => (
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
  />
)

const shouldShowProgressBar = (step: Lti1p3RegistrationWizardStep) => {
  return step !== 'Error'
}

const renderStepContent = (
  step: Lti1p3RegistrationWizardStep,
  props: Lti1p3RegistrationWizardProps,
  storeActions: Lti1p3RegistrationWizardStore,
) => {
  const {internalConfiguration} = props

  switch (step) {
    case 'LaunchSettings':
      return (
        <LaunchSettingsConfirmationWrapper
          internalConfig={internalConfiguration}
          overlayStore={storeActions.state.overlayStore}
          reviewing={storeActions.state.reviewing}
          hasClickedNext={storeActions.state.hasClickedNext}
        />
      )
    case 'Permissions':
      return (
        <PermissionConfirmationWrapper
          showAllSettings={true}
          overlayStore={storeActions.state.overlayStore}
          internalConfig={internalConfiguration}
        />
      )
    case 'DataSharing':
      return (
        <PrivacyConfirmationWrapper
          internalConfig={internalConfiguration}
          overlayStore={storeActions.state.overlayStore}
        />
      )
    case 'Placements':
      return (
        <PlacementsConfirmationWrapper
          internalConfig={internalConfiguration}
          overlayStore={storeActions.state.overlayStore}
        />
      )
    case 'EulaSettings':
      return (
        <LaunchTypeSpecificSettingsConfirmationWrapper
          settingType="LtiEulaRequest"
          internalConfig={internalConfiguration}
          overlayStore={storeActions.state.overlayStore}
        />
      )
    case 'OverrideURIs':
      return (
        <OverrideURIsConfirmationWrapper
          overlayStore={storeActions.state.overlayStore}
          internalConfig={internalConfiguration}
          reviewing={storeActions.state.reviewing}
          hasClickedNext={storeActions.state.hasClickedNext}
        />
      )
    case 'Naming':
      return (
        <NamingConfirmationWrapper
          internalConfig={internalConfiguration}
          overlayStore={storeActions.state.overlayStore}
        />
      )
    case 'Icons':
      return (
        <IconConfirmationWrapper
          internalConfig={internalConfiguration}
          reviewing={storeActions.state.reviewing}
          overlayStore={storeActions.state.overlayStore}
          hasClickedNext={storeActions.state.hasClickedNext}
        />
      )
    case 'Review':
      return (
        <ReviewScreenWrapper
          overlayStore={storeActions.state.overlayStore}
          internalConfig={internalConfiguration}
          transitionTo={step => {
            storeActions.setStep(step)
          }}
        />
      )
    case 'Installing':
    case 'Updating': {
      const loadingText = step === 'Installing' ? I18n.t('Installing App') : I18n.t('Updating App')
      return (
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={loadingText} />
            </Flex.Item>
            <Flex.Item>{loadingText}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      )
    }
    case 'Error':
      return (
        <RegistrationModalBody>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Dynamic Registration error')}
            errorCategory="Dynamic Registration"
            errorMessage={storeActions.state.errorMessage}
          />
        </RegistrationModalBody>
      )
    default:
      return null
  }
}

export type Lti1p3RegistrationWizardProps = {
  existingRegistration?: LtiRegistrationWithConfiguration
  accountId: AccountId
  internalConfiguration: InternalLtiConfiguration
  service: Lti1p3RegistrationWizardService
  onDismiss: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: (registrationId: LtiRegistrationId) => void
}

export const Lti1p3RegistrationWizard = ({
  existingRegistration,
  accountId,
  internalConfiguration,
  service,
  onDismiss,
  unifiedToolId,
  onSuccessfulRegistration,
}: Lti1p3RegistrationWizardProps) => {
  const existingAdminNickname = existingRegistration?.admin_nickname
  const existingOverlayData = existingRegistration?.overlay?.data

  const useLti1p3RegistrationWizardStore = React.useMemo(() => {
    return createLti1p3RegistrationWizardState({
      adminNickname: toUndefined(existingAdminNickname),
      internalConfig: internalConfiguration,
      service,
      existingOverlay: toUndefined(existingOverlayData),
    })
  }, [internalConfiguration, service, existingAdminNickname, existingOverlayData])

  const store = useLti1p3RegistrationWizardStore()
  const currentState = store

  return (
    <>
      <Header onClose={onDismiss} editing={!!existingRegistration} />
      {shouldShowProgressBar(currentState.state._step) && progressBar(currentState.state._step)}
      {renderStepContent(
        currentState.state._step,
        {
          existingRegistration,
          accountId,
          internalConfiguration,
          service,
          onDismiss,
          unifiedToolId,
          onSuccessfulRegistration,
        },
        currentState,
      )}
      {shouldShowFooter(currentState.state._step) && (
        <Footer
          currentScreen={getFooterCurrentScreen(currentState.state._step)}
          reviewing={currentState.state.reviewing}
          onPreviousClicked={
            currentState.state._step === 'LaunchSettings'
              ? onDismiss
              : () => currentState.previousStep(currentState.state._step)
          }
          onNextClicked={() =>
            currentState.advanceStep(
              accountId,
              onSuccessfulRegistration,
              errors => {
                if (errors.length > 0) {
                  // focus the first error
                  document.getElementById(getInputIdForField(errors[0].field))?.focus()
                }
              },
              existingRegistration,
              unifiedToolId,
            )
          }
          disableNextButton={!currentState.canProceed(currentState.state._step)}
          updating={!!existingRegistration}
        />
      )}
    </>
  )
}
