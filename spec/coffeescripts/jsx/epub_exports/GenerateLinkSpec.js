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
import {mount} from 'enzyme'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import GenerateLink from 'jsx/epub_exports/GenerateLink'
import CourseEpubExportStore from 'jsx/epub_exports/CourseStore'
import I18n from 'i18n!epub_exports'

QUnit.module('GenerateLink', {
  setup() {
    this.props = {
      course: {
        name: 'Maths 101',
        id: 1
      }
    }
  }
})

test('showGenerateLink', function() {
  let wrapper = mount(<GenerateLink {...this.props} />)
  ok(wrapper.instance().showGenerateLink(), 'should be true without epub_export object')

  this.props.course.epub_export = {permissions: {regenerate: false}}
  wrapper = mount(<GenerateLink {...this.props} />)
  notOk(wrapper.instance().showGenerateLink(), 'should be false without permissions to rengenerate')

  this.props.course.epub_export = {permissions: {regenerate: true}}
  wrapper = mount(<GenerateLink {...this.props} />)
  ok(wrapper.instance().showGenerateLink(), 'should be true with permissions to rengenerate')
})

test('state triggered', function() {
  const clock = sinon.useFakeTimers()
  sinon.stub(CourseEpubExportStore, 'create')
  const GenerateLinkElement = <GenerateLink {...this.props} />
  const component = TestUtils.renderIntoDocument(GenerateLinkElement)
  const node = ReactDOM.findDOMNode(component)
  TestUtils.Simulate.click(node)
  ok(component.state.triggered, 'should set state to triggered')
  clock.tick(1005)
  ok(!component.state.triggered, 'should toggle back to not triggered after 1000')
  clock.restore()
  CourseEpubExportStore.create.restore()
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})

test('render', function() {
  const clock = sinon.useFakeTimers()
  sinon.stub(CourseEpubExportStore, 'create')

  let wrapper = mount(<GenerateLink {...this.props} />)
  equal(wrapper.children().type(), 'button', 'tag should be a button')
  ok(wrapper.text().match(I18n.t('Generate ePub')),'should show generate text')

  wrapper.simulate('click')
  equal(wrapper.children().type(), 'span', 'tag should be span')
  ok(wrapper.text().match(I18n.t('Generating...')), 'should show generating text')

  this.props.course.epub_export = {permissions: {regenerate: true}}
  wrapper = mount(<GenerateLink {...this.props} />)
  clock.tick(2000)
  equal(wrapper.children().type(), 'button', 'tag should be a button')
  ok(wrapper.text().match(I18n.t('Regenerate ePub')), 'should show regenerate text')

  clock.restore()
  CourseEpubExportStore.create.restore()
})
