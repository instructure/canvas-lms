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
import type {AccountId} from '../model/AccountId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {LaunchSettingsConfirmationWrapper} from './components/LaunchSettingsConfirmationWrapper'
import {
  createLti1p3RegistrationWizardState,
  type Lti1p3RegistrationWizardStep,
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
import {isLtiPlacementWithIcon} from '../model/LtiPlacement'
import {Header} from '../registration_wizard_forms/Header'

const I18n = createI18nScope('lti_registrations')

export type Lti1p3RegistrationWizardProps = {
  existingRegistration?: LtiRegistrationWithConfiguration
  accountId: AccountId
  internalConfiguration: InternalLtiConfiguration
  service: Lti1p3RegistrationWizardService
  unregister: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: () => void
}

export const Lti1p3RegistrationWizard = ({
  existingRegistration,
  accountId,
  internalConfiguration,
  service,
  unregister,
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

  const handlePreviousClicked = (prevStep: Lti1p3RegistrationWizardStep) => () => {
    store.setReviewing(false)
    store.setStep(prevStep)
  }

  const handleNextClicked = (nextStep: Lti1p3RegistrationWizardStep) => () => {
    if (store.state.reviewing) {
      store.setStep('Review')
    } else {
      if (nextStep === 'Review') {
        store.setReviewing(true)
      }
      store.setStep(nextStep)
    }
  }

  switch (store.state._step) {
    case 'LaunchSettings':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <LaunchSettingsConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
            reviewing={store.state.reviewing}
            onPreviousClicked={unregister}
            onNextClicked={handleNextClicked('Permissions')}
          />
        </>
      )
    case 'Permissions':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <PermissionConfirmationWrapper
            showAllSettings={true}
            overlayStore={store.state.overlayStore}
            internalConfig={internalConfiguration}
          />
          <Footer
            currentScreen="intermediate"
            reviewing={store.state.reviewing}
            onPreviousClicked={handlePreviousClicked('LaunchSettings')}
            onNextClicked={handleNextClicked('DataSharing')}
          />
        </>
      )
    case 'DataSharing':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <PrivacyConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
          />
          <Footer
            currentScreen="intermediate"
            reviewing={store.state.reviewing}
            onPreviousClicked={handlePreviousClicked('Permissions')}
            onNextClicked={handleNextClicked('Placements')}
          />
        </>
      )
    case 'Placements':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <PlacementsConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
          />
          <Footer
            currentScreen="intermediate"
            reviewing={store.state.reviewing}
            onPreviousClicked={handlePreviousClicked('DataSharing')}
            onNextClicked={handleNextClicked('OverrideURIs')}
          />
        </>
      )
    case 'OverrideURIs':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <OverrideURIsConfirmationWrapper
            overlayStore={store.state.overlayStore}
            internalConfig={internalConfiguration}
            reviewing={store.state.reviewing}
            onPreviousClicked={handlePreviousClicked('Placements')}
            onNextClicked={handleNextClicked('Naming')}
          />
        </>
      )
    case 'Naming':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <NamingConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
          />
          <Footer
            currentScreen="intermediate"
            reviewing={store.state.reviewing}
            onPreviousClicked={handlePreviousClicked('OverrideURIs')}
            onNextClicked={() => {
              const placements = store.state.overlayStore.getState().state.placements.placements
              if (placements?.some(p => isLtiPlacementWithIcon(p))) {
                handleNextClicked('Icons')()
              } else {
                handleNextClicked('Review')()
              }
            }}
          />
        </>
      )
    case 'Icons':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <IconConfirmationWrapper
            internalConfig={internalConfiguration}
            reviewing={store.state.reviewing}
            overlayStore={store.state.overlayStore}
            onPreviousButtonClicked={handlePreviousClicked('Naming')}
            onNextButtonClicked={handleNextClicked('Review')}
          />
        </>
      )
    case 'Review':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <ReviewScreenWrapper
            overlayStore={store.state.overlayStore}
            internalConfig={internalConfiguration}
            transitionTo={store.setStep}
          />
          <Footer
            currentScreen="last"
            onPreviousClicked={() => {
              const placements = store.state.overlayStore.getState().state.placements.placements
              if (placements?.some(p => isLtiPlacementWithIcon(p))) {
                handlePreviousClicked('Icons')()
              } else {
                handlePreviousClicked('Naming')()
              }
            }}
            updating={!!existingRegistration}
            onNextClicked={() => {
              if (existingRegistration) {
                store.update(
                  onSuccessfulRegistration,
                  accountId,
                  existingRegistration.id,
                  unifiedToolId,
                )
              } else {
                store.install(onSuccessfulRegistration, accountId, unifiedToolId)
              }
            }}
            reviewing={store.state.reviewing}
          />
        </>
      )
    case 'Installing':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
          <RegistrationModalBody>
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Installing App')} />
              </Flex.Item>
              <Flex.Item>{I18n.t('Installing App')}</Flex.Item>
            </Flex>
          </RegistrationModalBody>
        </>
      )
    case 'Updating':
      return (
        <>
          <Header onClose={unregister} editing={!!existingRegistration} />
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
          <Header onClose={unregister} editing={!!existingRegistration} />
          <RegistrationModalBody>
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('Dynamic Registration error')}
              errorCategory="Dynamic Registration"
              errorMessage={store.state.errorMessage}
            />
          </RegistrationModalBody>
        </>
      )
  }
}
