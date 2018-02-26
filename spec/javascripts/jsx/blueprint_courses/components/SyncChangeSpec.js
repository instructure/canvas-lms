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
import SyncChange from 'jsx/blueprint_courses/components/SyncChange'
import data from '../sampleData'

QUnit.module('SyncChange component')

const defaultProps = () => ({
  change: data.history[0].changes[0],
})

test('renders the SyncChange component', () => {
  const tree = enzyme.shallow(<SyncChange {...defaultProps()} />)
  const node = tree.find('.bcs__history-item__change')
  ok(node.exists())
})

test('renders the SyncChange component expanded when state.isExpanded = true', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncChange {...props} />)
  tree.instance().setState({ isExpanded: true })
  const node = tree.find('.bcs__history-item__change__expanded')
  ok(node.exists())
})

test('toggles isExpanded on click', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncChange {...props} />)
  tree.at(0).simulate('click')

  const node = tree.find('.bcs__history-item__change__expanded')
  ok(node.exists())
})

test('displays the correct exception count', () => {
  const props = defaultProps()
  const tree = enzyme.shallow(<SyncChange {...props} />)
  const pill = tree.find('.pill')
  equal(pill.at(0).text(), '3 exceptions')
})

test('displays the correct exception types', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.mount(<SyncChange {...props} />)
  tree.instance().setState({ isExpanded: true })
  const exceptionGroups = tree.find('li.bcs__history-item__change-exceps__group')
  let exceptionGroup = exceptionGroups.at(0).find('span').at(0)
  equal(exceptionGroup.text(), "Points changed exceptions:")
  exceptionGroup = exceptionGroups.at(1).find('span').at(0)
  equal(exceptionGroup.text(), "Content changed exceptions:")
  exceptionGroup = exceptionGroups.at(2).find('span').at(0)
  equal(exceptionGroup.text(), "Deleted content exceptions:")

})
