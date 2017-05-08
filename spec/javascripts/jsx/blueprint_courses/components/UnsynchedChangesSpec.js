import React from 'react'
import { Provider } from 'react-redux'
import * as enzyme from 'enzyme'
import createStore from 'jsx/blueprint_courses/store'
import {ConnectedUnsynchedChanges} from 'jsx/blueprint_courses/components/UnsynchedChanges'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'

const noop = () => {}
const unsynchedChanges = [
  {
    asset_id: '22',
    asset_type: 'assignment',
    asset_name: 'Another Discussion',
    change_type: 'deleted',
    html_url: '/courses/4/assignments/22',
    locked: false
  },
  {
    asset_id: '96',
    asset_type: 'attachment',
    asset_name: 'Bulldog.png',
    change_type: 'updated',
    html_url: '/courses/4/files/96',
    locked: true
  },
  {
    asset_id: 'page-1',
    asset_type: 'wiki_page',
    asset_name: 'Page 1',
    change_type: 'created',
    html_url: '/4/pages/page-1',
    locked: false
  }
]

const defaultProps = {
  unsynchedChanges,
  isLoadingUnsynchedChanges: false,
  hasLoadedUnsynchedChanges: true,
  migrationStatus: MigrationStates.unknown,

  willSendNotification: false,
  willIncludeCustomNotificationMessage: false,
  notificationMessage: '',
}
const actionProps = {
  loadUnsynchedChanges: noop,
  enableSendNotification: noop,
  includeCustomNotificationMessage: noop,
  setNotificationMessage: noop,
}

function mockStore (props = {...defaultProps}) {
  return createStore({...props})
}

function connect (props = {...defaultProps}) {
  const store = mockStore()
  return (
    <Provider store={store}>
      <ConnectedUnsynchedChanges {...props} {...actionProps} />
    </Provider>
  )
}

QUnit.module('UnsynchedChanges component')

test('renders the UnsynchedChanges component', () => {
  const tree = enzyme.mount(connect())
  let node = tree.find('UnsynchedChanges')
  ok(node.exists())
  node = tree.find('.bcs__history')
  ok(node.exists())
})

test('renders the enable notification component', () => {
  const tree = enzyme.mount(connect())
  const node = tree.find('EnableNotification')
  ok(node.exists())
})

test('renders the changes', () => {
  const tree = enzyme.mount(connect())
  const changes = tree.find('.bcs__history-item__change')
  equal(changes.length, 3)
  const locks = tree.find('.bcs__history-item__lock-icon IconLockSolid')
  equal(locks.length, 1)
  const unlocks = tree.find('.bcs__history-item__lock-icon IconUnlockSolid')
  equal(unlocks.length, 2)
})
