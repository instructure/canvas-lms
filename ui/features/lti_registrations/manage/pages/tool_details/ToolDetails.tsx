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

import {useAppendBreadcrumb} from '@canvas/breadcrumbs/useAppendBreadcrumb'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {View, type ViewProps} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconCopyLine, IconTrashLine} from '@instructure/ui-icons'
import * as React from 'react'
import {Outlet, useMatch, useNavigate} from 'react-router-dom'
import {matchApiResultState} from '../../../common/lib/apiResult/matchApiResultState'
import {useApiResult} from '../../../common/lib/apiResult/useApiResult'
import {useZodParams} from '../../../common/lib/useZodParams/useZodParams'
import {fetchRegistrationWithAllInfoForId, deleteRegistration} from '../../api/registrations'
import type {AccountId} from '../../model/AccountId'
import {
  isForcedOn,
  LtiRegistration,
  type LtiRegistrationWithAllInformation,
} from '../../model/LtiRegistration'
import {type LtiRegistrationId, ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {ltiToolDefaultIconUrl} from '../../model/ltiToolIcons'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import {ApiResultErrorPage} from '../../../common/lib/apiResult/ApiResultErrorPage'
import {InlineList} from '@instructure/ui-list'
import {InstUISettingsProvider} from '@instructure/emotion'
import theme from '@instructure/canvas-theme'
import Header from 'features/assignment_grade_summary/react/components/Header'

const I18n = createI18nScope('lti_registrations')

export const ToolDetails = (props: {accountId: AccountId}) => {
  const parsed = useZodParams({
    registration_id: ZLtiRegistrationId,
  })
  if (parsed.success) {
    const {registration_id: ltiRegistrationId} = parsed.value
    return <ToolDetailsRequest ltiRegistrationId={ltiRegistrationId} accountId={props.accountId} />
  } else {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('LTI Registrations listing error')}
        errorMessage={JSON.stringify(parsed.errors)}
      />
    )
  }
}

export const ToolDetailsRequest = ({
  accountId,
  ltiRegistrationId,
}: {
  accountId: AccountId
  ltiRegistrationId: LtiRegistrationId
}) => {
  const fetchReg = React.useCallback(
    () => fetchRegistrationWithAllInfoForId({accountId, ltiRegistrationId}),
    [accountId, ltiRegistrationId],
  )

  const {state, refresh} = useApiResult(fetchReg)

  return matchApiResultState(state)({
    data: (value, stale) => (
      <ToolDetailsInner
        registration={value}
        stale={stale}
        accountId={accountId}
        refreshRegistration={refresh}
      />
    ),
    error: error => (
      <ApiResultErrorPage errorSubject={I18n.t('LTI Tool details fetch error')} error={error} />
    ),
    loading: () => (
      <Flex direction="column" alignItems="center" padding="large 0">
        <Spinner renderTitle="Loading" />
      </Flex>
    ),
  })
}

export type ToolDetailsRoute = 'access' | 'configuration' | 'usage' | 'history'

const useToolDetailsRoute = () => {
  const isConfiguration = useMatch('/manage/:registration_id/configuration/*')
  const isUsage = useMatch('/manage/:registration_id/usage/*')
  const isHistory = useMatch('/manage/:registration_id/history/*')

  return isConfiguration ? 'configuration' : isUsage ? 'usage' : isHistory ? 'history' : 'access'
}

export type ToolDetailsOutletContext = {
  registration: LtiRegistrationWithAllInformation
  refreshRegistration: () => void
}

const OverflowThemeOverride = {defaultOverflowY: 'unset'}

const headerDetailsTheme = {
  componentOverrides: {
    'InlineList.Item': {
      // (these colors exist but InstUI doesn't properly export them)
      color: theme.colors.primitives.grey57,
    },
  },
}

const HeaderDetailFields = (registration: LtiRegistrationWithAllInformation) => (
  <InstUISettingsProvider theme={headerDetailsTheme}>
    <InlineList size="small" delimiter="pipe" margin="0 0 small">
      {registration.admin_nickname ? (
        <InlineList.Item>
          <Text
            wrap="break-word"
            size="small"
          >{`${I18n.t('Nickname')}: ${registration.admin_nickname}`}</Text>
        </InlineList.Item>
      ) : null}
      <InlineList.Item>
        {I18n.t('Installed')}
        :&nbsp;
        <FriendlyDatetime
          dateTime={registration.created_at}
          format={I18n.t('#date.formats.medium')}
        />
        {registration.created_by ? (
          <Text size="small">
            &nbsp;{I18n.t('by')}&nbsp;
            {typeof registration.created_by === 'string'
              ? registration.created_by
              : registration.created_by.name}
          </Text>
        ) : null}
      </InlineList.Item>
      <InlineList.Item>
        <Text size="small">
          {I18n.t('Updated')}:&nbsp;
          <FriendlyDatetime
            dateTime={registration.updated_at}
            format={I18n.t('#date.formats.medium')}
          />
        </Text>
        {registration.updated_by ? (
          <Text size="small">
            &nbsp;{I18n.t('by')}&nbsp;
            {typeof registration.updated_by === 'string'
              ? registration.updated_by
              : registration.updated_by.name}
          </Text>
        ) : null}
      </InlineList.Item>
    </InlineList>
  </InstUISettingsProvider>
)

export const ToolDetailsInner = ({
  registration,
  accountId,
  refreshRegistration,
}: {
  registration: LtiRegistrationWithAllInformation
  stale: boolean
  accountId: AccountId
  refreshRegistration: () => void
}) => {
  const navigate = useNavigate()

  const route = useToolDetailsRoute()

  useAppendBreadcrumb(registration.name, `/accounts/${accountId}/apps/manage/${registration.id}`)

  const onTabClick = React.useCallback(
    (_: any, tab: {id?: string}) => {
      if (tab.id === 'access') {
        navigate(`/manage/${registration.id}`)
      } else if (tab.id) {
        navigate(`/manage/${registration.id}/${tab.id}`)
      }
    },
    [navigate, registration.id],
  )

  const outletContext: ToolDetailsOutletContext = {registration, refreshRegistration}
  const [tooltipShowing, setTooltipShowing] = React.useState(false)
  const canDelete = !registration.inherited

  const handleCopyClientId = React.useCallback(
    async (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent>) => {
      e.preventDefault()
      const clientId = registration.developer_key_id
      if (clientId) {
        try {
          await navigator.clipboard.writeText(clientId)
          showFlashAlert({
            type: 'info',
            message: I18n.t('Client ID copied (%{clientId})', {clientId}),
            dismissible: false,
            politeness: 'polite',
          })
        } catch {
          showFlashAlert({
            type: 'error',
            message: I18n.t('Unable to copy client ID to clipboard (%{clientId})', {clientId}),
            dismissible: false,
            politeness: 'polite',
          })
        }
      }
    },
    [registration],
  )

  const handleDelete = React.useCallback(
    async (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent>) => {
      e.preventDefault()
      const confirmed = await showConfirmationDialog({
        body: [
          <Text key="warning" weight="bold">
            {I18n.t('You are about to delete "%{name}"', {name: registration.name})}
          </Text>,
          <br key="break" />,
          <Text key="description">
            {I18n.t(
              'Removing this registration will remove the app from the entire account. It will be removed from its placements and existing links to it will stop working. To reestablish placements and links, you will need to reinstall the app.',
            )}
          </Text>,
        ],
        confirmColor: 'danger',
        confirmText: I18n.t('Delete'),
        label: I18n.t('Delete App Configuration'),
        size: 'small',
      })

      if (confirmed) {
        const result = await deleteRegistration(registration.account_id, registration.id)
        if (result._type === 'Success') {
          refreshRegistration()
          navigate('/manage')
        } else {
          showFlashAlert({
            type: 'error',
            message: I18n.t('There was an error when attempting to delete the registration.'),
          })
        }
      }
    },
    [registration],
  )

  React.useEffect(() => {
    document.getElementById('drawer-layout-content')?.scrollTo({
      top: 0,
      behavior: 'instant',
    })
  }, [])

  return (
    <Flex direction="column">
      <View
        borderRadius="large"
        borderColor="secondary"
        borderWidth="small"
        margin="0 0 small"
        as="div"
        padding="small"
      >
        <Flex direction="column">
          <Flex direction="row" margin="0 0 small">
            <img
              src={
                registration.icon_url
                  ? registration.icon_url
                  : ltiToolDefaultIconUrl({
                      base: window.location.origin,
                      toolName: registration.name,
                      developerKeyId: registration.developer_key_id || undefined,
                    })
              }
              style={{height: '52px'}}
              alt={registration.name}
            />

            <Flex direction="column" margin="0 small">
              <Text size="large" weight="bold">
                {registration.name}
              </Text>
              <Text size="small">{registration.vendor}</Text>
            </Flex>
          </Flex>
          <Flex margin="0 0 small">
            <Text>{registration.description}</Text>
          </Flex>
          {HeaderDetailFields(registration)}
          <Flex margin="0 0 small">
            {/* Todo: change this based on registration info */}
            <Pill>v1.3</Pill>
          </Flex>
          <Flex direction="column">
            <Flex gap="small" margin="0">
              <Button
                data-pendo="lti-registrations-copy-client-id"
                color="secondary"
                renderIcon={<IconCopyLine />}
                margin="0"
                onClick={handleCopyClientId}
              >
                {I18n.t('Copy Client ID')}
              </Button>
              <Tooltip
                renderTip={I18n.t(
                  "This account does not own this app and therefore can't delete it.",
                )}
                isShowingContent={tooltipShowing}
                onShowContent={e => {
                  // The tooltip should only be shown if they *can't* click the delete button
                  setTooltipShowing(!canDelete)
                }}
                onHideContent={e => {
                  setTooltipShowing(false)
                }}
              >
                <Button
                  data-pendo="lti-registrations-delete-app"
                  color="secondary"
                  renderIcon={<IconTrashLine />}
                  margin="0"
                  data-testid="delete-app"
                  interaction={canDelete ? 'enabled' : 'disabled'}
                  onClick={handleDelete}
                >
                  {I18n.t('Delete App')}
                </Button>
              </Tooltip>
            </Flex>
          </Flex>
        </Flex>
      </View>
      <Tabs margin="0" padding="medium" onRequestTabChange={onTabClick}>
        <Tabs.Panel
          isSelected={route === 'access'}
          active={route === 'access'}
          id="access"
          padding="medium 0"
          href="/"
          renderTitle={
            <Text style={{color: 'initial', textDecoration: 'initial'}}>
              {I18n.t('Availability and Exceptions')}
            </Text>
          }
          themeOverride={OverflowThemeOverride}
        >
          <Outlet context={outletContext} />
        </Tabs.Panel>
        <Tabs.Panel
          isSelected={route === 'configuration'}
          active={route === 'configuration'}
          renderTitle={
            <Text style={{color: 'initial', textDecoration: 'initial'}}>
              {I18n.t('Configuration')}
            </Text>
          }
          id="configuration"
          padding="medium 0"
          themeOverride={OverflowThemeOverride}
        >
          <Outlet context={outletContext} />
        </Tabs.Panel>
        {window.ENV.FEATURES.lti_registrations_usage_tab ? (
          <Tabs.Panel
            isSelected={route === 'usage'}
            active={route === 'usage'}
            renderTitle={
              <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('Usage')}</Text>
            }
            id="usage"
            padding="medium 0"
          >
            <Outlet context={outletContext} />
          </Tabs.Panel>
        ) : null}
        <Tabs.Panel
          isSelected={route === 'history'}
          active={route === 'history'}
          renderTitle={
            <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('History')}</Text>
          }
          id="history"
          padding="medium 0"
        >
          <Outlet context={outletContext} />
        </Tabs.Panel>
      </Tabs>
    </Flex>
  )
}
