/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import BlueprintAssociations from '../BlueprintAssociations'
import getSampleData from './getSampleData'

describe('BlueprintAssociations component', () => {
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
    hasUnsyncedChanges: false,
    subAccounts: getSampleData().subAccounts,
    terms: getSampleData().terms,
  })

  test('renders the BlueprintAssociations component', () => {
    const {container} = render(<BlueprintAssociations {...defaultProps()} />)
    const node = container.querySelector('.bca__wrapper')
    expect(node).toBeTruthy()
  })

  test('displays saving spinner when saving', () => {
    const props = defaultProps()
    props.isSavingAssociations = true
    const {container} = render(<BlueprintAssociations {...props} />)
    const node = container.querySelector('.bca__overlay__save-wrapper [class*="spinner"]')
    expect(node).toBeTruthy()
  })

  test('renders a child CoursePicker component', () => {
    const {container} = render(<BlueprintAssociations {...defaultProps()} />)
    const node = container.querySelector('.bca-course-picker')
    expect(node).toBeTruthy()
  })

  test('renders a child AssociationsTable component', () => {
    const {container} = render(<BlueprintAssociations {...defaultProps()} />)
    const node = container.querySelector('.bca-associations-table')
    expect(node).toBeTruthy()
  })

  test('render save warning if there are existing associations, new associations, and unsynced changes', () => {
    const props = defaultProps()
    props.existingAssociations = getSampleData().courses
    props.addedAssociations = getSampleData().courses
    props.hasUnsyncedChanges = true
    const {getByText} = render(<BlueprintAssociations {...props} />)
    const node = getByText('Warning:')
    expect(node).toBeTruthy()
  })

  test('render no save warning if there are existing associations, new associations, but no unsynced changes', () => {
    const props = defaultProps()
    props.existingAssociations = getSampleData().courses
    props.addedAssociations = getSampleData().courses
    props.hasUnsyncedChanges = false
    const {queryByText} = render(<BlueprintAssociations {...props} />)
    const node = queryByText('Warning:')
    expect(node).toBeFalsy()
  })

  test('render no save warning if there are existing associations, unsynced changes, but no new associations', () => {
    const props = defaultProps()
    props.existingAssociations = getSampleData().courses
    props.addedAssociations = []
    props.hasUnsyncedChanges = true
    const {queryByText} = render(<BlueprintAssociations {...props} />)
    const node = queryByText('Warning:')
    expect(node).toBeFalsy()
  })

  test('render no save warning if there are new associations, unsynced changes, but no existing associations', () => {
    const props = defaultProps()
    props.existingAssociations = []
    props.addedAssociations = getSampleData().courses
    props.hasUnsyncedChanges = true
    const {queryByText} = render(<BlueprintAssociations {...props} />)
    const node = queryByText('Warning:')
    expect(node).toBeFalsy()
  })
})
