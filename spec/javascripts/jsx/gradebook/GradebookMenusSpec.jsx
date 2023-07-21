/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook#getViewOptionsMenuProps', () => {
  test('hideAssignmentGroupTotals is true when settings.hide_assignment_group_totals is "true"', () => {
    const settings = {hide_assignment_group_totals: 'true'}
    const {hideAssignmentGroupTotals} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(hideAssignmentGroupTotals, true)
  })

  test('hideAssignmentGroupTotals is false when settings.hide_assignment_group_totals is "false"', () => {
    const settings = {hide_assignment_group_totals: 'false'}
    const {hideAssignmentGroupTotals} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(hideAssignmentGroupTotals, false)
  })

  test('hideTotal is true when settings.hide_total is "true"', () => {
    const settings = {hide_total: 'true'}
    const {hideTotal} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(hideTotal, true)
  })

  test('hideTotal is false when settings.hide_total is "false"', () => {
    const settings = {hide_total: 'false'}
    const {hideTotal} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(hideTotal, false)
  })

  test('showSeparateFirstLastNames is false', () => {
    const {showSeparateFirstLastNames} = createGradebook().getViewOptionsMenuProps()
    strictEqual(showSeparateFirstLastNames, false)
  })

  test('showSeparateFirstLastNames is true when settings.show_separate_first_last_names is "true"', () => {
    const settings = {show_separate_first_last_names: 'true'}
    const {showSeparateFirstLastNames} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(showSeparateFirstLastNames, true)
  })

  test('showSeparateFirstLastNames is false when settings.show_separate_first_last_names is "false"', () => {
    const settings = {show_separate_first_last_names: 'false'}
    const {showSeparateFirstLastNames} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(showSeparateFirstLastNames, false)
  })

  test('allowShowSeparateFirstLastNames is true when options.allow_separate_first_last_names is true', () => {
    const {allowShowSeparateFirstLastNames} = createGradebook({
      allow_separate_first_last_names: true,
    }).getViewOptionsMenuProps()
    strictEqual(allowShowSeparateFirstLastNames, true)
  })

  test('allowShowSeparateFirstLastNames is false when options.allow_separate_first_last_names is false', () => {
    const {allowShowSeparateFirstLastNames} = createGradebook({
      allow_separate_first_last_names: false,
    }).getViewOptionsMenuProps()
    strictEqual(allowShowSeparateFirstLastNames, false)
  })

  test('showUnpublishedAssignments is true', () => {
    const {showUnpublishedAssignments} = createGradebook().getViewOptionsMenuProps()
    strictEqual(showUnpublishedAssignments, true)
  })

  test('showUnpublishedAssignments is set via settings.show_unpublished_assignments', () => {
    const settings = {show_unpublished_assignments: false}
    const {showUnpublishedAssignments} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(showUnpublishedAssignments, false)
  })

  test('viewUngradedAsZero is true when settings.view_ungraded_as_zero is "true"', () => {
    const settings = {view_ungraded_as_zero: 'true'}
    const {viewUngradedAsZero} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(viewUngradedAsZero, true)
  })

  test('viewUngradedAsZero is false when settings.view_ungraded_as_zero is "false"', () => {
    const settings = {view_ungraded_as_zero: 'false'}
    const {viewUngradedAsZero} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(viewUngradedAsZero, false)
  })

  test('allowViewUngradedAsZero is true when allow_view_ungraded_as_zero is true', () => {
    const {allowViewUngradedAsZero} = createGradebook({
      allow_view_ungraded_as_zero: true,
    }).getViewOptionsMenuProps()
    strictEqual(allowViewUngradedAsZero, true)
  })

  test('allowViewUngradedAsZero is false when allow_view_ungraded_as_zero is false', () => {
    const {allowViewUngradedAsZero} = createGradebook({
      allow_view_ungraded_as_zero: false,
    }).getViewOptionsMenuProps()
    strictEqual(allowViewUngradedAsZero, false)
  })
})

QUnit.module('Gradebook#renderViewOptionsMenu')

test('passes showUnpublishedAssignments to props', () => {
  const gradebook = createGradebook()
  gradebook.gridDisplaySettings.showUnpublishedAssignments = true
  const createElementStub = sandbox.stub(React, 'createElement')
  sandbox.stub(ReactDOM, 'render')
  gradebook.renderViewOptionsMenu()

  strictEqual(
    createElementStub.firstCall.args[1].showUnpublishedAssignments,
    gradebook.gridDisplaySettings.showUnpublishedAssignments
  )
})

test('passes toggleUnpublishedAssignments as onSelectShowUnpublishedAssignments to props', () => {
  const gradebook = createGradebook()
  gradebook.toggleUnpublishedAssignments = () => {}
  const createElementStub = sandbox.stub(React, 'createElement')
  sandbox.stub(ReactDOM, 'render')
  gradebook.renderViewOptionsMenu()

  strictEqual(
    createElementStub.firstCall.args[1].toggleUnpublishedAssignments,
    gradebook.onSelectShowUnpublishedAssignments
  )
})

QUnit.module('Menus', {
  setup() {
    setFixtureHtml($fixtures)
    this.gradebook = createGradebook({
      context_allows_gradebook_uploads: true,
      export_gradebook_csv_url: 'http://someUrl',
      gradebook_import_url: 'http://someUrl',
      navigate() {},
    })
    this.gradebook.postGradesLtis = []
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('ViewOptionsMenu is rendered on renderViewOptionsMenu', function () {
  this.gradebook.renderViewOptionsMenu()
  const buttonText = this.gradebook.props.viewOptionsMenuNode
    .querySelector('Button')
    .innerText.trim()
  equal(buttonText, 'View')
})

test('ActionMenu is rendered on renderActionMenu when enhanced_gradebook_filters is enabled', function () {
  this.gradebook = createGradebook({
    context_allows_gradebook_uploads: true,
    export_gradebook_csv_url: 'http://someUrl',
    gradebook_import_url: 'http://someUrl',
    enhanced_gradebook_filters: true,
    navigate() {},
  })
  this.gradebook.renderActionMenu()
  const importButtonText = this.gradebook.props.enhancedActionMenuNode
    .querySelectorAll('Button')[0]
    .innerText.trim()
  equal(importButtonText, 'Import')

  const exportButtonText = this.gradebook.props.enhancedActionMenuNode
    .querySelectorAll('Button')[1]
    .innerText.trim()
  equal(exportButtonText, 'Export')
})

test('ActionMenu is rendered on renderActionMenu when enhanced_gradebook_filters is disabled', function () {
  this.gradebook.renderActionMenu()
  const buttonText = this.gradebook.props.actionMenuNode
    .querySelectorAll('Button')[0]
    .innerText.trim()
  equal(buttonText, 'Actions')
})

QUnit.module('Gradebook#updateColumnsAndRenderViewOptionsMenu', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    sinon.stub(gradebook, 'updateColumns')
    sinon.stub(gradebook, 'renderViewOptionsMenu')
  })

  test('calls updateColumns', () => {
    gradebook.updateColumnsAndRenderViewOptionsMenu()
    strictEqual(gradebook.updateColumns.callCount, 1)
  })

  test('calls renderViewOptionsMenu', () => {
    gradebook.updateColumnsAndRenderViewOptionsMenu()
    strictEqual(gradebook.renderViewOptionsMenu.callCount, 1)
  })
})
