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

import AnnouncementsIndex from 'jsx/announcements/components/AnnouncementsIndex'

const defaultProps = () => ({
  announcements: [],
  announcementsPage: 1,
  isLoadingAnnouncements: false,
  hasLoadedAnnouncements: false,
  getAnnouncements: () => {},
})

QUnit.module('AnnouncementsIndex component')

test('renders the component', () => {
  const tree = mount(<AnnouncementsIndex {...defaultProps()} />)
  const node = tree.find('AnnouncementsIndex')
  ok(node.exists())
})

test('displays spinner when loading announcements', () => {
  const props = defaultProps()
  props.isLoadingAnnouncements = true
  const tree = shallow(<AnnouncementsIndex {...props} />)
  const node = tree.find('Spinner')
  ok(node.exists())
})

test('calls getAnnouncements if hasLoadedAnnouncements is false', () => {
  const props = defaultProps()
  props.getAnnouncements = sinon.spy()
  mount(<AnnouncementsIndex {...props} />)
  equal(props.getAnnouncements.callCount, 1)
})