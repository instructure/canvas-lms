/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import {Flex} from '@instructure/ui-flex'
import {ProgressBar} from '@instructure/ui-progress'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import React, {useCallback} from 'react'
import {useQueryClient, useMutation} from '@tanstack/react-query'
import {isSuccessful} from '../../common/lib/apiResult/ApiResult'
import {applyLtiRegistrationUpdateRequest} from '../api/ltiImsRegistration'
import {IconConfirmationWrapper} from '../lti_1p3_registration_form/components/IconConfirmationWrapper'
import {NamingConfirmationWrapper} from '../lti_1p3_registration_form/components/NamingConfirmationWrapper'
import {PermissionConfirmationWrapper} from '../lti_1p3_registration_form/components/PermissionConfirmationWrapper'
import {PlacementsConfirmationWrapper} from '../lti_1p3_registration_form/components/PlacementsConfirmationWrapper'
import {PrivacyConfirmationWrapper} from '../lti_1p3_registration_form/components/PrivacyConfirmationWrapper'
import type {AccountId} from '../model/AccountId'
import type {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import type {LtiPlacement} from '../model/LtiPlacement'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {Header} from '../registration_wizard_forms/Header'
import {RegistrationUpdateFooter} from './RegistrationUpdateFooter'
import {
  mkUseRegistrationUpdateWizardState,
  RegistrationUpdateWizardStepOrder,
} from './RegistrationUpdateWizardState'
import {createLti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {convertToLtiConfigurationOverlay} from '../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'
import {RegistrationUpdateReview} from './RegistrationUpdateReview'
import {Modal} from '@instructure/ui-modal'

const I18n = createI18nScope('lti_registrations')

export interface RegistrationUpdateWizardInnerProps {
  accountId: AccountId
  registrationUpdateRequest: LtiRegistrationUpdateRequest
  registration: LtiRegistrationWithConfiguration
  onDismiss: () => void
  onSuccess: () => void
}

export const RegistrationUpdateWizardInner = ({
  accountId,
  registrationUpdateRequest,
  registration,
  onDismiss,
  onSuccess,
}: RegistrationUpdateWizardInnerProps) => {
  const queryClient = useQueryClient()
  const appName = registrationUpdateRequest.internal_lti_configuration.title

  const applyUpdateMutation = useMutation({
    mutationFn: (ltiOverlay: LtiConfigurationOverlay) =>
      applyLtiRegistrationUpdateRequest(
        accountId,
        registrationUpdateRequest.lti_registration_id,
        registrationUpdateRequest.id,
        ltiOverlay,
      ),
    onSuccess: result => {
      if (isSuccessful(result)) {
        queryClient.invalidateQueries({
          queryKey: [
            accountId,
            'lti_registration_update_request',
            registrationUpdateRequest.lti_registration_id,
            registrationUpdateRequest.id,
          ],
        })

        queryClient.invalidateQueries({
          queryKey: [accountId, 'lti_registrations'],
        })

        showFlashAlert({
          message: I18n.t(`Configuration updates applied to *%{appName}*`, {
            appName,
            wrappers: ['<b>$1</b>'],
          }),
          type: 'success',
        })
        onSuccess()
      } else {
        showFlashAlert({
          message: I18n.t('Failed to apply updates to *%{appName}*', {
            appName,
            wrappers: ['<b>$1</b>'],
          }),
          type: 'error',
        })
      }
    },
    onError: () => {
      showFlashAlert({
        message: I18n.t('An error occurred while applying the registration update'),
        type: 'error',
      })
    },
  })

  const useRegistrationUpdateWizardState = React.useMemo(
    () => mkUseRegistrationUpdateWizardState(registrationUpdateRequest),
    [registrationUpdateRequest],
  )

  const wizardState = useRegistrationUpdateWizardState()

  const {state, advance, previous, isFirstStep, isLastStep} = wizardState

  const isAlreadyApplied = registrationUpdateRequest.status === 'applied'

  const overlayStore = React.useMemo(() => {
    return createLti1p3RegistrationOverlayStore(
      registrationUpdateRequest.internal_lti_configuration,
      registration.admin_nickname || undefined,
      registration.overlay?.data,
    )
  }, [registrationUpdateRequest, registration])

  const handleApply = useCallback(() => {
    if (!overlayStore) return

    const ltiOverlay = convertToLtiConfigurationOverlay(
      overlayStore.getState().state,
      registrationUpdateRequest.internal_lti_configuration,
    ).overlay

    applyUpdateMutation.mutate(ltiOverlay)
  }, [overlayStore, registrationUpdateRequest, applyUpdateMutation])

  const renderCurrentStep = () => {
    switch (state.step) {
      case 'Reviewing':
        return (
          <RegistrationModalBody>
            <RegistrationUpdateReview
              registrationUpdateRequest={registrationUpdateRequest}
              registration={registration}
            />
          </RegistrationModalBody>
        )
      case 'PermissionConfirmation':
        return (
          <PermissionConfirmationWrapper
            internalConfig={registration.configuration}
            overlayStore={overlayStore}
            showAllSettings={false}
            scopesSupported={registration.configuration.scopes}
            registrationUpdateRequest={registrationUpdateRequest}
          />
        )
      case 'PrivacyLevelConfirmation':
        return (
          <PrivacyConfirmationWrapper
            internalConfig={registrationUpdateRequest.internal_lti_configuration}
            overlayStore={overlayStore}
            registrationUpdateRequest={registrationUpdateRequest}
          />
        )
      case 'PlacementsConfirmation':
        return (
          <PlacementsConfirmationWrapper
            internalConfig={registration.configuration}
            overlayStore={overlayStore}
            supportedPlacements={registration.configuration.placements.map(p => p.placement)}
            existingRegistration={registration}
            registrationUpdateRequest={registrationUpdateRequest}
          />
        )
      case 'NamingConfirmation':
        return (
          <NamingConfirmationWrapper
            internalConfig={registrationUpdateRequest.internal_lti_configuration}
            overlayStore={overlayStore}
            existingRegistration={registration}
            registrationUpdateRequest={registrationUpdateRequest}
          />
        )
      case 'IconConfirmation':
        return (
          <IconConfirmationWrapper
            internalConfig={registrationUpdateRequest.internal_lti_configuration}
            overlayStore={overlayStore}
            reviewing={wizardState.state.reviewing}
            existingRegistration={registration}
            registrationUpdateRequest={registrationUpdateRequest}
          />
        )
      default:
        return null
    }
  }

  const getProgressValue = (): number => {
    const currentIndex = RegistrationUpdateWizardStepOrder.indexOf(state.step)
    return currentIndex + 1
  }

  const isFirst = isFirstStep()
  const isLast = isLastStep()

  const handleNext = () => {
    if (isLast) {
      handleApply()
    } else {
      advance()
    }
  }

  if (applyUpdateMutation.isPending) {
    return (
      <>
        <Header
          onClose={onDismiss}
          headerText={I18n.t('Review Updates from %{appName}', {appName: registration.name})}
        />
        <ProgressBar
          meterColor="info"
          shouldAnimate={true}
          size="x-small"
          frameBorder="none"
          screenReaderLabel={I18n.t('Installation Progress')}
          valueNow={RegistrationUpdateWizardStepOrder.length}
          valueMax={RegistrationUpdateWizardStepOrder.length}
          margin="0"
        />
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Applying Update')} />
            </Flex.Item>
            <Flex.Item>{I18n.t('Applying registration update')}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      </>
    )
  }

  if (isAlreadyApplied) {
    return (
      <>
        <Header onClose={onDismiss} headerText={I18n.t('Already Applied')} />
        <RegistrationModalBody>
          <View as="div" padding="large" textAlign="center">
            <Heading level="h3" margin="0 0 medium 0">
              {I18n.t('Update Already Applied')}
            </Heading>
            <Text size="medium">
              <span
                dangerouslySetInnerHTML={{
                  __html: I18n.t('This update has already been applied to *%{appName}*.', {
                    appName,
                    wrappers: ['<strong>$1</strong>'],
                  }),
                }}
              />
            </Text>
          </View>
        </RegistrationModalBody>
        <Modal.Footer>
          <Button onClick={onDismiss} color="primary">
            {I18n.t('Close')}
          </Button>
        </Modal.Footer>
      </>
    )
  }

  return (
    <>
      <Header
        onClose={onDismiss}
        headerText={I18n.t('Review Updates from %{appName}', {appName: registration.name})}
      />
      <ProgressBar
        meterColor="info"
        shouldAnimate={true}
        size="x-small"
        frameBorder="none"
        screenReaderLabel={I18n.t('Installation Progress')}
        valueNow={getProgressValue()}
        valueMax={RegistrationUpdateWizardStepOrder.length}
        themeOverride={{
          trackBottomBorderWidth: '0',
        }}
        margin="0"
      />
      {renderCurrentStep()}
      <RegistrationUpdateFooter
        currentScreen={isFirst ? 'first' : isLast ? 'last' : 'intermediate'}
        onPreviousClicked={isFirst ? onDismiss : previous}
        onNextClicked={handleNext}
        disableButtons={applyUpdateMutation.isPending}
        onAcceptAllClicked={handleApply}
        onEditUpdatesClicked={advance}
      />
    </>
  )
}
