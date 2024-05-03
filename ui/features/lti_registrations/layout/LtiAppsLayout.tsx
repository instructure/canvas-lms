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

import {Link, Outlet, useMatch, useNavigate} from 'react-router-dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {openRegistrationWizard} from '../manage/registration_wizard/RegistrationWizardModalState'
import {RegistrationWizardModal} from '../manage/registration_wizard/RegistrationWizardModal'
import {ZAccountId} from '../manage/model/AccountId'

const I18n = useI18nScope('lti_registrations')

export const LtiAppsLayout = React.memo(() => {
  const isManage = useMatch('/manage/*')
  const navigate = useNavigate()

  const onTabClick = React.useCallback(
    (_, tab: {id?: string}) => {
      navigate(tab.id === 'manage' ? '/manage' : '/')
    },
    [navigate]
  )

  const queryClient = new QueryClient()

  const accountId = ZAccountId.parse(window.location.pathname.split('/')[2])

  const open = React.useCallback(() => {
    openRegistrationWizard({
      dynamicRegistrationUrl: '',
      lti_version: '1p3',
      method: 'dynamic_registration',
      registering: false,
      progress: 0,
      progressMax: 100,
    })
  }, [])

  return (
    <QueryClientProvider client={queryClient}>
      <Flex alignItems="start" justifyItems="space-between" margin="0 0 small 0">
        <Flex.Item>
          <Heading level="h1">{I18n.t('Apps')}</Heading>
        </Flex.Item>
        {isManage ? (
          <Flex.Item>
            <Button color="primary" onClick={open}>
              {I18n.t('Install a New App')}
            </Button>
          </Flex.Item>
        ) : null}
      </Flex>
      <RegistrationWizardModal accountId={accountId} />
      <Tabs margin="medium auto" padding="medium" onRequestTabChange={onTabClick}>
        {window.ENV.FEATURES.lti_registrations_discover_page && (
          <Tabs.Panel
            isSelected={!isManage}
            id="discover"
            active={!isManage}
            padding="large 0"
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
          id="manage"
          padding="large x-small"
          isSelected={!!isManage}
          active={!!isManage}
        >
          <Outlet />
        </Tabs.Panel>
      </Tabs>
    </QueryClientProvider>
  )
})
