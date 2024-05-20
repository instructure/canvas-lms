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
import {shallow} from 'enzyme'
import createStore from '@canvas/backbone/createStore'
import CourseHomeDialog from '@canvas/course-homepage/react/Dialog'

const xhrs = []
let fakeXhr

QUnit.module('CourseHomeDialog', {
  setup: () => {
    fakeXhr = sinon.useFakeXMLHttpRequest()
    fakeXhr.onCreate = xhr => xhrs.push(xhr)
  },

  teardown: () => {
    fakeXhr.restore()
  },
})

const store = createStore({
  selectedDefaultView: 'modules',
  savedDefaultView: 'modules',
})

const getDefaultProps = () => ({
  store,
  onRequestClose: () => {},
  wikiUrl: 'example.com',
  courseId: '1',
  open: true,
  isPublishing: false,
})

test('Renders', () => {
  const dialog = shallow(<CourseHomeDialog {...getDefaultProps()} />)
  ok(dialog.exists())
})

test('enables wiki selection if front page is provided', () => {
  const isWikiDisabled = wrapper => wrapper.find({value: 'wiki'}).props().disabled

  const noWiki = shallow(<CourseHomeDialog {...getDefaultProps()} />)
  ok(isWikiDisabled(noWiki), 'wiki radio should be disabled')

  const hasWiki = shallow(<CourseHomeDialog {...getDefaultProps()} wikiFrontPageTitle="Welcome" />)
  ok(!isWikiDisabled(hasWiki), 'wiki radio should be enabled')
})

const submitButton = wrapper => wrapper.find('Button').last()

test('Saves the preference on submit', assert => {
  const onSubmit = sinon.spy()

  const dialog = shallow(<CourseHomeDialog {...getDefaultProps()} onSubmit={onSubmit} />)

  store.setState({selectedDefaultView: 'assignments'})
  submitButton(dialog).simulate('click')

  const resolved = assert.async()
  window.setTimeout(() => {
    equal(xhrs.length, 1)
    xhrs[0].respond([200, {}, {}])
  })
  window.setTimeout(() => {
    ok(onSubmit.called)
    resolved()
  })
})

test('calls onRequestClose when cancel is clicked', () => {
  const onRequestClose = sinon.spy()
  const dialog = shallow(
    <CourseHomeDialog {...getDefaultProps()} onRequestClose={onRequestClose} />
  )
  const cancelBtn = dialog.find('Button').at(0)
  equal(cancelBtn.props().children, 'Cancel')
  cancelBtn.simulate('click')
  ok(onRequestClose.called)
})

test('save button disabled when publishing if modules selected', () => {
  store.setState({selectedDefaultView: 'modules'})
  let dialog = shallow(<CourseHomeDialog {...getDefaultProps()} isPublishing />)
  ok(submitButton(dialog).props().disabled, 'submit disabled when modules selected')

  store.setState({selectedDefaultView: 'feed'})
  dialog = shallow(<CourseHomeDialog {...getDefaultProps()} />)
  ok(!submitButton(dialog).props().disabled, 'submit enabled when modules not selected')
})
