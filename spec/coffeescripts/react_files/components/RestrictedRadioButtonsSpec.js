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
import {Simulate} from 'react-addons-test-utils'
import $ from 'jquery'
import RestrictedRadioButtons from 'jsx/files/RestrictedRadioButtons'
import Folder from 'compiled/models/Folder'

QUnit.module('RestrictedRadioButtons', {
  setup() {
    const props = {
      models: [new Folder({id: 999})],
      radioStateChange: sinon.stub()
    }
    this.RestrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.RestrictedRadioButtons).parentNode)
    $('#fixtures').empty()
  }
})

test('renders a publish input field', function() {
  ok(this.RestrictedRadioButtons.refs.publishInput, 'should have a publish input field')
})

test('renders an unpublish input field', function() {
  ok(this.RestrictedRadioButtons.refs.unpublishInput, 'should have an unpublish input field')
})

test('renders a permissions input field', function() {
  Simulate.change(this.RestrictedRadioButtons.refs.permissionsInput)
  ok(this.RestrictedRadioButtons.refs.permissionsInput, 'should have an permissions input field')
})

test('renders a calendar option input field', function() {
  Simulate.change(this.RestrictedRadioButtons.refs.permissionsInput)
  ok(this.RestrictedRadioButtons.refs.dateRange, 'should have a dateRange input field')
})

QUnit.module('RestrictedRadioButtons Multiple Selected Items', {
  setup() {
    const props = {
      models: [
        new Folder({
          id: 1000,
          hidden: false
        }),
        new Folder({
          id: 999,
          hidden: true
        })
      ],
      radioStateChange: sinon.stub()
    }
    this.RestrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.RestrictedRadioButtons).parentNode)
    $('#fixtures').empty()
  }
})

test('defaults to having nothing selected when non common items are selected', function() {
  equal(this.RestrictedRadioButtons.refs.publishInput.checked, false, 'not selected')
  equal(this.RestrictedRadioButtons.refs.unpublishInput.checked, false, 'not selected')
  equal(
    this.RestrictedRadioButtons.refs.permissionsInput.checked,
    false,
    'not selected'
  )
})

test('selecting the restricted access option default checks the hiddenInput option', function() {
  this.RestrictedRadioButtons.refs.permissionsInput.checked = true
  Simulate.change(this.RestrictedRadioButtons.refs.permissionsInput)
  equal(
    this.RestrictedRadioButtons.refs.link_only.checked,
    true,
    'default checks hiddenInput'
  )
})

QUnit.module('RestrictedRadioButtons#extractFormValues', {
  setup() {
    const props = {
      models: [new Folder({id: 999})],
      radioStateChange: sinon.stub()
    }
    this.restrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.restrictedRadioButtons).parentNode)
    $('#fixtures').empty()
  }
})

test('returns the correct object to publish an item', function() {
  this.restrictedRadioButtons.refs.publishInput.checked = true
  Simulate.change(this.restrictedRadioButtons.refs.publishInput)
  const expectedObject = {
    hidden: false,
    unlock_at: '',
    lock_at: '',
    locked: false
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to unpublish an item', function() {
  this.restrictedRadioButtons.refs.unpublishInput.checked = true
  Simulate.change(this.restrictedRadioButtons.refs.unpublishInput)
  const expectedObject = {
    hidden: false,
    unlock_at: '',
    lock_at: '',
    locked: true
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to hide an item', function() {
  this.restrictedRadioButtons.refs.permissionsInput.checked = true
  Simulate.change(this.restrictedRadioButtons.refs.permissionsInput)
  const expectedObject = {
    hidden: true,
    unlock_at: '',
    lock_at: '',
    locked: false
  }
  deepEqual(
    this.restrictedRadioButtons.extractFormValues(),
    expectedObject,
    'returns the correct object'
  )
})

test('returns the correct object to restrict an item based on dates', function() {
  Simulate.change(this.restrictedRadioButtons.refs.permissionsInput)
  Simulate.change(this.restrictedRadioButtons.refs.dateRange)
  this.restrictedRadioButtons.refs.dateRange.checked = true
  $(this.restrictedRadioButtons.refs.unlock_at).data('unfudged-date', 'something else')
  $(this.restrictedRadioButtons.refs.lock_at).data('unfudged-date', 'something')
  const expectedObject = {
    hidden: false,
    unlock_at: 'something else',
    lock_at: 'something',
    locked: false
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
          unlock_at: undefined
        }),
        new Folder({
          id: 1000,
          hidden: true,
          lock_at: undefined,
          unlock_at: undefined
        })
      ],
      radioStateChange: sinon.stub()
    }
    this.restrictedRadioButtons = ReactDOM.render(
      <RestrictedRadioButtons {...props} />,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.restrictedRadioButtons).parentNode)
    $('#fixtures').empty()
  }
})

test('commonly selected items will open the same defaulted options', function() {
  equal(
    this.restrictedRadioButtons.refs.permissionsInput.checked,
    true,
    'permissionsInput is checked for all of the selected items'
  )
  equal(
    this.restrictedRadioButtons.refs.link_only.checked,
    true,
    'link_only is checked for all of the selected items'
  )
})
