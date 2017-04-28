import React from 'react'
import * as enzyme from 'enzyme'
import UnsynchedChanges from 'jsx/blueprint_course_settings/components/UnsynchedChanges'

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

QUnit.module('UnsynchedChanges component')

const defaultProps = () => ({
  unsynchedChanges,
  loadUnsynchedChanges: noop,
  isLoadingUnsynchedChanges: false,
  hasLoadedUnsynchedChanges: true,
  willSendNotification: true,
  enableSendNotification: noop,
  migrationStatus: 'unknown'
})

test('renders the UnsynchedChanges component', () => {
  const tree = enzyme.shallow(<UnsynchedChanges {...defaultProps()} />)
  const node = tree.find('.bcs__history')
  ok(node.exists())
})

test('renders the notification checkbox', () => {
  const tree = enzyme.mount(<UnsynchedChanges {...defaultProps()} />)
  const notificationCheckbox = tree.find('input[type="checkbox"]')
  equal(notificationCheckbox.node.checked, true)
})

test('renders the changes', () => {
  const tree = enzyme.mount(<UnsynchedChanges {...defaultProps()} />)
  const changes = tree.find('.bcs__history-item__change')
  equal(changes.length, 3)
  const locks = tree.find('.bcs__history-item__lock-icon IconLockSolid')
  equal(locks.length, 1)
  const unlocks = tree.find('.bcs__history-item__lock-icon IconUnlockSolid')
  equal(unlocks.length, 2)
})
