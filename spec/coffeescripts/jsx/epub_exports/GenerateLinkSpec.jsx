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

import 'jquery-migrate'
import React from 'react'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import GenerateLink from 'ui/features/epub_exports/react/GenerateLink'
import CourseEpubExportStore from 'ui/features/epub_exports/react/CourseStore'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('epub_exports')

QUnit.module('GenerateLink', {
  setup() {
    this.props = {
      course: {
        name: 'Maths 101',
        id: 1,
      },
    }
  },
})

test('showGenerateLink', function () {
  const ref = React.createRef()
  render(<GenerateLink {...this.props} ref={ref} />)
  ok(ref.current.showGenerateLink(), 'should be true without epub_export object')

  this.props.course.epub_export = {permissions: {regenerate: false}}
  render(<GenerateLink {...this.props} ref={ref} />)
  notOk(ref.current.showGenerateLink(), 'should be false without permissions to regenerate')

  this.props.course.epub_export = {permissions: {regenerate: true}}
  render(<GenerateLink {...this.props} ref={ref} />)
  ok(ref.current.showGenerateLink(), 'should be true with permissions to regenerate')
})

test('state triggered', function () {
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

test('render', async function () {
  const user = userEvent.setup({ delay: null })
  const clock = sinon.useFakeTimers()
  sinon.stub(CourseEpubExportStore, 'create')

  const ref = React.createRef()
  let wrapper = render(<GenerateLink {...this.props} ref={ref} />)
  const button = wrapper.container.querySelector('button')
  equal(button.type, 'button', 'tag should be a button')
  ok(wrapper.getAllByText(I18n.t('Generate ePub')), 'should show generate text')

  await user.click(button)
  const text = wrapper.getByText(I18n.t('Generating...'))
  ok(text, 'should show generating text')
  equal(text.tagName, 'SPAN', 'tag should be span')

  this.props.course.epub_export = {permissions: {regenerate: true}}
  wrapper = render(<GenerateLink {...this.props} />)
  clock.tick(2000)
  equal(wrapper.container.querySelector('button').type, 'button', 'tag should be a button')
  ok(wrapper.getAllByText(I18n.t('Regenerate ePub')), 'should show regenerate text')

  clock.restore()
  CourseEpubExportStore.create.restore()
})
