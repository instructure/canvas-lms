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

import React from 'react'
import {mount} from 'enzyme'
import Toolbar from 'jsx/files/Toolbar'
import Folder from 'compiled/models/Folder'
import File from 'compiled/models/File'

let file = null
let courseFolder = null
let userFolder = null

const buttonEnabled = button => {
  if (button.length == 1) {
    const el = button.instance()
    if (el.nodeName === 'A') {
      return !el.disabled && el.tabIndex !== -1
    } else if (el.nodeName === 'BUTTON') {
      return !el.disabled
    }
  }
  return false
}

const buttonsEnabled = (toolbar, config) => {
  for (const prop in config) {
    const button = toolbar.find(prop)
    if ((config[prop] && buttonEnabled(button)) || (!config[prop] && !buttonEnabled(button))) {
      continue
    } else {
      return false
    }
  }
  return true
}

QUnit.module('Toolbar', {
  setup() {
    file = new File({id: 1})
    courseFolder = new Folder({context_type: 'Course', context_id: 1})
    userFolder = new Folder({context_type: 'User', context_id: 2})
  }
})

test('renders multi select action items when there is more than one item selected', () => {
  const toolbar = mount(
    <Toolbar
      params="foo"
      query=""
      selectedItems={[file]}
      contextId="1"
      contextType="courses"
    />
  )
  ok(toolbar.find('.ui-buttonset .ui-button').exists(), 'shows multiple select action items')
})

test('renders only view and download buttons for limited users', () => {
  const toolbar = mount(
    <Toolbar
      params="foo"
      query=""
      selectedItems={[file]}
      currentFolder={userFolder}
      contextId="2"
      contextType="users"
      userCanManageFilesForContext={false}
    />
  )
  const config = {
    '.btn-view': true,
    '.btn-download': true,
    '.btn-move': false,
    '.btn-restrict': false,
    '.btn-delete': false,
    '.btn-add-folder': false,
    '.btn-upload': false
  }
  ok(buttonsEnabled(toolbar, config), 'only view and download buttons are shown')
})

test('renders all buttons for users with manage_files permissions', () => {
  const toolbar = mount(
    <Toolbar
      params="foo"
      query=""
      selectedItems={[file]}
      currentFolder={courseFolder}
      contextId="1"
      contextType="courses"
      userCanManageFilesForContext
      userCanRestrictFilesForContext
    />
  )

  const config = {
    '.btn-view': true,
    '.btn-download': true,
    '.btn-move': true,
    '.btn-restrict': true,
    '.btn-delete': true,
    '.btn-add-folder': true,
    '.btn-upload': true
  }
  ok(
    buttonsEnabled(toolbar, config),
    'move, restrict access, delete, add folder, and upload file buttons are additionally shown for users with manage_files permissions'
  )
})

test('disables preview button on folder', () => {
  const toolbar = mount(
    <Toolbar
      params="foo"
      query=""
      selectedItems={[userFolder]}
      currentFolder={courseFolder}
      contextId="1"
      contextType="courses"
      userCanManageFilesForContext
      userCanRestrictFilesForContext
    />
  )
  const config = {
    '.btn-view': false,
    '.btn-download': true,
    '.btn-move': true,
    '.btn-restrict': true,
    '.btn-delete': true,
    '.btn-add-folder': true,
    '.btn-upload': true
  }
  ok(buttonsEnabled(toolbar, config), 'view button hidden when folder selected')
})
