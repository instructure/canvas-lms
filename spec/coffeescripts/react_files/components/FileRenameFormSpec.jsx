/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import FileRenameForm from '@canvas/files/react/components/FileRenameForm'

QUnit.module('FileRenameForm', {
  setup() {
    const defaultProps = {
      fileOptions: {
        file: {
          id: 999,
          name: 'original_name.txt',
        },
        name: 'options_name.txt',
      },
    }
    this.renderForm = props => {
      this.form = ReactDOM.render(
        <FileRenameForm {...defaultProps} {...props} />,
        $('<div>').appendTo('#fixtures')[0]
      )
    }
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.form).parentNode)
    $('#fixtures').empty()
  },
})

test('switches to editing file name state with button click', function () {
  this.renderForm()
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  ok(this.form.refs.newName)
})

test('isEditing displays options name by default', function () {
  this.renderForm()
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  equal(this.form.refs.newName.value, 'options_name.txt')
})

test('isEditing displays file name when no options name exists', function () {
  this.renderForm({fileOptions: {file: {name: 'file_name.md'}}})
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  equal(this.form.refs.newName.value, 'file_name.md')
})

test('can go back from isEditing to initial view with button click', function () {
  this.renderForm()
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  ok(this.form.refs.newName)
  Simulate.click(this.form.refs.backBtn)
  ok(!this.form.state.isEditing)
  ok(this.form.refs.replaceBtn)
})

test('calls passed in props method to resolve conflict', function () {
  expect(2)
  this.renderForm({
    fileOptions: {file: {name: 'file_name.md'}},
    onNameConflictResolved(options) {
      ok(options.name)
    },
  })
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  Simulate.click(this.form.refs.commitChangeBtn)
})

test('onNameConflictResolved preserves expandZip option when skipping', function () {
  expect(1)
  this.renderForm({
    fileOptions: {
      file: {name: 'file_name.md'},
      expandZip: 'true',
    },
    onNameConflictResolved(options) {
      equal(options.expandZip, 'true')
    },
    allowSkip: true,
  })
  Simulate.click(this.form.refs.skipBtn)
})

test('onNameConflictResolved preserves expandZip option when renaming', function () {
  expect(2)
  this.renderForm({
    fileOptions: {
      file: {name: 'file_name.md'},
      expandZip: 'true',
    },
    onNameConflictResolved(options) {
      equal(options.expandZip, 'true')
    },
  })
  Simulate.click(this.form.refs.renameBtn)
  ok(this.form.state.isEditing)
  Simulate.click(this.form.refs.commitChangeBtn)
})

test('onNameConflictResolved preserves expandZip option when replacing', function () {
  expect(1)
  this.renderForm({
    fileOptions: {
      file: {name: 'file_name.md'},
      expandZip: 'true',
    },
    onNameConflictResolved(options) {
      equal(options.expandZip, 'true')
    },
  })
  Simulate.click(this.form.refs.replaceBtn)
})

test('renders default rename file message', function () {
  this.renderForm()
  equal(
    this.form.refs.bodyContent.textContent,
    'An item named "options_name.txt" already exists in this location. Do you want to replace the existing file?'
  )
})

test('override rename file message', function () {
  this.renderForm({
    onRenameFileMessage: nameToUse => `rename ${nameToUse} please`,
  })
  equal(this.form.refs.bodyContent.textContent, 'rename options_name.txt please')
})

test('renders default lock file message', function () {
  this.renderForm({
    fileOptions: {
      file: {
        id: 999,
        name: 'original_name.txt',
      },
      name: 'options_name.txt',
      cannotOverwrite: true,
    },
  })
  ok(
    this.form.refs.bodyContent.textContent.match(
      /A locked item named "options_name.txt" already exists in this location. Please enter a new name./
    )
  )
})

test('override lock file message', function () {
  this.renderForm({
    fileOptions: {
      file: {
        id: 999,
        name: 'original_name.txt',
      },
      name: 'options_name.txt',
      cannotOverwrite: true,
    },
    onLockFileMessage: nameToUse => `rename locked file ${nameToUse} please`,
  })
  ok(this.form.refs.bodyContent.textContent.match(/rename locked file options_name.txt please/))
})
