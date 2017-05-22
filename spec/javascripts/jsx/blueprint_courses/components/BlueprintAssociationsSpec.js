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
import BlueprintAssociations from 'jsx/blueprint_courses/components/BlueprintAssociations'
import data from '../sampleData'

QUnit.module('BlueprintAssociations component')

const defaultProps = () => ({
  courses: [],
  existingAssociations: [],
  addedAssociations: [],
  removedAssociations: [],
  addAssociations: () => {},
  removeAssociations: () => {},
  loadCourses: () => {},
  loadAssociations: () => {},
  hasLoadedCourses: false,
  isLoadingCourses: false,
  isLoadingAssociations: false,
  isSavingAssociations: false,
  subAccounts: data.subAccounts,
  terms: data.terms,
})

test('renders the BlueprintAssociations component', () => {
  const tree = enzyme.shallow(<BlueprintAssociations {...defaultProps()} />)
  const node = tree.find('.bca__wrapper')
  ok(node.exists())
})

test('displays saving spinner when saving', () => {
  const props = defaultProps()
  props.isSavingAssociations = true
  const tree = enzyme.shallow(<BlueprintAssociations {...props} />)
  const node = tree.find('.bca__overlay__save-wrapper Spinner')
  ok(node.exists())
})

test('renders a child CoursePicker component', () => {
  const tree = enzyme.mount(<BlueprintAssociations {...defaultProps()} />)
  const node = tree.find('CoursePicker')
  ok(node.exists())
})

test('renders a child AssociationsTable component', () => {
  const tree = enzyme.mount(<BlueprintAssociations {...defaultProps()} />)
  const node = tree.find('AssociationsTable')
  ok(node.exists())
})
