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
import type {Product} from '@canvas/lti-apps/models/Product'
import {pickPreferredIntegration} from '@canvas/lti-apps/utils/pickPreferredIntegration'
import {Button} from '@instructure/ui-buttons'
import * as React from 'react'
import {Link as RouterLink, useNavigate} from 'react-router-dom'
import {isSuccessful} from '../common/lib/apiResult/ApiResult'
import {fetchThirdPartyToolConfiguration, refreshRegistrations} from '../manage/api/registrations'
import {openInheritedKeyWizard} from '../manage/inherited_key_registration_wizard/InheritedKeyRegistrationWizardState'
import type {AccountId} from '../manage/model/AccountId'
import {ZDeveloperKeyId} from '../manage/model/developer_key/DeveloperKeyId'
import {LtiRegistrationId} from '../manage/model/LtiRegistrationId'
import {ZUnifiedToolId} from '../manage/model/UnifiedToolId'
import {
  openDynamicRegistrationWizard,
  openJsonRegistrationWizard,
  openJsonUrlRegistrationWizard,
  openRegistrationWizard,
  type JsonFetchStatus,
} from '../manage/registration_wizard/RegistrationWizardModalState'

export type ConfigureButtonProps = {
  buttonWidth: 'block' | 'inline-block'
  product: Product
  accountId: AccountId
  /**
   * This represents the id of the existing LtiRegistration of the tool, if it exists.
   * It's not using the LtiRegistration type because that's not available
   * in ui/shared/lti-apps/
   */
  installStatus?: {id: string} | null
  installStatusLoading?: boolean
}

const I18n = createI18nScope('lti_registrations')

export const findLtiVersion = (
  toolIntegrationConfigurations: Product['tool_integration_configurations'],
): '1p1' | '1p3' => {
  // We want to ignore any configs whose "integration_type" is either
  // lti_11_legacy_backfill or lti_13_legacy_backfill.
  const lti11Configs = toolIntegrationConfigurations.lti_11?.filter(config => {
    return !config['integration_type'].endsWith('_legacy_backfill')
  })

  const lti13Configs = toolIntegrationConfigurations.lti_13?.filter(config => {
    return !config['integration_type'].endsWith('_legacy_backfill')
  })

  if (lti13Configs && lti13Configs.length > 0) {
    return '1p3'
  } else if (lti11Configs && lti11Configs.length > 0) {
    return '1p1'
  }

  return '1p3'
}

export const ProductConfigureButton = ({
  buttonWidth,
  product,
  accountId,
  installStatus,
  installStatusLoading,
}: ConfigureButtonProps) => {
  const navigate = useNavigate()

  const onSuccessfulInstall = React.useCallback(
    (registrationId: LtiRegistrationId) => {
      if (window.ENV.FEATURES.lti_registrations_next) {
        navigate(`/manage/${registrationId}`)
      } else {
        navigate('/manage')
      }
    },
    [navigate],
  )

  const onSuccessfulInstallForInheritedKey = React.useCallback(
    (id: LtiRegistrationId, name?: string) => {
      if (window.ENV.FEATURES.lti_registrations_next) {
        navigate(`/manage/${id}`)
      } else {
        navigate(`/manage?q=${name}`)
      }
    },
    [navigate],
  )

  const integration = product.canvas_lti_configurations
    ? pickPreferredIntegration(product.canvas_lti_configurations)
    : undefined

  const [jsonFetchStatus, setJsonFetchStatus] = React.useState<JsonFetchStatus>({_tag: 'initial'})

  React.useEffect(() => {
    if (
      integration &&
      (integration.integration_type === 'lti_13_configuration' ||
        integration.integration_type === 'lti_13_url')
    ) {
      setJsonFetchStatus({_tag: 'loading'})

      const body =
        integration.integration_type === 'lti_13_configuration'
          ? {
              lti_configuration: JSON.parse(integration.configuration),
            }
          : {
              url: integration.url,
            }

      fetchThirdPartyToolConfiguration(body, accountId).then(result => {
        setJsonFetchStatus({
          _tag: 'loaded',
          result,
        })
      })
    }
  }, [integration, setJsonFetchStatus, accountId])

  const openBlankRegistrationWizard = () =>
    openRegistrationWizard({
      jsonUrl: '',
      jsonCode: '',
      unifiedToolId: undefined,
      dynamicRegistrationUrl: '',
      lti_version: findLtiVersion(product.tool_integration_configurations),
      isInstructureTool: product?.company?.name === 'Instructure',
      showBlankConfigurationMessage: (product?.canvas_lti_configurations?.length || 0) === 0,
      method: 'manual',
      registering: false,
      onSuccessfulInstallation: () => {
        refreshRegistrations()
      },
      jsonFetch: {_tag: 'initial'},
    })

  // Don't render the button at all until we know whether or not the tool is already installed,
  // This is to avoid jank while loading
  if (installStatusLoading) {
    return null
  } else if (window.ENV.FEATURES.lti_registrations_templates && installStatus) {
    // If the tool is already installed, we want to direct the user to the registration details page instead of showing the configure button
    // the link should look like the configure button, but it should take the user to the registration details page instead of opening the registration wizard
    // it sohuld also render as an 'a' tag, but still look like a button
    return (
      <Button
        id="configure-existing-lti-app"
        display={buttonWidth}
        color="primary"
        as={RouterLink}
        to={`/manage/${installStatus.id}`}
      >
        {I18n.t('View Installation')}
      </Button>
    )
  } else {
    return (
      <Button
        id="install-new-lti-app"
        display={buttonWidth}
        color="primary"
        interaction={
          buttonIsEnabled(jsonFetchStatus) && !installStatusLoading ? 'enabled' : 'disabled'
        }
        onClick={() => {
          switch (integration?.integration_type) {
            case 'lti_13_dynamic_registration':
              openDynamicRegistrationWizard(
                integration.url,
                ZUnifiedToolId.parse(integration.unified_tool_id),
                onSuccessfulInstall,
              )
              break
            case 'lti_13_global_inherited_key':
              openInheritedKeyWizard(
                ZDeveloperKeyId.parse(integration.global_inherited_key),
                onSuccessfulInstallForInheritedKey,
              )
              break
            case 'lti_13_url':
              if (jsonFetchStatus._tag === 'loaded' && isSuccessful(jsonFetchStatus.result)) {
                openJsonUrlRegistrationWizard(
                  integration.url,
                  jsonFetchStatus.result.data,
                  ZUnifiedToolId.parse(integration.unified_tool_id),
                  onSuccessfulInstall,
                )
              } else if (jsonFetchStatus._tag === 'loaded') {
                openBlankRegistrationWizard()
              }
              break
            case 'lti_13_configuration':
              if (jsonFetchStatus._tag === 'loaded' && isSuccessful(jsonFetchStatus.result)) {
                openJsonRegistrationWizard(
                  integration.configuration,
                  jsonFetchStatus.result.data,
                  ZUnifiedToolId.parse(integration.unified_tool_id),
                  onSuccessfulInstall,
                )
              } else if (jsonFetchStatus._tag === 'loaded') {
                openBlankRegistrationWizard()
              }
              break
            case undefined:
              openBlankRegistrationWizard()
              break
          }
        }}
      >
        {I18n.t('Install')}
      </Button>
    )
  }
}

const buttonIsEnabled = (jsonFetchStatus: JsonFetchStatus) => jsonFetchStatus._tag !== 'loading'
