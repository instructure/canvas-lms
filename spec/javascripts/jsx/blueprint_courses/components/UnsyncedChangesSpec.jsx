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
import {Provider} from 'react-redux'
import {mount} from 'enzyme'
import createStore from '@canvas/blueprint-courses/react/store'
import {ConnectedUnsyncedChanges} from 'ui/features/blueprint_course_master/react/components/UnsyncedChanges'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'

const noop = () => {}
const unsyncedChanges = [
  {
    asset_id: '22',
    asset_type: 'assignment',
    asset_name: 'Another Discussion',
    change_type: 'deleted',
    html_url: '/courses/4/assignments/22',
    locked: false,
  },
  {
    asset_id: '96',
    asset_type: 'attachment',
    asset_name: 'Bulldog.png',
    change_type: 'updated',
    html_url: '/courses/4/files/96',
    locked: true,
  },
  {
    asset_id: 'page-1',
    asset_type: 'wiki_page',
    asset_name: 'Page 1',
    change_type: 'created',
    html_url: '/4/pages/page-1',
    locked: false,
  },
  {
    asset_id: '5',
    asset_type: 'media_track',
    asset_name: 'media.mp4',
    change_type: 'created',
    html_url: '/media_attachments/96/media_tracks',
    locked: false,
    locale: 'en',
  },
]

const defaultProps = {
  unsyncedChanges,
  isLoadingUnsyncedChanges: false,
  hasLoadedUnsyncedChanges: true,
  migrationStatus: MigrationStates.unknown,

  willSendNotification: false,
  willIncludeCustomNotificationMessage: false,
  notificationMessage: '',
}
const actionProps = {
  loadUnsyncedChanges: noop,
  enableSendNotification: noop,
  includeCustomNotificationMessage: noop,
  setNotificationMessage: noop,
}

function mockStore(props = {...defaultProps}) {
  return createStore({...props})
}

function connect(props = {...defaultProps}) {
  const store = mockStore()
  return (
    <Provider store={store}>
      <ConnectedUnsyncedChanges {...props} {...actionProps} />
    </Provider>
  )
}

QUnit.module('UnsyncedChanges component')

test('renders the UnsyncedChanges component', () => {
  const tree = mount(connect())
  let node = tree.find('UnsyncedChanges')
  ok(node.exists())
  node = tree.find('.bcs__history')
  ok(node.exists())
})

test('renders the migration options component', () => {
  const tree = mount(connect())
  const node = tree.find('MigrationOptions')
  ok(node.exists())
})

test('renders the changes properly', () => {
  const tree = mount(connect())
  const changes = tree.find('tr[data-testid="bcs__unsynced-item"]')
  equal(changes.length, 4)
  const locks = changes.find('IconBlueprintLockSolid')
  equal(locks.length, 1)
  const unlocks = changes.find('IconBlueprintSolid')
  equal(unlocks.length, 3)
})

test('renders the media tracks properly', () => {
  const tree = mount(connect())
  const changes = tree.find('tr[data-testid="bcs__unsynced-item"]')
  equal(changes.length, 4)
  const assetName = changes.findWhere(
    node =>
      node.name() === 'Text' &&
      node.text() === 'media.mp4 (English)' &&
      node.parent().type() === 'span'
  )
  equal(assetName.length, 1)
  const assetType = changes.findWhere(
    node => node.name() === 'Text' && node.text() === 'Caption' && node.parent().type() === 'td'
  )
  equal(assetType.length, 1)
})
