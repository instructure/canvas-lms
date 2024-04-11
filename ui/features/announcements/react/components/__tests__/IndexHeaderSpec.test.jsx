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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {shallow} from 'enzyme'
import IndexHeader from '../IndexHeader'
import sinon from 'sinon'

function makeProps() {
  return {
    applicationElement: () => document.getElementById('fixtures'),
    contextId: '1',
    contextType: 'course',
    deleteSelectedAnnouncements: jest.fn(),
    isBusy: false,
    permissions: {
      create: true,
      manage_course_content_edit: true,
      manage_course_content_delete: true,
      moderate: true,
    },
    searchAnnouncements: jest.fn(),
    selectedCount: 0,
    toggleSelectedAnnouncementsLock: jest.fn(),
    announcementsLocked: false,
    isToggleLocking: false,
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

describe('"Add Announcement" button', () => {
  test('is present when the user has permission to create an announcement', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    const node = wrapper.find('#add_announcement')
    expect(node.exists()).toBeTruthy()
  })

  test('is absent when the user does not have permission to create an announcement', () => {
    const props = makeProps()
    props.permissions.create = false
    const wrapper = shallow(<IndexHeader {...props} />)
    const node = wrapper.find('#add_announcement')
    expect(node.exists()).toBeFalsy()
  })
})

describe('searching announcements', () => {
  test('calls the searchAnnouncements prop with searchInput value after debounce timeout', async () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = render(<IndexHeader {...props} />)
    const input = wrapper.container.querySelector('input')
    const user = userEvent.setup({delay: null})
    await user.type(input, 'foo')
    const searchOptions = await waitForSpyToBeCalled(spy)
    expect(searchOptions[0]).toEqual({term: 'foo'})
    wrapper.unmount()
  })
})

describe('"Announcement Filter" select', () => {
  test('includes two options in the filter select component', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    const filtersText = wrapper.find('option').map(option => option.text())
    expect(filtersText).toEqual(['All', 'Unread'])
  })

  test('calls the searchAnnouncements prop when selecting a filter option', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = shallow(<IndexHeader {...props} />)
    const onChange = wrapper.find('select').prop('onChange')
    onChange({target: {value: 'unread'}})
    expect(spy.callCount).toEqual(1)
  })

  test('includes the filter value when calling the searchAnnouncements prop', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.searchAnnouncements = spy
    const wrapper = shallow(<IndexHeader {...props} />)
    const onChange = wrapper.find('select').prop('onChange')
    onChange({target: {value: 'unread'}})
    const searchOptions = spy.lastCall.args[0]
    expect(searchOptions).toEqual({filter: 'unread'})
  })
})

describe('"Lock Selected Announcements" button', () => {
  test('is present when the user has permission to lock announcements', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#lock_announcements').length).toEqual(1)
  })

  test('is absent when the user does not have permission to lock announcements', () => {
    const props = makeProps()
    props.permissions.manage_course_content_edit = false
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#lock_announcements').length).toEqual(0)
  })

  test('is absent when announcements are globally locked', () => {
    const props = makeProps()
    props.announcementsLocked = true
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#lock_announcements').length).toEqual(0)
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#lock_announcements').is('[disabled]')).toBeTruthy()
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#lock_announcements').is('[disabled]')).toBeTruthy()
  })

  test('calls the toggleSelectedAnnouncementsLock prop when clicked', () => {
    const spy = sinon.spy()
    const props = makeProps()
    props.toggleSelectedAnnouncementsLock = spy
    props.selectedCount = 1
    const wrapper = shallow(<IndexHeader {...props} />)
    wrapper.find('#lock_announcements').simulate('click')
    expect(spy.callCount).toEqual(1)
  })
})

describe('"Delete Selected Announcements" button', () => {
  test('is present when the user has permission to delete announcements', () => {
    const props = makeProps()
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#delete_announcements').length).toEqual(1)
  })

  test('is absent when the user does not have permission to delete announcements', () => {
    const props = makeProps()
    props.permissions.manage_course_content_delete = false
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#delete_announcements').length).toEqual(0)
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#delete_announcements').is('[disabled]')).toBeTruthy()
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    const wrapper = shallow(<IndexHeader {...props} />)
    expect(wrapper.find('#delete_announcements').is('[disabled]')).toBeTruthy()
  })

  test('shows the "Confirm Delete" modal when clicked', async () => {
    const props = makeProps()
    props.selectedCount = 1
    const ref = React.createRef()
    const wrapper = render(<IndexHeader {...props} ref={ref} />)
    const delButton = wrapper.container.querySelector('#delete_announcements')
    await userEvent.click(delButton)
    expect(ref.current.deleteModal).toBeTruthy()
  })
})
