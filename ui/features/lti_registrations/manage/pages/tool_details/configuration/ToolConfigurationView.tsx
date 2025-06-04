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

import * as React from 'react'
import {useOutletContext, Link as RouterLink} from 'react-router-dom'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {View, ViewProps} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconCopyLine, IconRefreshLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spacing} from '@instructure/emotion'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {i18nLtiPrivacyLevel} from '../../../model/i18nLtiPrivacyLevel'
import {i18nLtiPlacement} from '../../../model/i18nLtiPlacement'
import {DefaultLtiPrivacyLevel} from '../../../model/LtiPrivacyLevel'
import {isLtiPlacementWithDefaultIcon, isLtiPlacementWithIcon} from '../../../model/LtiPlacement'
import {ltiToolDefaultIconUrl} from '../../../model/ltiToolIcons'
import {ToolConfigurationFooter} from './ToolConfigurationFooter'
import {isForcedOn} from '../../../model/LtiRegistration'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import {
  resetLtiRegistration,
  fetchLtiRegistrationWithLegacyConfig,
} from '../../../api/registrations'
import {isSuccessful} from '../../../../common/lib/apiResult/ApiResult'

const I18n = createI18nScope('lti_registrations')

const Section = ({
  title,
  children,
  margin = '0 small medium small',
}: {
  title: string
  children: React.ReactNode
  margin?: Spacing
}) => {
  return (
    <View
      borderRadius="large"
      borderColor="secondary"
      borderWidth="small"
      margin={margin}
      as="div"
      padding="medium"
    >
      <Heading level="h3" margin="0 0 small 0">
        {title}
      </Heading>
      {children}
    </View>
  )
}

const SubSection = ({
  title,
  children,
  margin = 'small 0 0 0',
}: {
  title: string
  children?: React.ReactNode
  margin?: Spacing
}) => {
  return (
    <>
      <Heading level="h4" margin={margin}>
        {title}
      </Heading>
      {children}
    </>
  )
}

export const ToolConfigurationView = () => {
  const {registration, refreshRegistration} = useOutletContext<ToolDetailsOutletContext>()

  const customFields = Object.entries(registration.overlaid_configuration.custom_fields || {})
  const redirectUris = registration.overlaid_configuration.redirect_uris || []
  const enabledPlacements = registration.overlaid_configuration.placements.filter(p => {
    return !('enabled' in p) || p.enabled
  })

  const enabledPlacementsWithIcons = enabledPlacements.filter(p =>
    isLtiPlacementWithIcon(p.placement),
  )

  const [tooltipShowing, setTooltipShowing] = React.useState(false)
  const resetAppConfiguration = async () => {
    const result = await resetLtiRegistration(registration.account_id, registration.id)
    await refreshRegistration()
  }

  const canRestoreDefault = !registration.inherited

  const handleRestoreDefault = React.useCallback(
    async (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent>) => {
      e.preventDefault()
      const confirmed = await showConfirmationDialog({
        body: I18n.t(
          'Are you sure you want to reset this app’s settings to their default values? Once they are reverted the action cannot be undone.',
        ),
        confirmColor: 'danger',
        confirmText: I18n.t('Reset'),
        label: I18n.t('Reset App Configuration'),
        size: 'small',
      })

      if (confirmed) {
        resetAppConfiguration()
      }
    },
    [],
  )

  const handleCopyJsonConfig = React.useCallback(
    async (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent>) => {
      e.preventDefault()
      const legacyConfigResponse = await fetchLtiRegistrationWithLegacyConfig(
        registration.account_id,
        registration.id,
      )

      if (isSuccessful(legacyConfigResponse)) {
        const legacyConfig = legacyConfigResponse.data['overlaid_legacy_configuration']
        try {
          await navigator.clipboard.writeText(JSON.stringify(legacyConfig, null, 2))
          showFlashAlert({
            type: 'info',
            message: I18n.t('JSON configuration copied'),
          })
        } catch {
          showFlashAlert({
            type: 'error',
            message: I18n.t('Unable to copy JSON code to clipboard'),
          })
        }
      } else {
        showFlashAlert({
          type: 'error',
          message: I18n.t('Unable to get JSON configuration to be copied.'),
        })
      }
    },
    [registration],
  )

  return (
    <div>
      {registration.manual_configuration_id ? (
        <Section title={I18n.t('Launch Settings')}>
          <SubSection title={I18n.t('Redirect URIs:')}>
            {redirectUris.map((uri, i) => (
              <Text key={i}>{uri}</Text>
            ))}
          </SubSection>

          <SubSection title={I18n.t('Default Target Link URI:')}>
            <Text>{registration.overlaid_configuration.target_link_uri}</Text>
          </SubSection>

          <SubSection title={I18n.t('Open ID Connect Initiation URI:')}>
            {registration.overlaid_configuration.oidc_initiation_url}
          </SubSection>

          <Flex direction="row" alignItems="end" margin="small 0 0">
            <Flex.Item margin="0 xx-small 0 0">
              <Text weight="bold">{I18n.t('JWK Method:')}</Text>
            </Flex.Item>

            <Flex.Item>
              {registration.overlaid_configuration.public_jwk_url ? (
                <Text>{I18n.t('Public JWK URL')}</Text>
              ) : (
                <Text>{I18n.t('Public JWK')}</Text>
              )}
            </Flex.Item>
          </Flex>

          {registration.overlaid_configuration.public_jwk_url ? (
            <SubSection title={I18n.t('Public JWK URL:')}>
              <Text>{registration.overlaid_configuration.public_jwk_url}</Text>
            </SubSection>
          ) : registration.overlaid_configuration.public_jwk ? (
            <SubSection title={I18n.t('Public JWK:')}>
              <View as="div" margin="x-small 0 0 0">
                <pre style={{fontFamily: 'monospace'}}>
                  {JSON.stringify(registration.overlaid_configuration.public_jwk, null, 2)}
                </pre>
              </View>
            </SubSection>
          ) : null}

          <SubSection title={I18n.t('Domain:')}>
            {registration.overlaid_configuration.domain ? (
              <Text>{registration.overlaid_configuration.domain}</Text>
            ) : (
              <Text fontStyle="italic">{I18n.t('No domain configured.')}</Text>
            )}
          </SubSection>

          <SubSection title={I18n.t('Custom Fields:')}>
            {customFields.length === 0 ? (
              <Text fontStyle="italic">{I18n.t('No custom fields configured.')}</Text>
            ) : (
              <View as="div" margin="x-small 0 0 0">
                <pre style={{fontFamily: 'monospace'}}>
                  {customFields.map(([key, field]) => `${key}=${field}`).join('\n')}
                </pre>
              </View>
            )}
          </SubSection>
        </Section>
      ) : null}

      <Section title={I18n.t('Permissions')}>
        <Flex direction="column" data-testid="permissions">
          {registration.overlaid_configuration.scopes.length === 0 ? (
            <Text fontStyle="italic">{I18n.t('This app has no permissions configured.')}</Text>
          ) : (
            registration.overlaid_configuration.scopes.map(scope => (
              <Text key={scope} as="div">
                {i18nLtiScope(scope)}
              </Text>
            ))
          )}
        </Flex>
      </Section>

      <Section title={I18n.t('Data Sharing')}>
        {i18nLtiPrivacyLevel(
          registration.overlaid_configuration.privacy_level || DefaultLtiPrivacyLevel,
        )}
      </Section>

      <Section title={I18n.t('Placements')}>
        <Flex direction="column">
          {enabledPlacements.length === 0 ? (
            <Text fontStyle="italic">{I18n.t('No placements enabled.')}</Text>
          ) : (
            enabledPlacements.map((p, i) => <Text key={i}>{i18nLtiPlacement(p.placement)}</Text>)
          )}
        </Flex>
      </Section>

      <Section title={I18n.t('Administration Nickname and Description')}>
        <Flex direction="row" alignItems="end" margin="small 0 0">
          <Flex.Item margin="0 xx-small 0 0">
            <Text weight="bold">{I18n.t('Administration Nickname:')}</Text>
          </Flex.Item>
          <Flex.Item>
            {registration.admin_nickname ? (
              <Text>{registration.admin_nickname}</Text>
            ) : (
              <Text fontStyle="italic">{I18n.t('No nickname')}</Text>
            )}
          </Flex.Item>
        </Flex>

        <Flex direction="row" alignItems="end" margin="small 0 0">
          <Flex.Item margin="0 xx-small 0 0">
            <Text weight="bold">{I18n.t('Description:')}</Text>
          </Flex.Item>
          <Flex.Item>
            {registration.overlaid_configuration.description ? (
              <Text>{registration.overlaid_configuration.description}</Text>
            ) : (
              <Text fontStyle="italic">{I18n.t('No description')}</Text>
            )}
          </Flex.Item>
        </Flex>

        <Heading level="h3" margin="small 0" id="placements">
          {I18n.t('Placement Names')}
        </Heading>
        {enabledPlacements.map((p, i) => (
          <Flex direction="row" alignItems="end" margin="small 0 0" key={i}>
            <Flex.Item margin="0 xx-small 0 0">
              <Text weight="bold">{i18nLtiPlacement(p.placement)}:</Text>
            </Flex.Item>
            <Flex.Item>
              {p.text ? <Text>{p.text}</Text> : <Text fontStyle="italic">{I18n.t('No text')}</Text>}
            </Flex.Item>
          </Flex>
        ))}
      </Section>

      <Section title={I18n.t('Icon URLs')}>
        {enabledPlacementsWithIcons.length > 0 ? (
          enabledPlacementsWithIcons.map((p, i) => (
            <View key={p.placement} as="div" margin="0 0 small 0" style={{overflow: 'hidden'}}>
              <Text weight="bold">{i18nLtiPlacement(p.placement)}:</Text>
              <Flex
                direction="row"
                alignItems="center"
                margin="0"
                key={i}
                style={{overflow: 'hidden'}}
              >
                {p.icon_url ? (
                  <>
                    <Flex.Item margin="0 xx-small 0 0">
                      <img style={{height: '24px'}} src={p.icon_url} alt={registration.name}></img>
                    </Flex.Item>
                    {/* Can't use Flex.Item here, because it won't let us
                      set flex:1 which is needed for the text-overflow */}
                    <div
                      data-testid={`icon-url-${p.placement}`}
                      style={{
                        textOverflow: 'ellipsis',
                        overflow: 'hidden',
                        whiteSpace: 'nowrap',
                        flex: 1,
                      }}
                    >
                      {p.icon_url}
                    </div>
                  </>
                ) : isLtiPlacementWithDefaultIcon(p.placement) ? (
                  <>
                    <Flex.Item margin="0 xx-small 0 0">
                      <img
                        style={{height: '24px'}}
                        src={ltiToolDefaultIconUrl({
                          base: window.location.origin,
                          toolName: registration.name,
                          developerKeyId: registration.developer_key_id || undefined,
                        })}
                        alt={registration.name}
                      ></img>
                    </Flex.Item>
                    <Flex.Item margin="0 xx-small 0 0" data-testid={`icon-url-${p.placement}`}>
                      <Text fontStyle="italic">{I18n.t('Default Icon')}</Text>
                    </Flex.Item>
                  </>
                ) : (
                  <Text fontStyle="italic" data-testid={`icon-url-${p.placement}`}>
                    {I18n.t('Not Included')}
                  </Text>
                )}
              </Flex>
            </View>
          ))
        ) : (
          <Text fontStyle="italic">{I18n.t('No placements with icons are enabled.')}</Text>
        )}
      </Section>

      <ToolConfigurationFooter>
        <Flex direction="row" justifyItems="space-between" padding="0 small">
          <Flex.Item>
            <Flex gap="small">
              <Flex.Item>
                <Tooltip
                  renderTip={I18n.t(
                    "This account does not own this app and therefore can't reset its configuration.",
                  )}
                  isShowingContent={tooltipShowing}
                  onShowContent={e => {
                    // The tooltip should only be shown if they *can't* click the restore default button
                    setTooltipShowing(!canRestoreDefault)
                  }}
                  onHideContent={e => {
                    setTooltipShowing(false)
                  }}
                >
                  <Button
                    color="primary-inverse"
                    interaction={canRestoreDefault ? 'enabled' : 'disabled'}
                    renderIcon={<IconRefreshLine />}
                    margin="0"
                    onClick={handleRestoreDefault}
                  >
                    {I18n.t('Restore Default')}
                  </Button>
                </Tooltip>
              </Flex.Item>
              {registration.ims_registration_id === null ? (
                <Flex.Item>
                  <Button
                    color="primary-inverse"
                    renderIcon={<IconCopyLine />}
                    margin="0"
                    onClick={handleCopyJsonConfig}
                  >
                    {I18n.t('Copy JSON Code')}
                  </Button>
                </Flex.Item>
              ) : null}
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <Button
              color="primary"
              as={RouterLink}
              to={`/manage/${registration.id}/configuration/edit`}
            >
              {I18n.t('Edit')}
            </Button>
          </Flex.Item>
        </Flex>
      </ToolConfigurationFooter>
    </div>
  )
}
