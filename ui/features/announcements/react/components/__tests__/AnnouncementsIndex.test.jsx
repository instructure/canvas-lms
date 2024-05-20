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
import {Provider} from 'react-redux'
import _ from 'lodash'
import sinon from 'sinon'

import AnnouncementsIndex from '../AnnouncementsIndex'

const announcements = [
    {
      id: '1',
      position: 2,
      published: true,
      title: 'hello world',
      message: 'lorem ipsum foo bar baz',
      posted_at: new Date().toString(),
      author: {
        id: '1',
        display_name: 'John Doe',
        name: 'John Doe',
        html_url: 'http://example.org/user/5',
      },
      read_state: 'read',
      unread_count: 0,
      discussion_subentry_count: 0,
      locked: false,
      user_count: 2,
      html_url: 'http://example.org/announcement/5',
      permissions: {
        delete: true,
      },
    },
  ]

const makeProps = (props = {}) =>
  _.merge(
    {
      announcements: [],
      announcementsPage: 1,
      isCourseContext: true,
      isLoadingAnnouncements: false,
      hasLoadedAnnouncements: false,
      announcementsLastPage: 5,
      permissions: {
        create: true,
        manage_course_content_delete: true,
        manage_course_content_edit: true,
        moderate: true,
      },
      getAnnouncements: jest.fn(),
      announcementSelectionChangeStart: jest.fn(),
      setAnnouncementSelection: jest.fn(),
      deleteAnnouncements: jest.fn(),
      toggleAnnouncementsLock: jest.fn(),
      announcementsLocked: false,
    },
    props
  )

// necessary to mock this because we have a child Container/"Smart" component
// that need to pull their props from the store state
const store = {
  getState: () => ({
    announcementsLocked: false,
    contextType: 'course',
    contextId: '1',
    isToggleLocking: false,
    permissions: {
      create: true,
      manage_course_content_delete: true,
      manage_course_content_edit: true,
      moderate: true,
    },
    selectedAnnouncements: [],
  }),
  // we only need to define these functions so that we match the react-redux contextTypes
  // shape for a store otherwise react-redux thinks our store is invalid
  dispatch() {},
  subscribe() {},
}

describe('AnnouncementsIndex component', function () {
  test('renders the component', () => {
    const ref = React.createRef()
    render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps()} ref={ref} />
      </Provider>
    )
    expect(ref.current).toBeTruthy()
  })

  test('displays spinner when loading announcements', () => {
    const tree = shallow(<AnnouncementsIndex {...makeProps({isLoadingAnnouncements: true})} />)
    const node = tree.find('Spinner')
    expect(node.exists()).toBeTruthy()
  })

  test('calls getAnnouncements if hasLoadedAnnouncements is false', () => {
    const getAnnouncements = sinon.spy()
    render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps({getAnnouncements})} />
      </Provider>
    )
    expect(getAnnouncements.callCount).toEqual(1)
  })

  test('should render IndexHeader if we have manage_course_content_edit/delete permissions', () => {
    const tree = render(
      <Provider store={store}>
        <AnnouncementsIndex
          {...makeProps({
            permissions: {manage_course_content_delete: true, manage_course_content_edit: true},
          })}
        />
      </Provider>
    )
    expect(tree.queryAllByText('Announcement Filter')).toBeTruthy()
  })

  test('should render IndexHeader even if we do not have manage_course_content_edit/delete permissions', () => {
    const tree = render(
      <Provider store={store}>
        <AnnouncementsIndex
          {...makeProps({
            permissions: {manage_course_content_delete: true, manage_course_content_edit: true},
          })}
        />
      </Provider>
    )
    expect(tree.queryAllByText('Announcement Filter')).toBeTruthy()
  })

  test('clicking announcement checkbox triggers setAnnouncementSelection with correct data', async () => {
    const selectSpy = sinon.spy()
    const props = {
      announcements: announcements,
      announcementSelectionChangeStart: selectSpy,
      hasLoadedAnnouncements: true,
      permissions: {moderate: true, manage_course_content_delete: true},
    }
    const tree = render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps(props)} />
      </Provider>
    )

    const checkbox = tree.container.querySelector('input[type="checkbox"]')
    await userEvent.click(checkbox)
    setTimeout(() => {
      expect(selectSpy.callCount).toEqual(1)
      expect(selectSpy.firstCall.args).toEqual([{selected: true, id: announcements[0].id}])
    })
  })

  test('does not show checkbox if manage_course_content_edit/delete is false', () => {
    const selectSpy = sinon.spy()
    const props = {
      announcements: announcements,
      announcementSelectionChangeStart: selectSpy,
      hasLoadedAnnouncements: true,
      permissions: {
        moderate: true,
        manage_course_content_delete: false,
        manage_course_content_edit: false,
      },
    }
    const tree = render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps(props)} />
      </Provider>
    )

    expect(tree.container.querySelector('input[type="checkbox"]')).toBeFalsy()
  })

  test('onManageAnnouncement shows delete modal when called with delete action', done => {
    const props = {
      announcements: announcements,
      hasLoadedAnnouncements: true,
      permissions: {
        moderate: true,
      },
    }

    function indexRef(c) {
      if (c) {
        c.onManageAnnouncement(null, {action: 'delete'})

        setTimeout(() => {
          expect(c.deleteModal).toBeTruthy()
          c.deleteModal.hide()
          done()
        })
      }
    }

    render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps(props)} ref={indexRef} />
      </Provider>
    )
  })

  test('onManageAnnouncement calls toggleAnnouncementsLock when called with lock action', done => {
    const lockSpy = sinon.spy()
    const props = {
      announcements: announcements,
      hasLoadedAnnouncements: true,
      permissions: {
        moderate: true,
      },
      toggleAnnouncementsLock: lockSpy,
    }
    function indexRef(c) {
      if (c) {
        c.onManageAnnouncement(null, {action: 'lock'})
        setTimeout(() => {
          expect(lockSpy.callCount).toEqual(1)
          done()
        })
      }
    }
    render(
      <Provider store={store}>
        <AnnouncementsIndex {...makeProps(props)} ref={indexRef} />
      </Provider>
    )
  })
})
