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
import ContentLayout from './ContentLayout'
import {AppNavBar, FooterLinks, GlobalStyle, InstructureLogo, LoginLogo} from '../shared'
import {Flex} from '@instructure/ui-flex'
import {Outlet, ScrollRestoration} from 'react-router-dom'
import {View} from '@instructure/ui-view'
import {useNewLogin} from '../context/NewLoginContext'

export const LoginLayout = () => {
  const {loginLogoUrl} = useNewLogin()

  return (
    <>
      <GlobalStyle />
      <ScrollRestoration />

      <View as="div" background="primary" height="100vh">
        <Flex direction="column" height="100%">
          <Flex.Item as="header" width="100%">
            <AppNavBar />
          </Flex.Item>

          <Flex.Item shouldGrow={true}>
            <ContentLayout>
              <Flex direction="column" gap="large">
                {loginLogoUrl && (
                  <View as="header">
                    <LoginLogo />
                  </View>
                )}

                <View as="main" minHeight="18.75rem">
                  <Outlet />
                </View>

                <View as="footer">
                  <Flex direction="column" gap="large">
                    <FooterLinks />

                    <Flex.Item align="center" overflowX="visible" overflowY="visible">
                      <InstructureLogo />
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex>
            </ContentLayout>
          </Flex.Item>
        </Flex>
      </View>
    </>
  )
}
