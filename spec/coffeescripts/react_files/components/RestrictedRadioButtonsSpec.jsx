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

import React from 'react'
import ReactDOM from 'react-dom'
import {Simulate} from 'react-dom/test-utils'
import $ from 'jquery'
import 'jquery-migrate'
import RestrictedRadioButtons from '@canvas/files/react/components/RestrictedRadioButtons'
import Folder from '@canvas/files/backbone/models/Folder'

QUnit.module('RestrictedRadioButtons', {
  setup() {
    const props = {
      models: [new Folder({id: 999})],
      radioStateChange: sinon.stub(),
    }
    this.RestrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('renders a publish input field', function () {
  ok(this.RestrictedRadioButtons.publishInput, 'should have a publish input field')
})

test('renders an unpublish input field', function () {
  ok(this.RestrictedRadioButtons.unpublishInput, 'should have an unpublish input field')
})

test('renders a not-visible-in-student-files field', function () {
  ok(this.RestrictedRadioButtons.linkOnly, 'should have an link-only input field')
})

test('renders a calendar option input field', function () {
  ok(this.RestrictedRadioButtons.dateRange, 'should have a calendar input field')
})

QUnit.module('RestrictedRadioButtons Multiple Selected Items', {
  setup() {
    const props = {
      models: [
        new Folder({
          id: 1000,
          hidden: false,
        }),
        new Folder({
          id: 999,
          hidden: true,
        }),
      ],
      radioStateChange: sinon.stub(),
    }
    this.RestrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('defaults to having nothing selected when non common items are selected', function () {
  equal(this.RestrictedRadioButtons.publishInput.checked, false, 'not selected')
  equal(this.RestrictedRadioButtons.unpublishInput.checked, false, 'not selected')
  equal(this.RestrictedRadioButtons.linkOnly.checked, false, 'not selected')
  equal(this.RestrictedRadioButtons.dateRange.checked, false, 'not selected')
})

QUnit.module('RestrictedRadioButtons#extractFormValues', {
  setup() {
    const props = {
      models: [new Folder({id: 999})],
      radioStateChange: sinon.stub(),
    }
    this.restrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('returns the correct object to publish an item', function () {
  this.restrictedRadioButtons.publishInput.checked = true
  Simulate.change(this.restrictedRadioButtons.publishInput)
  const expectedObject = {
    hidden: false,
    unlock_at: '',
    lock_at: '',
    locked: false,
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to unpublish an item', function () {
  this.restrictedRadioButtons.unpublishInput.checked = true
  Simulate.change(this.restrictedRadioButtons.unpublishInput)
  const expectedObject = {
    hidden: false,
    unlock_at: '',
    lock_at: '',
    locked: true,
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to hide an item', function () {
  Simulate.change(this.restrictedRadioButtons.linkOnly)
  const expectedObject = {
    hidden: true,
    unlock_at: '',
    lock_at: '',
    locked: false,
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to restrict an item based on dates', function () {
  Simulate.change(this.restrictedRadioButtons.dateRange)
  this.restrictedRadioButtons.dateRange.checked = true
  $(this.restrictedRadioButtons.unlock_at).data('unfudged-date', 'something else')
  $(this.restrictedRadioButtons.lock_at).data('unfudged-date', 'something')
  const expectedObject = {
    hidden: false,
    unlock_at: 'something else',
    lock_at: 'something',
    locked: false,
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

QUnit.module('RestrictedRadioButtons Multiple Items', {
  setup() {
    const props = {
      models: [
        new Folder({
          id: 999,
          hidden: true,
          lock_at: undefined,
          unlock_at: undefined,
        }),
        new Folder({
          id: 1000,
          hidden: true,
          lock_at: undefined,
          unlock_at: undefined,
        }),
      ],
      radioStateChange: sinon.stub(),
    }
    this.restrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('commonly selected items will open the same defaulted options', function () {
  equal(
    this.restrictedRadioButtons.linkOnly.checked,
    true,
    'link_only is checked for all of the selected items'
  )
})
