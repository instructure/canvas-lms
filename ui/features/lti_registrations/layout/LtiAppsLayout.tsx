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
import ReactDOM from 'react-dom'
import {createBrowserRouter, RouterProvider, Link, Outlet, useMatch} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('lti_registrations')

export const LtiAppsLayout = () => {
  const isManage = useMatch('/manage/*')

  return (
    <>
      <View as="div" margin="0 0 small 0" padding="none">
        <Heading level="h1">{I18n.t('Extensions')}</Heading>
      </View>
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
    </>
  )
}
