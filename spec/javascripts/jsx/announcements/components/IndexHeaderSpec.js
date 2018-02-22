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
import { mount } from 'enzyme'
import merge from 'lodash/merge'

import IndexHeader, { SEARCH_TIME_DELAY } from 'jsx/announcements/components/IndexHeader'

const makeProps = (props = {}) => merge({
  contextType: 'course',
  contextId: '1',
  permissions: {
    create: true,
    manage_content: true,
    moderate: true,
  },
  isBusy: false,
  selectedCount: 0,
  searchAnnouncements () {},
  toggleSelectedAnnouncementsLock () {},
  deleteSelectedAnnouncements () {},
  applicationElement: () => document.getElementById('fixtures'),
}, props)

QUnit.module('IndexHeader component')

test('renders the component', () => {
  const tree = mount(<IndexHeader {...makeProps()} />)
  const node = tree.find('IndexHeader')
  ok(node.exists())
})

test('renders create announcement button if we have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: true } })} />
  )
  const node = tree.find('#add_announcement')
  ok(node.exists())
})

test('does not render create announcement button if we do not have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: false } })} />
  )
  const node = tree.find('#add_announcement')
  notOk(node.exists())
})

test('onSearch calls searchAnnouncements with searchInput value after debounce timeout', (assert) => {
  const done = assert.async()
  const searchSpy = sinon.spy()
  const tree = mount(
    <IndexHeader {...makeProps({ searchAnnouncements: searchSpy })} />
  )

  tree.find('input[name="announcements_search"]').node.value = 'foo'
  tree.instance().onSearch()

  setTimeout(() => {
    deepEqual(searchSpy.firstCall.args[0], { term: 'foo' })
    done()
  }, SEARCH_TIME_DELAY)
})

test('onSearch calls searchAnnouncements with searchInput value only once within debounce timeout', (assert) => {
  const done = assert.async()
  const searchSpy = sinon.spy()
  const tree = mount(
    <IndexHeader {...makeProps({ searchAnnouncements: searchSpy })} />
  )

  tree.find('input[name="announcements_search"]').node.value = 'foo'
  tree.instance().onSearch()
  tree.instance().onSearch()
  tree.instance().onSearch()

  setTimeout(() => {
    deepEqual(searchSpy.firstCall.args[0], { term: 'foo' })
    equal(searchSpy.callCount, 1)
    done()
  }, SEARCH_TIME_DELAY)
})

test('renders the filter select component', () => {
  const tree = mount(
    <IndexHeader {...makeProps()} />
  )
  const node = tree.find('Select')
  ok(node.exists())
})

test('renders two options in the filter select component', () => {
  const tree = mount(
    <IndexHeader {...makeProps()} />
  )
  const node = tree.find('option')
  equal(node.length, 2)
})

test('onChange on the filter select calls searchAnnouncements with filter value', () => {
  const filterSpy = sinon.spy()
  const tree = mount(
    <IndexHeader {...makeProps({ searchAnnouncements: filterSpy })} />
  )
  const node = tree.find('Select')
  node.props().onChange({target: {value: 'unread'}})
  deepEqual(filterSpy.firstCall.args[0], { filter: 'unread' })
  equal(filterSpy.callCount, 1)
})

test('renders lock announcements button if we have manage_content permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { manage_content: true } })} />
  )
  const node = tree.find('#lock_announcements')
  ok(node.exists())
})

test('does not render lock announcements button if we do not have manage_content permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { manage_content: false } })} />
  )
  const node = tree.find('#lock_announcements')
  notOk(node.exists())
})

test('lock announcements button is disabled if isBusy', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ isBusy: true })} />
  )
  const node = tree.find('#lock_announcements')
  ok(node.is('[disabled]'))
})

test('lock announcements button is disabled if selectedCount is 0', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ selectedCount: 0 })} />
  )
  const node = tree.find('#lock_announcements')
  ok(node.is('[disabled]'))
})

test('renders delete announcements button if we have manage_content permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { manage_content: true } })} />
  )
  const node = tree.find('#delete_announcements')
  ok(node.exists())
})

test('does not render delete announcements button if we do not have manage_content permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { manage_content: false } })} />
  )
  const node = tree.find('#delete_announcements')
  notOk(node.exists())
})

test('delete announcements button is disabled if isBusy', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ isBusy: true })} />
  )
  const node = tree.find('#delete_announcements')
  ok(node.is('[disabled]'))
})

test('delete announcements button is disabled if selectedCount is 0', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ selectedCount: 0 })} />
  )
  const node = tree.find('#delete_announcements')
  ok(node.is('[disabled]'))
})

test('clicking lock announcements button should call toggleSelectedAnnouncementsLock prop', (assert) => {
  const done = assert.async()
  const lockSpy = sinon.spy()
  const tree = mount(
    <IndexHeader {...makeProps({ toggleSelectedAnnouncementsLock: lockSpy, selectedCount: 1 })} />
  )

  tree.find('#lock_announcements').simulate('click')
  setTimeout(() => {
    equal(lockSpy.callCount, 1)
    done()
  })
})

test('clicking delete announcements button should show a confirm modal', (assert) => {
  const done = assert.async()
  const tree = mount(
    <IndexHeader {...makeProps({ selectedCount: 1 })} />
  )
  const instance = tree.instance()

  tree.find('#delete_announcements').simulate('click')
  setTimeout(() => {
    ok(instance.deleteModal)
    instance.deleteModal.hide()
    tree.unmount()
    done()
  })
})

test('does not renders lock announcements button if announcements are globally locked', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ announcementsLocked: true, permissions: { manage_content: true } })} />
  )
  const node = tree.find('#lock_announcements')
  notOk(node.exists())
})
