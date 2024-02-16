/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import React from 'react'
import moxios from 'moxios'
import sinon from 'sinon'
import {moxiosWait} from '@canvas/jest-moxios-utils'
import {act, cleanup, render, waitFor} from '@testing-library/react'

import DashboardCard from '@canvas/dashboard-card/react/DashboardCard'
import CourseActivitySummaryStore from '@canvas/dashboard-card/react/CourseActivitySummaryStore'
import assertions from 'helpers/assertions'

QUnit.module('DashboardCard', {
  setup() {
    this.stream = [
      {
        type: 'DiscussionTopic',
        unread_count: 2,
        count: 7,
      },
      {
        type: 'Announcement',
        unread_count: 0,
        count: 3,
      },
    ]
    this.props = {
      shortName: 'Bio 101',
      originalName: 'Biology',
      assetString: 'foo',
      href: '/courses/1',
      courseCode: '101',
      id: '1',
      links: [
        {
          css_class: 'discussions',
          hidden: false,
          icon: 'icon-discussion',
          label: 'Discussions',
          path: '/courses/1/discussion_topics',
        },
      ],
      backgroundColor: '#EF4437',
      image: null,
      isFavorited: true,
      connectDragSource: c => c,
      connectDropTarget: c => c,
    }
    moxios.install()
    return (this.getStateForCourseStub = sandbox
      .stub(CourseActivitySummaryStore, 'getStateForCourse')
      .returns({}))
  },
  teardown() {
    moxios.uninstall()
    localStorage.clear()
    cleanup()
    if (this.wrapper) {
      return this.wrapper.remove()
    }
  },
})

function errorRendered() {
  if (document.querySelector['.FlashAlert']) {
    return true
  }
}

test('obtains new course activity when course activity is updated', function (assert) {
  const {getByText} = render(<DashboardCard {...this.props} />)

  assert.notEqual(getByText(`${this.props.links[0].label} - ${this.props.shortName}`), undefined)
  assert.ok(this.getStateForCourseStub.calledOnce)

  act(() => CourseActivitySummaryStore.setState({streams: {1: {stream: this.stream}}}))

  assert.ok(this.getStateForCourseStub.calledTwice)
})

// eslint-disable-next-line qunit/resolve-async
test('is accessible', function (assert) {
  this.wrapper = $('<div>').appendTo('body')[0]
  const {container} = render(<DashboardCard {...this.props} />, this.wrapper)
  const $html = $(container.firstChild)
  const done = assert.async()
  assertions.isAccessible($html, done)
})

test('does not have an image when a url is not provided', function (assert) {
  const {getByText, queryByText} = render(<DashboardCard {...this.props} />)

  assert.equal(queryByText(`Course image for ${this.props.shortName}`), undefined)
  assert.notEqual(getByText(`Course card color region for ${this.props.shortName}`), undefined)
})

test('has an image when a url is provided', function (assert) {
  this.props.image = 'http://coolUrl'
  const {getByText} = render(<DashboardCard {...this.props} />)

  assert.notEqual(getByText(`Course image for ${this.props.shortName}`), undefined)
})

test('handles success removing course from favorites', async function (assert) {
  const handleRerenderSpy = sinon.spy()
  this.props.onConfirmUnfavorite = handleRerenderSpy

  function waitForResponse() {
    if (handleRerenderSpy.calledOnce) {
      return true
    }
  }

  const {getByText} = render(<DashboardCard {...this.props} />)
  act(() =>
    getByText(
      `Choose a color or course nickname or move course card for ${this.props.shortName}`
    ).click()
  )
  act(() => getByText('Move').click())
  act(() => getByText('Unfavorite').click())
  act(() => getByText('Submit').click())

  await moxiosWait(() => {
    const request = moxios.requests.mostRecent()
    request.respondWith({
      status: 200,
      response: [],
    })
  })

  await waitFor(() => waitForResponse())
  assert.ok(handleRerenderSpy.calledOnce)
})

test('handles failure removing course from favorites', async function (assert) {
  this.props.onConfirmUnfavorite = sinon.spy()

  function waitForAlert() {
    if (errorRendered) {
      return true
    }
  }

  const {getByText} = render(<DashboardCard {...this.props} />)
  act(() =>
    getByText(
      `Choose a color or course nickname or move course card for ${this.props.shortName}`
    ).click()
  )
  act(() => getByText('Move').click())
  act(() => getByText('Unfavorite').click())
  act(() => getByText('Submit').click())

  await moxiosWait(() => {
    const request = moxios.requests.mostRecent()
    request.respondWith({
      status: 403,
      response: [],
    })
  })

  await waitFor(() => waitForAlert())
  assert.ok(errorRendered)
})
