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
import AssociationsTable from 'jsx/blueprint_courses/components/AssociationsTable'
import FocusManager from 'jsx/blueprint_courses/focusManager'
import getSampleData from '../getSampleData'

QUnit.module('AssociationsTable component')

const focusManager = new FocusManager()
focusManager.before = document.body

const defaultProps = () => ({
  existingAssociations: getSampleData().courses,
  addedAssociations: [],
  removedAssociations: [],
  onRemoveAssociations: () => {},
  isLoadingAssociations: false,
  focusManager,
})

test('renders the AssociationsTable component', () => {
  const tree = enzyme.shallow(<AssociationsTable {...defaultProps()} />)
  const node = tree.find('.bca-associations-table')
  ok(node.exists())
})

test('displays correct table data', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<AssociationsTable {...props} />)
  const rows = tree.find('.bca-associations__course-row')

  equal(rows.length, props.existingAssociations.length)
  equal(rows.at(0).find('td').at(0).text(), props.existingAssociations[0].name)
  equal(rows.at(1).find('td').at(0).text(), props.existingAssociations[1].name)
})

test('calls onRemoveAssociations when association remove button is clicked', () => {
  const props = defaultProps()
  props.onRemoveAssociations = sinon.spy()
  const tree = enzyme.mount(<AssociationsTable {...props} />)
  const button = tree.find('.bca-associations__course-row form')
  button.at(0).simulate('submit')

  equal(props.onRemoveAssociations.callCount, 1)
  deepEqual(props.onRemoveAssociations.getCall(0).args[0], ['1'])
})
