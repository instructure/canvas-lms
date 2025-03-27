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

import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import * as React from 'react'
import {useApiResult} from '../../../common/lib/apiResult/useApiResult'
import {useZodParams} from '../../../common/lib/useZodParams/useZodParams'
import {fetchRegistrationForId} from '../../api/registrations'
import {AccountId} from '../../model/AccountId'
import {LtiRegistration} from '../../model/LtiRegistration'
import {LtiRegistrationId, ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {Tabs} from '@instructure/ui-tabs'
import {Outlet, useMatch, useNavigate} from 'react-router-dom'
import {matchApiResultState} from '../../../common/lib/apiResult/matchApiResultState'
import {useAppendBreadcrumbsToDefaults} from '@canvas/breadcrumbs/useAppendBreadcrumbsToDefaults'

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
    () => fetchRegistrationForId({accountId, ltiRegistrationId}),
    [accountId, ltiRegistrationId],
  )

  const {state} = useApiResult(fetchReg)

  return matchApiResultState(state)({
    data: (value, stale) => (
      <ToolDetailsInner registration={value} stale={stale} accountId={accountId} />
    ),
    error: message => (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('LTI Tool details fetch error')}
        errorMessage={message}
      />
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
  const isConfiguration = useMatch('/manage/:registration_id/configuration*')
  const isUsage = useMatch('/manage/:registration_id/usage*')
  const isHistory = useMatch('/manage/:registration_id/history*')

  return isConfiguration ? 'configuration' : isUsage ? 'usage' : isHistory ? 'history' : 'access'
}

export type ToolDetailsOutletContext = {
  registration: LtiRegistration
}

const ToolDetailsInner = ({
  registration,
  accountId,
}: {registration: LtiRegistration; stale: boolean; accountId: AccountId}) => {
  const navigate = useNavigate()

  const route = useToolDetailsRoute()

  useAppendBreadcrumbsToDefaults([
    {
      name: I18n.t('Manage'),
      url: `/accounts/${accountId}/apps/manage`,
    },
    {
      name: registration.name,
      url: `/accounts/${accountId}/apps/manage/${registration.id}`,
    },
  ])

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

  return (
    <Flex direction="column">
      <View
        borderRadius="large"
        borderColor="primary"
        borderWidth="small"
        margin="0 0 small"
        as="div"
        padding="small"
      >
        <Flex direction="column">
          <Flex direction="row" margin="0 0 small">
            {registration.icon_url ? (
              <img src={registration.icon_url} style={{height: '52px'}} alt={registration.name} />
            ) : null}
            <Flex direction="column" margin="0 small">
              <Text size="large" weight="bold">
                {registration.name}
              </Text>
              {/* TODO: put "vendor" text here once it's stored by the BE
              <Text size="small">{registration.vendor}</Text> */}
            </Flex>
          </Flex>
          {/* TODO: put "tagline" text here once it's stored by the BE
          <Flex margin='0 0 small'>
            <Text size="small"></Text>
          </Flex> */}
          <Flex margin="0 0 medium">
            {/* Todo: change this based on registration info */}
            <Pill>v1.3</Pill>
          </Flex>
          <Flex direction="column">
            {registration.admin_nickname ? (
              <Flex margin="0 0 small">
                <Text weight="bold">{I18n.t('Nickname')}:&nbsp;</Text>
                <Text>{registration.admin_nickname}</Text>
              </Flex>
            ) : null}
            <Flex>
              <Text weight="bold">{I18n.t('Installed')}:&nbsp;</Text>
              <Text>
                <FriendlyDatetime
                  dateTime={registration.created_at}
                  format={I18n.t('#date.formats.medium')}
                />
              </Text>
              {registration.created_by ? (
                <Text>
                  &nbsp;{I18n.t('by')}&nbsp;
                  {typeof registration.created_by === 'string'
                    ? registration.created_by
                    : registration.created_by.name}
                </Text>
              ) : null}
            </Flex>
          </Flex>
        </Flex>
      </View>
      <Tabs margin="0" padding="medium" onRequestTabChange={onTabClick}>
        <Tabs.Panel
          isSelected={route === 'access'}
          active={route === 'access'}
          id="access"
          padding="large 0"
          href="/"
          renderTitle={
            <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('Access')}</Text>
          }
          themeOverride={{defaultOverflowY: 'unset'}}
        >
          <Outlet context={{registration}} />
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
          padding="large x-small"
        >
          <Outlet context={{registration}} />
        </Tabs.Panel>
        {window.ENV.FEATURES.lti_registrations_usage_data ? (
          <Tabs.Panel
            isSelected={route === 'usage'}
            active={route === 'usage'}
            renderTitle={
              <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('Usage')}</Text>
            }
            id="usage"
            padding="large x-small"
          >
            <Outlet context={{registration}} />
          </Tabs.Panel>
        ) : null}
        <Tabs.Panel
          isSelected={route === 'history'}
          active={route === 'history'}
          renderTitle={
            <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('History')}</Text>
          }
          id="history"
          padding="large x-small"
        >
          <Outlet context={{registration}} />
        </Tabs.Panel>
      </Tabs>
    </Flex>
  )
}
