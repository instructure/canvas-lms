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

import React from 'react'
import {mount} from 'enzyme'
import ProfileTray from '../ProfileTray'

function noop() {}
const imageurl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

describe('MissingPeopleSection', () =>{
  it('renders the component', () => {
    const wrapper = mount(
      <ProfileTray
        userDisplayName="Sample Student"
        userAvatarURL={imageurl}
        profileEnabled
        eportfoliosEnabled
        closeTray={noop}
      />
    )
    expect(wrapper.find('Heading').text()).toEqual('Sample Student')
  })

  it('renders the complete list', () => {
    const wrapper = mount(
      <ProfileTray
        userDisplayName="Sample Student"
        userAvatarURL={imageurl}
        profileEnabled
        eportfoliosEnabled
        closeTray={noop}
      />
    )

    expect(wrapper.find('Avatar').exists()).toBeTruthy()

    expect(wrapper.find('ul li').map(n => n.text())).toEqual([
      'Profile', 'Settings', 'Notifications', 'Files', 'ePortfolios'
    ])
  })

  it('renders the list without Profiles', () => {
    const wrapper = mount(
      <ProfileTray
        userDisplayName="Sample Student"
        userAvatarURL={imageurl}
        profileEnabled={false}
        eportfoliosEnabled
        closeTray={noop}
      />
    )

    expect(wrapper.find('ul li').map(n => n.text())).toEqual(
      ['Settings', 'Notifications', 'Files', 'ePortfolios']
    )
  })

  it('renders the list without ePortfolios', () => {
    const wrapper = mount(
      <ProfileTray
        userDisplayName="Sample Student"
        userAvatarURL={imageurl}
        profileEnabled
        eportfoliosEnabled={false}
        closeTray={noop}
      />
    )
    expect(wrapper.find('Avatar').exists()).toBeTruthy()

    expect(wrapper.find('ul li').map(n => n.text())).toEqual(
      ['Profile', 'Settings', 'Notifications', 'Files']
    )
  })
})
