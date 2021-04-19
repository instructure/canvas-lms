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
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import moxios from 'moxios'
import sinon from 'sinon'
import {moxiosWait} from 'jest-moxios-utils'
import {waitFor} from '@testing-library/react'

import DashboardCard from '@canvas/dashboard-card/react/DashboardCard'
import CourseActivitySummaryStore from '@canvas/dashboard-card/react/CourseActivitySummaryStore'
import assertions from 'helpers/assertions'

QUnit.module('DashboardCard', {
  setup() {
    this.stream = [
      {
        type: 'DiscussionTopic',
        unread_count: 2,
        count: 7
      },
      {
        type: 'Announcement',
        unread_count: 0,
        count: 3
      }
    ]
    this.props = {
      shortName: 'Bio 101',
      originalName: 'Biology',
      assetString: 'foo',
      href: '/courses/1',
      courseCode: '101',
      id: '1',
      backgroundColor: '#EF4437',
      image: null,
      isFavorited: true,
      connectDragSource: c => c,
      connectDropTarget: c => c
    }
    moxios.install()
    return sandbox.stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})
  },
  teardown() {
    moxios.uninstall()
    localStorage.clear()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.component).parentNode)
    if (this.wrapper) {
      return this.wrapper.remove()
    }
  }
})

function errorRendered() {
  if (document.querySelector['.FlashAlert']) {
    return true
  }
}

test('render', function () {
  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  const $html = $(ReactDOM.findDOMNode(this.component))
  ok($html.attr('class').match(/DashboardCard/))
  const renderSpy = sandbox.spy(this.component, 'render')
  ok(!renderSpy.called, 'precondition')
  CourseActivitySummaryStore.setState({streams: {1: {stream: this.stream}}})
  ok(renderSpy.called, 'should re-render on state update')
})

// eslint-disable-next-line qunit/resolve-async
test('it should be accessible', function (assert) {
  const DashCard = <DashboardCard {...this.props} />
  this.wrapper = $('<div>').appendTo('body')[0]
  this.component = ReactDOM.render(DashCard, this.wrapper)
  const $html = $(ReactDOM.findDOMNode(this.component))
  const done = assert.async()
  assertions.isAccessible($html, done)
})

test('unreadCount', function () {
  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  ok(!this.component.unreadCount('icon-discussion', []), 'should not blow up without a stream')
  equal(
    this.component.unreadCount('icon-discussion', this.stream),
    2,
    'should pass down unread count if stream item corresponding to icon has unread count'
  )
})

test('does not have image attribute when a url is not provided', function () {
  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  strictEqual(
    TestUtils.scryRenderedDOMComponentsWithClass(this.component, 'ic-DashboardCard__header_image')
      .length,
    0,
    'image attribute should not be present'
  )
})

test('has image attribute when url is provided', function () {
  this.props.image = 'http://coolUrl'
  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  const $html = TestUtils.findRenderedDOMComponentWithClass(
    this.component,
    'ic-DashboardCard__header_image'
  )
  ok($html, 'image showing')
})

test('#removeCourseFromFavorites succeeds', function () {
  const handleRerenderSpy = sinon.spy()
  this.props.onConfirmUnfavorite = handleRerenderSpy

  function waitForResponse() {
    if (handleRerenderSpy.calledOnce) {
      return true
    }
  }

  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  this.component.removeCourseFromFavorites()

  return moxiosWait(function () {
    const request = moxios.requests.mostRecent()
    request.respondWith({
      status: 200,
      response: []
    })
  }).then(async function () {
    await waitFor(() => waitForResponse())
    ok(handleRerenderSpy.calledOnce)
  })
})

test('#removeCourseFromFavorites fails', function () {
  const handleRerenderSpy = sinon.spy()
  this.props.onConfirmUnfavorite = handleRerenderSpy

  function waitForAlert() {
    if (errorRendered) {
      return true
    }
  }

  const DashCard = <DashboardCard {...this.props} />
  this.component = TestUtils.renderIntoDocument(DashCard)
  this.component.removeCourseFromFavorites()

  return moxiosWait(function () {
    const request = moxios.requests.mostRecent()
    request.respondWith({
      status: 403,
      response: []
    })
  }).then(async function () {
    await waitFor(() => waitForAlert())
    ok(errorRendered)
  })
})
