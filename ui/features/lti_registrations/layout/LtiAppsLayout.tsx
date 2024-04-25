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

import React from 'react'

import {Link, Outlet, useMatch} from 'react-router-dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {DynamicRegistrationModal} from '../manage/dynamic_registration/DynamicRegistrationModal'
import {useDynamicRegistrationState} from '../manage/dynamic_registration/DynamicRegistrationState'

const I18n = useI18nScope('lti_registrations')

export const LtiAppsLayout = () => {
  const isManage = useMatch('/manage/*')

  const queryClient = new QueryClient()

  const contextId = window.location.pathname.split('/')[2]

  const state = useDynamicRegistrationState(s => s)

  return (
    <QueryClientProvider client={queryClient}>
      <Flex alignItems="start" justifyItems="space-between" margin="0 0 small 0">
        <Flex.Item>
          <Heading level="h1">{I18n.t('Extensions')}</Heading>
        </Flex.Item>
        {isManage ? (
          <Flex.Item>
            <Button color="primary" onClick={() => state.open()}>
              {I18n.t('Install a New Extension')}
            </Button>
          </Flex.Item>
        ) : null}
      </Flex>
      <DynamicRegistrationModal contextId={contextId} />
      <Text size="large">{I18n.t('Discover Something new or manage existing LTI extensions')}</Text>
      <Tabs margin="medium auto" padding="medium" onRequestTabChange={() => {}}>
        {window.ENV.FEATURES.lti_registrations_discover_page && (
          <Tabs.Panel
            isSelected={!isManage}
            id="tabB"
            href="/"
            renderTitle={
              <Link style={{color: 'initial', textDecoration: 'initial'}} to="/">
                {I18n.t('Discover')}
              </Link>
            }
          >
            <Outlet />
          </Tabs.Panel>
        )}
        <Tabs.Panel
          renderTitle={
            <Link style={{color: 'initial', textDecoration: 'initial'}} to="/manage">
              {I18n.t('Manage')}
            </Link>
          }
          id="tabA"
          padding="large"
          isSelected={!!isManage}
          active={true}
        >
          <Outlet />
        </Tabs.Panel>
      </Tabs>
    </QueryClientProvider>
  )
}
