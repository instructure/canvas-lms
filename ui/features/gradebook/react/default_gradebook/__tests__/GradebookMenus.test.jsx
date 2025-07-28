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

import {render, screen} from '@testing-library/react'
import React from 'react'
import EnhancedActionMenu from '../components/EnhancedActionMenu'
import ViewOptionsMenu from '../components/ViewOptionsMenu'
import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook Menu Options', () => {
  describe('getViewOptionsMenuProps', () => {
    it('sets hideAssignmentGroupTotals based on settings', () => {
      const settingsTrue = {hide_assignment_group_totals: 'true'}
      const settingsFalse = {hide_assignment_group_totals: 'false'}

      const {hideAssignmentGroupTotals: shouldBeTrue} = createGradebook({
        settings: settingsTrue,
      }).getViewOptionsMenuProps()
      const {hideAssignmentGroupTotals: shouldBeFalse} = createGradebook({
        settings: settingsFalse,
      }).getViewOptionsMenuProps()

      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })

    it('sets hideTotal based on settings', () => {
      const settingsTrue = {hide_total: 'true'}
      const settingsFalse = {hide_total: 'false'}

      const {hideTotal: shouldBeTrue} = createGradebook({
        settings: settingsTrue,
      }).getViewOptionsMenuProps()
      const {hideTotal: shouldBeFalse} = createGradebook({
        settings: settingsFalse,
      }).getViewOptionsMenuProps()

      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })

    it('sets showSeparateFirstLastNames based on settings', () => {
      const defaultGradebook = createGradebook()
      const settingsTrue = {show_separate_first_last_names: 'true'}
      const settingsFalse = {show_separate_first_last_names: 'false'}

      const {showSeparateFirstLastNames: defaultValue} = defaultGradebook.getViewOptionsMenuProps()
      const {showSeparateFirstLastNames: shouldBeTrue} = createGradebook({
        settings: settingsTrue,
      }).getViewOptionsMenuProps()
      const {showSeparateFirstLastNames: shouldBeFalse} = createGradebook({
        settings: settingsFalse,
      }).getViewOptionsMenuProps()

      expect(defaultValue).toBe(false)
      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })

    it('sets allowShowSeparateFirstLastNames based on options', () => {
      const {allowShowSeparateFirstLastNames: shouldBeTrue} = createGradebook({
        allow_separate_first_last_names: true,
      }).getViewOptionsMenuProps()

      const {allowShowSeparateFirstLastNames: shouldBeFalse} = createGradebook({
        allow_separate_first_last_names: false,
      }).getViewOptionsMenuProps()

      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })

    it('sets showUnpublishedAssignments based on settings', () => {
      const defaultGradebook = createGradebook()
      const gradebookWithSettings = createGradebook({
        settings: {show_unpublished_assignments: false},
      })

      const {showUnpublishedAssignments: defaultValue} = defaultGradebook.getViewOptionsMenuProps()
      const {showUnpublishedAssignments: settingsValue} =
        gradebookWithSettings.getViewOptionsMenuProps()

      expect(defaultValue).toBe(true)
      expect(settingsValue).toBe(false)
    })

    it('sets viewUngradedAsZero based on settings', () => {
      const settingsTrue = {view_ungraded_as_zero: 'true'}
      const settingsFalse = {view_ungraded_as_zero: 'false'}

      const {viewUngradedAsZero: shouldBeTrue} = createGradebook({
        settings: settingsTrue,
      }).getViewOptionsMenuProps()
      const {viewUngradedAsZero: shouldBeFalse} = createGradebook({
        settings: settingsFalse,
      }).getViewOptionsMenuProps()

      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })

    it('sets allowViewUngradedAsZero based on options', () => {
      const {allowViewUngradedAsZero: shouldBeTrue} = createGradebook({
        allow_view_ungraded_as_zero: true,
      }).getViewOptionsMenuProps()

      const {allowViewUngradedAsZero: shouldBeFalse} = createGradebook({
        allow_view_ungraded_as_zero: false,
      }).getViewOptionsMenuProps()

      expect(shouldBeTrue).toBe(true)
      expect(shouldBeFalse).toBe(false)
    })
  })

  describe('Menu Rendering', () => {
    it('renders View button in ViewOptionsMenu', () => {
      const gradebook = createGradebook()
      const props = gradebook.getViewOptionsMenuProps()
      render(<ViewOptionsMenu {...props} />)

      const viewButton = screen.getByText('View')
      expect(viewButton).toBeInTheDocument()
    })

    it('renders Import and Export buttons in ActionMenu when enhanced_gradebook_filters is enabled', () => {
      const gradebook = createGradebook({
        context_allows_gradebook_uploads: true,
        export_gradebook_csv_url: 'http://someUrl',
        gradebook_import_url: 'http://someUrl',
        enhanced_gradebook_filters: true,
        navigate: () => {},
        currentUserId: '1',
        postGradesFeature: {
          enabled: true,
          returnFocusTo: document.body,
          label: 'Post Grades',
          store: {},
        },
      })

      const props = {
        ...gradebook.getActionMenuProps(),
        currentUserId: '1',
        postGradesFeature: {
          enabled: true,
          returnFocusTo: document.body,
          label: 'Post Grades',
          store: {},
        },
      }

      render(<EnhancedActionMenu {...props} />)

      const importButton = screen.getByText('Import')
      const exportButton = screen.getByText('Export')

      expect(importButton).toBeInTheDocument()
      expect(exportButton).toBeInTheDocument()
    })
  })
})
