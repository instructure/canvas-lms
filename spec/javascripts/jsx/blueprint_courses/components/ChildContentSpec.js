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
import * as enzyme from 'enzyme'
import ChildContent from 'jsx/blueprint_courses/components/ChildContent'
import getSampleData from '../getSampleData'

QUnit.module('ChildContent app')

const defaultProps = () => ({
  isChangeLogOpen: false,
  terms: getSampleData().terms,
  childCourse: getSampleData().childCourse,
  masterCourse: getSampleData().masterCourse,
  realRef: () => {},
  routeTo: () => {},
  selectChangeLog: () => {},
})

test('renders the ChildContent component', () => {
  const tree = enzyme.shallow(<ChildContent {...defaultProps()} />)
  const node = tree.find('.bcc__wrapper')
  ok(node.exists())
})

test('clearRoutes removes blueprint path', () => {
  const props = defaultProps()
  props.routeTo = sinon.spy()
  const tree = enzyme.shallow(<ChildContent {...props} />)
  const instance = tree.instance()
  instance.clearRoutes()
  equal(props.routeTo.getCall(0).args[0], '#!/')
})

test('showChangeLog calls selectChangeLog prop with argument', () => {
  const props = defaultProps()
  props.selectChangeLog = sinon.spy()
  const tree = enzyme.shallow(<ChildContent {...props} />)
  const instance = tree.instance()
  instance.showChangeLog('5')
  deepEqual(props.selectChangeLog.getCall(0).args[0], '5')
})

test('hideChangeLog calls selectChangeLog prop with null', () => {
  const props = defaultProps()
  props.selectChangeLog = sinon.spy()
  const tree = enzyme.shallow(<ChildContent {...props} />)
  const instance = tree.instance()
  instance.hideChangeLog()
  deepEqual(props.selectChangeLog.getCall(0).args[0], null)
})

test('realRef gets called with component instance on mount', () => {
  const props = defaultProps()
  props.realRef = sinon.spy()
  const tree = enzyme.mount(<ChildContent {...props} />)
  const instance = tree.instance()
  equal(props.realRef.callCount, 1)
  equal(props.realRef.getCall(0).args[0], instance)
})
