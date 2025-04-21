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
import {
  pickPreferredIntegration,
  type PreferredLtiIntegration,
} from '@canvas/lti-apps/utils/pickPreferredIntegration'
import {Button} from '@instructure/ui-buttons'
import * as React from 'react'
import {useNavigate} from 'react-router-dom'
import {isSuccessful} from '../common/lib/apiResult/ApiResult'
import {fetchThirdPartyToolConfiguration} from '../manage/api/registrations'
import {openInheritedKeyWizard} from '../manage/inherited_key_registration_wizard/InheritedKeyRegistrationWizardState'
import type {AccountId} from '../manage/model/AccountId'
import {ZDeveloperKeyId} from '../manage/model/developer_key/DeveloperKeyId'
import {ZUnifiedToolId} from '../manage/model/UnifiedToolId'
import {
  openRegistrationWizard,
  openDynamicRegistrationWizard,
  openJsonRegistrationWizard,
  openJsonUrlRegistrationWizard,
  type JsonFetchStatus,
} from '../manage/registration_wizard/RegistrationWizardModalState'
import {refreshRegistrations} from '../manage/pages/manage/ManagePageLoadingState'
import type {LtiRegistrationWithConfiguration} from '../manage/model/LtiRegistration'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

export type ConfigureButtonProps = {
  buttonWidth: 'block' | 'inline-block'
  product: Product
  accountId: AccountId
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

export const ProductConfigureButton = ({buttonWidth, product, accountId}: ConfigureButtonProps) => {
  const navigate = useNavigate()

  const onSuccessfulInstall = React.useCallback(() => {
    navigate('/manage')
  }, [navigate])

  const onSuccessfulInstallForInheritedKey = React.useCallback(
    (config: LtiRegistrationWithConfiguration) => {
      navigate(`/manage?q=${config.admin_nickname || config.name}`)
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

  return (
    <Button
      display={buttonWidth}
      color="primary"
      interaction={buttonIsEnabled(integration, jsonFetchStatus) ? 'enabled' : 'disabled'}
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
            }
            break
          case undefined:
            openRegistrationWizard({
              jsonUrl: '',
              jsonCode: '',
              unifiedToolId: undefined,
              dynamicRegistrationUrl: '',
              lti_version: findLtiVersion(product.tool_integration_configurations),
              method: 'manual',
              registering: false,
              exitOnCancel: false,
              onSuccessfulInstallation: () => {
                refreshRegistrations()
              },
              jsonFetch: {_tag: 'initial'},
            })
            break
        }
      }}
    >
      {I18n.t('Configure')}
    </Button>
  )
}

const buttonIsEnabled = (
  integration: PreferredLtiIntegration | undefined,
  jsonFetchStatus: JsonFetchStatus,
) => {
  if (integration === undefined) {
    return true
  } else if (jsonFetchStatus._tag === 'loading') {
    return false
  } else if (integration?.integration_type === 'lti_13_dynamic_registration') {
    return true
  } else if (
    (jsonFetchStatus._tag === 'loaded' && isSuccessful(jsonFetchStatus.result)) ||
    integration?.integration_type === 'lti_13_global_inherited_key'
  ) {
    return window.ENV.FEATURES.lti_registrations_page
  } else {
    return false
  }
}
