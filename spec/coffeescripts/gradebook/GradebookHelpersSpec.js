/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import GradebookHelpers from 'compiled/gradebook/GradebookHelpers'
import GradebookConstants from 'jsx/gradebook/shared/constants'

QUnit.module('GradebookHelpers#noErrorsOnPage', {
  setup() {
    sandbox.stub($, 'find')
  }
})

test('noErrorsOnPage returns true when the dom has no errors', function() {
  $.find.returns([])
  ok(GradebookHelpers.noErrorsOnPage())
})

test('noErrorsOnPage returns false when the dom contains errors', function() {
  $.find.returns(['dom element with error message'])
  notOk(GradebookHelpers.noErrorsOnPage())
})

QUnit.module('GradebookHelpers#textareaIsGreaterThanMaxLength')

test('textareaIsGreaterThanMaxLength is false at exactly the max allowed length', () =>
  notOk(GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH)))

test('textareaIsGreaterThanMaxLength is true at greater than the max allowed length', () =>
  ok(GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH + 1)))

QUnit.module('GradebookHelpers#maxLengthErrorShouldBeShown', {
  setup() {
    sandbox.stub($, 'find')
  }
})

test('maxLengthErrorShouldBeShown is false when text length is exactly the max allowed length', () =>
  notOk(GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH)))

test('maxLengthErrorShouldBeShown is false when there are DOM errors', function() {
  $.find.returns(['dom element with error message'])
  notOk(GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1))
})

test(
  'maxLengthErrorShouldBeShown is true when text length is greater than' +
    'the max allowed length AND there are no DOM errors',
  function() {
    $.find.returns([])
    ok(GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1))
  }
)
