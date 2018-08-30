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
import {shallow, mount} from 'enzyme'

import IndexHeader from 'jsx/announcements/components/IndexHeader'

function makeProps() {
  return {
    applicationElement: () => document.getElementById('fixtures'),
    contextId: '1',
    contextType: 'course',
    deleteSelectedAnnouncements() {},
    isBusy: false,
    permissions: {
      create: true,
      manage_content: true,
      moderate: true
    },
    searchAnnouncements: () => {},
    selectedCount: 0,
    toggleSelectedAnnouncementsLock: () => {}
  }
}

function waitForSpyToBeCalled(spy) {
  return new Promise(resolve => {
    const interval = setInterval(() => {
      if (spy.callCount > 0) {
        clearInterval(interval)
        resolve(spy.lastCall.args)
      }
    }, 10)
  })
}

QUnit.module('"Add Announcement" button', () => {
  test('is present when the user has permission to create an announcement', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    const node = wrapper.find('#add_announcement')
    ok(node.exists())
  })

  test('is absent when the user does not have permission to create an announcement', () => {
    const props = makeProps()
    props.permissions.create = false
    const wrapper = shallow(<IndexHeader {...props} />)
    const node = wrapper.find('#add_announcement')
    notOk(node.exists())
  })
})

QUnit.module('searching announcements', () => {
  test('calls the searchAnnouncements prop with searchInput value after debounce timeout', async () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = mount(<IndexHeader {...props} />)
    const input = wrapper.find('TextInput').find('input')
    input.instance().value = 'foo'
    input.simulate('change', {target: {value: 'foo'}})
    const searchOptions = await waitForSpyToBeCalled(spy)
    deepEqual(searchOptions[0], {term: 'foo'})
    wrapper.unmount()
  })
})

QUnit.module('"Announcement Filter" select', () => {
  test('includes two options in the filter select component', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    const filtersText = wrapper.find('option').map(option => option.text())
    deepEqual(filtersText, ['All', 'Unread'])
  })

  test('calls the searchAnnouncements prop when selecting a filter option', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = shallow(<IndexHeader {...props} />)
    const onChange = wrapper.find('Select').prop('onChange')
    onChange({target: {value: 'unread'}})
    strictEqual(spy.callCount, 1)
  })

  test('includes the filter value when calling the searchAnnouncements prop', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = shallow(<IndexHeader {...props} />)
    const onChange = wrapper.find('Select').prop('onChange')
    onChange({target: {value: 'unread'}})
    const searchOptions = spy.lastCall.args[0]
    deepEqual(searchOptions, {filter: 'unread'})
  })
})

QUnit.module('"Lock Selected Announcements" button', () => {
  test('is present when the user has permission to lock announcements', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#lock_announcements').length, 1)
  })

  test('is absent when the user does not have permission to lock announcements', () => {
    const props = makeProps()
    props.permissions.manage_content = false
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#lock_announcements').length, 0)
  })

  test('is absent when announcements are globally locked', () => {
    const props = makeProps()
    props.announcementsLocked = true
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#lock_announcements').length, 0)
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#lock_announcements').is('[disabled]'), true)
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#lock_announcements').is('[disabled]'), true)
  })

  test('calls the toggleSelectedAnnouncementsLock prop when clicked', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.toggleSelectedAnnouncementsLock = spy
    props.selectedCount = 1
    const wrapper = shallow(<IndexHeader {...props} />)
    wrapper.find('#lock_announcements').simulate('click')
    strictEqual(spy.callCount, 1)
  })
})

QUnit.module('"Delete Selected Announcements" button', () => {
  test('is present when the user has permission to delete announcements', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#delete_announcements').length, 1)
  })

  test('is absent when the user does not have permission to delete announcements', () => {
    const props = makeProps()
    props.permissions.manage_content = false
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#delete_announcements').length, 0)
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#delete_announcements').is('[disabled]'), true)
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    const wrapper = shallow(<IndexHeader {...props} />)
    strictEqual(wrapper.find('#delete_announcements').is('[disabled]'), true)
  })

  test('shows the "Confirm Delete" modal when clicked', () => {
    const props = makeProps()
    props.selectedCount = 1
    const wrapper = shallow(<IndexHeader {...props} />)
    wrapper.find('#delete_announcements').simulate('click')
    ok(wrapper.instance().deleteModal)
  })
})
