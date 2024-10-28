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
import {AppNavBar, ContentLayout, Footer, Header} from '../shared'
import {Flex} from '@instructure/ui-flex'
import {Global, css} from '@instructure/emotion'
import {Outlet, ScrollRestoration} from 'react-router-dom'
import {View} from '@instructure/ui-view'

// https://emotion.sh/docs/@emotion/css#global-styles
export function GlobalStyle() {
  return (
    <Global
      styles={css`
        html,
        body {
          overflow-x: hidden;
        }
        html {
          height: 100%;
        }
        body {
          min-height: 100%;
          margin: 0;
        }
      `}
    />
  )
}

export const LoginLayout = () => {
  return (
    <>
      <GlobalStyle />
      <ScrollRestoration />

      <View as="div" height="100vh">
        <Flex as="div" direction="column" height="100%">
          <Flex.Item as="header" width="100vw" overflowY="visible">
            <AppNavBar />
          </Flex.Item>

          <Flex.Item as="div" shouldGrow={true} overflowY="visible">
            <ContentLayout>
              <Flex as="div" direction="column" gap="large">
                <Header />

                <main>
                  <Outlet />
                </main>

                <Footer />
              </Flex>
            </ContentLayout>
          </Flex.Item>
        </Flex>
      </View>
    </>
  )
}
