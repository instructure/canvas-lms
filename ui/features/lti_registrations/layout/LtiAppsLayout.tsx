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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Outlet, useMatch, useNavigate} from 'react-router-dom'
import {openRegistrationWizard} from '../manage/registration_wizard/RegistrationWizardModalState'
import {refreshRegistrations} from '../manage/pages/manage/ManagePageLoadingState'
import {useMedia} from 'react-use'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import {LtiRegistrationsTab} from './constants'
import {isLtiRegistrationsDiscoverEnabled} from '../discover/utils'
import {isLtiRegistrationsUsageEnabled} from '../monitor/utils'

const I18n = createI18nScope('lti_registrations')

export const LtiAppsLayout = React.memo(() => {
  const isManage = useMatch('/manage/*')
  const isMonitor = useMatch('/monitor/*')

  const navigate = useNavigate()
  const isMobile = useMedia('(max-width: 767px)')

  const tabSelected = React.useMemo(() => {
    return isManage
      ? LtiRegistrationsTab.manage
      : isMonitor
        ? LtiRegistrationsTab.monitor
        : LtiRegistrationsTab.discover
  }, [isManage, isMonitor])

  const {isTabManage, isTabDiscover, isTabMonitor} = React.useMemo(() => {
    return {
      isTabManage: tabSelected === LtiRegistrationsTab.manage,
      isTabMonitor: tabSelected === LtiRegistrationsTab.monitor,
      isTabDiscover: tabSelected === LtiRegistrationsTab.discover,
    }
  }, [tabSelected])

  const onTabClick = React.useCallback(
    (_: any, tab: {id?: string}) => {
      switch (tab.id) {
        case LtiRegistrationsTab.discover:
          navigate('/')
          break
        case LtiRegistrationsTab.manage:
          navigate('/manage')
          break
        case LtiRegistrationsTab.monitor:
          navigate('/monitor')
          break
        default:
          navigate('/')
          break
      }
    },
    [navigate],
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
          <Flex alignItems="center">
            <Flex.Item>
              <Heading level="h1">{I18n.t('Apps')}</Heading>
            </Flex.Item>
          </Flex>
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
          'Apps is the central hub to discover, manage, and monitor integrated apps. Extend and enhance your digital teaching and learning experience with powerful apps that provide and/or enrich your content, assessment, multimedia, collaboration, analytics, accessibility, and more. Select Discover to explore and install new apps, Manage to review and manage installed apps, and Monitor to view and understand usage.',
        )}
      </Text>
      {isMobile ? (
        <>
          <View margin="small 0" display="block">
            <SimpleSelect renderLabel="" onChange={onTabClick} value={tabSelected}>
              {isLtiRegistrationsDiscoverEnabled() && (
                <SimpleSelect.Option id="discover" value="discover">
                  {I18n.t('Discover')}
                </SimpleSelect.Option>
              )}
              <SimpleSelect.Option id="manage" value="manage">
                {I18n.t('Manage')}
              </SimpleSelect.Option>
              {isLtiRegistrationsUsageEnabled() && (
                <SimpleSelect.Option id="monitor" value="monitor">
                  {I18n.t('Monitor')}
                </SimpleSelect.Option>
              )}
            </SimpleSelect>
          </View>
          <Outlet />
        </>
      ) : (
        <Tabs margin="medium auto" padding="medium" onRequestTabChange={onTabClick}>
          {isLtiRegistrationsDiscoverEnabled() && (
            <Tabs.Panel
              renderTitle={
                <Text style={{color: 'initial', textDecoration: 'initial'}}>
                  {I18n.t('Discover')}
                </Text>
              }
              id={LtiRegistrationsTab.discover}
              active={isTabDiscover}
              isSelected={isTabDiscover}
              padding="large 0"
              href="/"
              themeOverride={{defaultOverflowY: 'unset'}}
            >
              <Outlet />
            </Tabs.Panel>
          )}
          <Tabs.Panel
            renderTitle={
              <Text style={{color: 'initial', textDecoration: 'initial'}}>{I18n.t('Manage')}</Text>
            }
            id={LtiRegistrationsTab.manage}
            padding="large x-small"
            active={isTabManage}
            isSelected={isTabManage}
          >
            <Outlet />
          </Tabs.Panel>
          {isLtiRegistrationsUsageEnabled() ? (
            <Tabs.Panel
              renderTitle={
                <Text style={{color: 'initial', textDecoration: 'initial'}}>
                  {I18n.t('Monitor')}
                </Text>
              }
              id={LtiRegistrationsTab.monitor}
              active={isTabMonitor}
              isSelected={isTabMonitor}
            >
              <Outlet />
            </Tabs.Panel>
          ) : undefined}
        </Tabs>
      )}
    </>
  )
})
