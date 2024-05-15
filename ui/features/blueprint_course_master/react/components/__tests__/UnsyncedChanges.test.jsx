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
import {Provider} from 'react-redux'
import {render} from '@testing-library/react'
import {getByText, getAllByText} from '@testing-library/dom'
import createStore from '@canvas/blueprint-courses/react/store'
import {ConnectedUnsyncedChanges} from '../UnsyncedChanges'
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

describe('UnsyncedChanges component', () => {
  test('renders the UnsyncedChanges component', () => {
    const tree = render(connect())
    let node = tree.container.querySelector('.bcs__unsynced-item__table')
    expect(node).toBeTruthy()
    node = tree.container.querySelector('.bcs__history')
    expect(node).toBeTruthy()
  })

  test('renders the migration options component', () => {
    const tree = render(connect())
    const node = getByText(tree.container, 'History Settings')
    expect(node).toBeTruthy()
  })

  test('renders the changes properly', () => {
    const tree = render(connect())
    const changes = tree.container.querySelectorAll('tr[data-testid="bcs__unsynced-item"]')
    expect(changes.length).toEqual(4)
    const locks = tree.container.querySelectorAll('svg[name="IconBlueprintLock"]')
    expect(locks.length).toEqual(1)
    const unlocks = tree.container.querySelectorAll('svg[name="IconBlueprint"]')
    expect(unlocks.length).toEqual(3)
  })

  test('renders the media tracks properly', () => {
    const tree = render(connect())
    const changes = tree.container.querySelectorAll('tr[data-testid="bcs__unsynced-item"]')
    expect(changes.length).toEqual(4)
    const assetName = getAllByText(tree.container, 'media.mp4 (English)')
    expect(assetName.length).toEqual(1)
    const assetType = getAllByText(tree.container, 'Caption')
    expect(assetType.length).toEqual(1)
  })
})
