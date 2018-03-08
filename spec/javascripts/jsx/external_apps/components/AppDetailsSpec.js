/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

define(
  [
    'react',
    'react-addons-test-utils',
    'jsx/external_apps/components/AppDetails',
    'jsx/external_apps/lib/AppCenterStore'
  ],
  (React, TestUtils, AppDetails, AppCenterStore) => {
    QUnit.module('External Apps App Details')

    test('the back to app center link goes to the proper place', () => {
      const fakeStore = {
        findAppByShortName() {
          return {
            short_name: 'someApp',
            config_options: []
          }
        }
      }

      const component = TestUtils.renderIntoDocument(
        <AppDetails baseUrl="/someUrl" shortName="someApp" store={fakeStore} />
      )

      const link = TestUtils.findRenderedDOMComponentWithClass(component, 'app_cancel')

      equal(link.props.href, '/someUrl', 'the url matches appropriately')
    })
  }
)
