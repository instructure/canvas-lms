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
import {ReviewScreen} from '../../registration_wizard_forms/ReviewScreen'
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationWizardStep} from '../Lti1p3RegistrationWizardState'
import {toUndefined} from '../../../common/lib/toUndefined'
import {getDefaultPlacementTextFromConfig} from './helpers'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'
import {useDomainDuplicates} from '../../api/domainDuplicates'
import {getAccountId} from '../../../common/lib/getAccountId'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

const I18n = createI18nScope('lti_registration.wizard')

export type ReviewScreenWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  transitionTo: (step: Lti1p3RegistrationWizardStep) => void
  includeLaunchSettings?: boolean
  includeIconUrls?: boolean
}

export const ReviewScreenWrapper = ({
  overlayStore,
  internalConfig,
  transitionTo,
  includeLaunchSettings = true,
  includeIconUrls = true,
}: ReviewScreenWrapperProps) => {
  const {state} = overlayStore()
  const placements = filterPlacementsByFeatureFlags(state.placements.placements ?? [])
  const scopes = state.permissions.scopes ?? []
  const privacyLevel =
    state.data_sharing.privacy_level ?? internalConfig.privacy_level ?? 'anonymous'

  // Check for duplicate domains and wait for the query to complete
  // Show a spinner while checking to ensure users see any duplicate warnings
  const accountId = getAccountId()
  const domain = state.launchSettings.domain ?? toUndefined(internalConfig.domain)
  const domainDuplicatesQuery = useDomainDuplicates(accountId, domain)

  // Show loading spinner while checking for duplicates
  if (domainDuplicatesQuery.isLoading) {
    return (
      <RegistrationModalBody>
        <Flex justifyItems="center" alignItems="center" height="100%">
          <Spinner
            size="large"
            renderTitle={I18n.t('Checking for duplicate domains...')}
            data-testid="duplicate-domain-spinner"
          />
        </Flex>
      </RegistrationModalBody>
    )
  }

  // After loading completes, use the results if successful, otherwise pass empty array
  const domainDuplicates = domainDuplicatesQuery.isSuccess
    ? domainDuplicatesQuery.data.json.duplicates
    : []

  const labels = Object.fromEntries(
    placements.map(placement => [
      placement,
      state.naming.placements[placement] ??
        getDefaultPlacementTextFromConfig(placement, internalConfig),
    ]),
  )
  const iconUrls = state.icons.placements
  const defaultPlacementIconUrls = Object.fromEntries(
    internalConfig.placements.map(placement => [placement.placement, placement.icon_url]),
  )
  const name = state.naming.nickname

  const description = state.naming.description ?? toUndefined(internalConfig.description)

  const jwkValue =
    state.launchSettings.Jwk ??
    (internalConfig.public_jwk ? JSON.stringify(internalConfig.public_jwk) : undefined)

  const customFieldsValue =
    state.launchSettings.customFields?.split('\n').filter(f => !!f) ??
    (internalConfig.custom_fields
      ? Object.entries(internalConfig.custom_fields).map(([key, value]) => `${key}=${value}`)
      : undefined)

  const messageSettings = state.launchSettings.message_settings
  const eulaSettings = messageSettings?.find(ms => ms.type === 'LtiEulaRequest')

  return (
    <>
      <ReviewScreen
        launchSettings={
          includeLaunchSettings
            ? {
                customFields: customFieldsValue,
                redirectUris:
                  state.launchSettings.redirectURIs?.split('\n') ??
                  toUndefined(internalConfig.redirect_uris),
                defaultTargetLinkUri:
                  state.launchSettings.targetLinkURI ?? toUndefined(internalConfig.target_link_uri),
                oidcInitiationUrl:
                  state.launchSettings.openIDConnectInitiationURL ??
                  toUndefined(internalConfig.oidc_initiation_url),
                jwkMethod: state.launchSettings.JwkMethod ?? 'public_jwk_url',
                jwkUrl: state.launchSettings.JwkURL ?? toUndefined(internalConfig.public_jwk_url),
                jwk: jwkValue,
                domain: state.launchSettings.domain ?? toUndefined(internalConfig.domain),
              }
            : undefined
        }
        eulaSettings={eulaSettings}
        description={description}
        placements={placements}
        scopes={scopes}
        privacyLevel={privacyLevel}
        labels={labels}
        iconUrls={iconUrls}
        defaultPlacementIconUrls={defaultPlacementIconUrls}
        defaultIconUrl={internalConfig.launch_settings?.icon_url}
        nickname={name}
        includeIconUrls={includeIconUrls}
        domainDuplicates={domainDuplicates}
        accountId={accountId}
        onEditLaunchSettings={() => transitionTo('LaunchSettings')}
        onEditPlacements={() => transitionTo('Placements')}
        onEditNaming={() => transitionTo('Naming')}
        onEditScopes={() => transitionTo('Permissions')}
        onEditIconUrls={() => transitionTo('Icons')}
        onEditPrivacyLevel={() => transitionTo('DataSharing')}
        onEditMessageSettings={type => {
          switch (type) {
            case 'LtiEulaRequest':
              transitionTo('EulaSettings')
              break
          }
        }}
      />
    </>
  )
}
