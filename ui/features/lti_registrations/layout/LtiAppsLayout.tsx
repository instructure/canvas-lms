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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Link, Outlet, useMatch, useNavigate} from 'react-router-dom'
import {openRegistrationWizard} from '../manage/registration_wizard/RegistrationWizardModalState'
import {refreshRegistrations} from '../manage/pages/manage/ManagePageLoadingState'
import {useMedia} from 'react-use'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('lti_registrations')

export const LtiAppsLayout = React.memo(() => {
  const isManage = useMatch('/manage/*')
  const navigate = useNavigate()
  const isMobile = useMedia('(max-width: 767px)')

  const onTabClick = React.useCallback(
    (_, tab: {id?: string}) => {
      navigate(tab.id === 'manage' ? '/manage' : '/')
    },
    [navigate]
  )

  const open = React.useCallback(() => {
    openRegistrationWizard({
      jsonUrl: '',
      jsonCode: '',
      unifiedToolId: undefined,
      dynamicRegistrationUrl: '',
      lti_version: '1p3',
      method: 'dynamic_registration',
      registering: false,
      exitOnCancel: false,
      onSuccessfulInstallation: () => {
        refreshRegistrations()
      },
      jsonFetch: {_tag: 'initial'},
    })
  }, [])

  return (
    <>
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
      <Text>
        {I18n.t(
          'Enhance your Canvas experience with apps that offer content libraries, collaboration tools, analytics, and more. This page is your hub for all app features! Use the Discover page to find and install new apps, and the Manage page to review and modify your installed apps.'
        )}
      </Text>
      {isMobile ? (
        <>
          <View margin="small 0" display="block">
            <SimpleSelect
              renderLabel=""
              onChange={onTabClick}
              value={isManage ? 'manage' : 'discover'}
            >
              <SimpleSelect.Option id="discover" value="discover">
                {I18n.t('Discover')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="manage" value="manage">
                {I18n.t('Manage')}
              </SimpleSelect.Option>
            </SimpleSelect>
          </View>
          <Outlet />
        </>
      ) : (
        <Tabs margin="medium auto" padding="medium" onRequestTabChange={onTabClick}>
          {window.ENV.FEATURES.lti_registrations_discover_page && (
            <Tabs.Panel
              isSelected={!isManage}
              id="discover"
              active={!isManage}
              padding="large 0"
              href="/"
              renderTitle={
                <Text style={{color: 'initial', textDecoration: 'initial'}}>
                  {I18n.t('Discover')}
                </Text>
              }
              themeOverride={{defaultOverflowY: 'unset'}}
            >
              <Outlet />
            </Tabs.Panel>
          )}
          <Tabs.Panel
            renderTitle={
              <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('Manage')}</Text>
            }
            id="manage"
            padding="large x-small"
            isSelected={!!isManage}
            active={!!isManage}
          >
            <Outlet />
          </Tabs.Panel>
        </Tabs>
      )}
    </>
  )
})
