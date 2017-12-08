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
import {mount} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'

import IndexHeader from 'jsx/announcements/components/IndexHeader'

QUnit.module('Announcements IndexHeader', suiteHooks => {
  let props
  let qunitTimeout
  let wrapper

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 1000 // prevent accidental unresolved async

    props = {
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
      searchAnnouncements: sinon.spy(),
      selectedCount: 0,
      toggleSelectedAnnouncementsLock: sinon.spy()
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    QUnit.config.testTimeout = qunitTimeout
  })

  function mountComponent() {
    wrapper = mount(<IndexHeader {...props} />)
  }

  QUnit.module('"Add Announcement" button', () => {
    test('is present when the user has permission to create an announcement', () => {
      mountComponent()
      const node = wrapper.find('#add_announcement')
      ok(node.exists())
    })

    test('is absent when the user does not have permission to create an announcement', () => {
      props.permissions.create = false
      const node = wrapper.find('#add_announcement')
      notOk(node.exists())
    })
  })

  QUnit.module('searching announcements', () => {
    function waitForSearch() {
      return new Promise(resolve => {
        const interval = setInterval(() => {
          if (props.searchAnnouncements.callCount > 0) {
            clearInterval(interval)
            resolve(props.searchAnnouncements.lastCall.args)
          }
        }, 10)
      })
    }

    test('calls the searchAnnouncements prop with searchInput value after debounce timeout', async () => {
      mountComponent()
      const input = wrapper.find('input[name="announcements_search"]')
      input.node.value = 'foo'
      input.simulate('change', {target: {value: 'foo'}})
      const searchOptions = await waitForSearch()
      deepEqual(searchOptions[0], {term: 'foo'})
    })
  })

  QUnit.module('"Announcement Filter" select', () => {
    test('includes two options in the filter select component', () => {
      mountComponent()
      const filtersText = wrapper.find('option').map(option => option.text())
      deepEqual(filtersText, ['All', 'Unread'])
    })

    test('calls the searchAnnouncements prop when selecting a filter option', () => {
      mountComponent()
      const onChange = wrapper.find('Select').prop('onChange')
      onChange({target: {value: 'unread'}})
      strictEqual(props.searchAnnouncements.callCount, 1)
    })

    test('includes the filter value when calling the searchAnnouncements prop', () => {
      mountComponent()
      const onChange = wrapper.find('Select').prop('onChange')
      onChange({target: {value: 'unread'}})
      const searchOptions = props.searchAnnouncements.lastCall.args[0]
      deepEqual(searchOptions, {filter: 'unread'})
    })
  })

  QUnit.module('"Lock Selected Announcements" button', () => {
    test('is present when the user has permission to lock announcements', () => {
      mountComponent()
      strictEqual(wrapper.find('#lock_announcements').length, 1)
    })

    test('is absent when the user does not have permission to lock announcements', () => {
      props.permissions.manage_content = false
      mountComponent()
      strictEqual(wrapper.find('#lock_announcements').length, 0)
    })

    test('is absent when announcements are globally locked', () => {
      props.announcementsLocked = true
      mountComponent()
      strictEqual(wrapper.find('#lock_announcements').length, 0)
    })

    test('is disabled when "isBusy" is true', () => {
      props.isBusy = true
      mountComponent()
      strictEqual(wrapper.find('#lock_announcements').is('[disabled]'), true)
    })

    test('is disabled when "selectedCount" is 0', () => {
      props.selectedCount = 0
      mountComponent()
      strictEqual(wrapper.find('#lock_announcements').is('[disabled]'), true)
    })

    test('calls the toggleSelectedAnnouncementsLock prop when clicked', () => {
      props.selectedCount = 1
      mountComponent()
      wrapper.find('#lock_announcements').simulate('click')
      strictEqual(props.toggleSelectedAnnouncementsLock.callCount, 1)
    })
  })

  QUnit.module('"Delete Selected Announcements" button', () => {
    test('is present when the user has permission to delete announcements', () => {
      mountComponent()
      strictEqual(wrapper.find('#delete_announcements').length, 1)
    })

    test('is absent when the user does not have permission to delete announcements', () => {
      props.permissions.manage_content = false
      mountComponent()
      strictEqual(wrapper.find('#delete_announcements').length, 0)
    })

    test('is disabled when "isBusy" is true', () => {
      props.isBusy = true
      mountComponent()
      strictEqual(wrapper.find('#delete_announcements').is('[disabled]'), true)
    })

    test('is disabled when "selectedCount" is 0', () => {
      props.selectedCount = 0
      mountComponent()
      strictEqual(wrapper.find('#delete_announcements').is('[disabled]'), true)
    })

    test('shows the "Confirm Delete" modal when clicked', () => {
      props.selectedCount = 1
      mountComponent()
      wrapper.find('#delete_announcements').simulate('click')
      ok(wrapper.instance().deleteModal)
      wrapper.instance().deleteModal.hide()
    })
  })
})
