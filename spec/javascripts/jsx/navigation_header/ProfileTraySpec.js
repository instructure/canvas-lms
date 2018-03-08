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
  ['react', 'react-dom', 'react-addons-test-utils', 'jsx/navigation_header/trays/ProfileTray'],
  (React, ReactDOM, TestUtils, ProfileTray) => {
    QUnit.module('MissingPeopleSection')

    function noop() {}

    test('renders the component', () => {
      const component = TestUtils.renderIntoDocument(
        <ProfileTray
          userDisplayName={'Sample Student'}
          userAvatarURL={imageurl}
          profileEnabled={true}
          eportfoliosEnabled={true}
          closeTray={noop}
        />
      )
      const profiletray = TestUtils.findRenderedDOMComponentWithClass(component, 'profile-tray')
      ok(profiletray)
    })

    test('renders the complete list', () => {
      const component = TestUtils.renderIntoDocument(
        <ProfileTray
          userDisplayName={'Sample Student'}
          userAvatarURL={imageurl}
          profileEnabled={true}
          eportfoliosEnabled={true}
          closeTray={noop}
        />
      )
      const avatar = TestUtils.findRenderedDOMComponentWithClass(component, 'ic-avatar')
      ok(avatar)

      const list = TestUtils.findRenderedDOMComponentWithTag(component, 'ul')
      ok(list)

      equal(list.querySelectorAll('li').length, 5)
      equal(list.querySelector('li:nth-child(1) > a').innerHTML, 'Profile')
      equal(list.querySelector('li:nth-child(2) > a').innerHTML, 'Settings')
      equal(list.querySelector('li:nth-child(3) > a').innerHTML, 'Notifications')
      equal(list.querySelector('li:nth-child(4) > a').innerHTML, 'Files')
      equal(list.querySelector('li:nth-child(5) > a').innerHTML, 'ePortfolios')
    })

    test('renders the list without Profiles', () => {
      const component = TestUtils.renderIntoDocument(
        <ProfileTray
          userDisplayName={'Sample Student'}
          userAvatarURL={imageurl}
          profileEnabled={false}
          eportfoliosEnabled={true}
          closeTray={noop}
        />
      )

      const list = TestUtils.findRenderedDOMComponentWithTag(component, 'ul')
      ok(list)

      equal(list.querySelectorAll('li').length, 4)
      equal(list.querySelector('li:nth-child(1) > a').innerHTML, 'Settings')
      equal(list.querySelector('li:nth-child(2) > a').innerHTML, 'Notifications')
      equal(list.querySelector('li:nth-child(3) > a').innerHTML, 'Files')
      equal(list.querySelector('li:nth-child(4) > a').innerHTML, 'ePortfolios')
    })

    test('renders the list without ePortfolios', () => {
      const component = TestUtils.renderIntoDocument(
        <ProfileTray
          userDisplayName={'Sample Student'}
          userAvatarURL={imageurl}
          profileEnabled={true}
          eportfoliosEnabled={false}
          closeTray={noop}
        />
      )
      const avatar = TestUtils.findRenderedDOMComponentWithClass(component, 'ic-avatar')
      ok(avatar)

      const list = TestUtils.findRenderedDOMComponentWithTag(component, 'ul')
      ok(list)

      equal(list.querySelectorAll('li').length, 4)
      equal(list.querySelector('li:nth-child(1) > a').innerHTML, 'Profile')
      equal(list.querySelector('li:nth-child(2) > a').innerHTML, 'Settings')
      equal(list.querySelector('li:nth-child(3) > a').innerHTML, 'Notifications')
      equal(list.querySelector('li:nth-child(4) > a').innerHTML, 'Files')
    })
  }
)

const imageurl = `data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolf
O0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8
hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0
UjIQA7`
