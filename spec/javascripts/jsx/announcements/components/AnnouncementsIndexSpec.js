/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import { mount, shallow } from 'enzyme'
import { Provider } from 'react-redux'
import _ from 'lodash'

import AnnouncementsIndex from 'jsx/announcements/components/AnnouncementsIndex'

const makeProps = (props = {}) => _.merge({
  announcements: [],
  announcementsPage: 1,
  isLoadingAnnouncements: false,
  hasLoadedAnnouncements: false,
  announcementsLastPage: 5,
  permissions: {
    create: true,
    manage_content: true,
    moderate: true,
  },
  getAnnouncements: () => {},
}, props)

// necessary to mock this because we have a child Container/"Smart" component
// that need to pull their props from the store state
const store = {
  getState: () => ({
    courseId: '5',
    permissions: {
      create: true,
      manage_content: true,
      moderate: true,
    },
  }),
  // we only need to define these functions so that we match the react-redux contextTypes
  // shape for a store otherwise react-redux thinks our store is invalid
  dispatch() {},
  subscribe() {},
}

QUnit.module('AnnouncementsIndex component')

test('renders the component', () => {
  const tree = mount(
    <Provider store={store}>
      <AnnouncementsIndex {...makeProps()} />
    </Provider>
  )
  const node = tree.find('AnnouncementsIndex')
  ok(node.exists())
})

test('displays spinner when loading announcements', () => {
  const tree = shallow(<AnnouncementsIndex {...makeProps({ isLoadingAnnouncements: true })} />)
  const node = tree.find('Spinner')
  ok(node.exists())
})

test('calls getAnnouncements if hasLoadedAnnouncements is false', () => {
  const getAnnouncements = sinon.spy()
  mount(
    <Provider store={store}>
      <AnnouncementsIndex {...makeProps({ getAnnouncements })} />
    </Provider>
  )
  equal(getAnnouncements.callCount, 1)
})

test('renders IndexHeader if we have manage_content permissions', () => {
  const tree = mount(
    <Provider store={store}>
      <AnnouncementsIndex {...makeProps({ permissions: { manage_content: true } })} />
    </Provider>
  )
  const node = tree.find('IndexHeader')
  ok(node.exists())
})

test('does not render IndexHeader if we do not have manage_content permissions', () => {
  const tree = mount(
    <Provider store={store}>
      <AnnouncementsIndex {...makeProps({ permissions: { manage_content: false } })} />
    </Provider>
  )
  const node = tree.find('IndexHeader')
  notOk(node.exists())
})
