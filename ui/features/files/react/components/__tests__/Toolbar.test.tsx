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
import Toolbar from '../Toolbar'
import Folder from '@canvas/files/backbone/models/Folder'
import File from '@canvas/files/backbone/models/File'

let file: any = null
let courseFolder: any = null
let userFolder: any = null

const buttonEnabled = (el: any) => {
  if (el) {
    if (el.nodeName === 'A') {
      return !el.disabled && el.tabIndex !== -1
    } else if (el.nodeName === 'BUTTON') {
      return !el.disabled
    }
  }
  return false
}

const buttonsEnabled = (toolbar: any, config: any) => {
  for (const selector in config) {
    const button = toolbar.container.querySelector(selector)
    if (
      (config[selector] && buttonEnabled(button)) ||
      (!config[selector] && !buttonEnabled(button))
    ) {
      continue
    } else {
      return false
    }
  }
  return true
}

describe('Toolbar', () => {
  beforeEach(() => {
    file = new File({id: 1})
    courseFolder = new Folder({context_type: 'Course', context_id: 1})
    userFolder = new Folder({context_type: 'User', context_id: 2})
  })

  test('renders multi select action items when there is more than one item selected', () => {
    const toolbar = render(
      <Toolbar params="foo" query="" selectedItems={[file]} contextId="1" contextType="courses" />
    )
    toolbar.container.querySelector('.ui-buttonset .ui-button')
    expect(toolbar.container.querySelector('.ui-buttonset .ui-button')).toBeInTheDocument()
  })

  test('renders only view and download buttons for limited users', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[file]}
        currentFolder={userFolder}
        contextId="2"
        contextType="users"
        userCanAddFilesForContext={false}
        userCanEditFilesForContext={false}
        userCanDeleteFilesForContext={false}
        userCanRestrictFilesForContext={false}
      />
    )
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': false,
      '.btn-restrict': false,
      '.btn-delete': false,
      '.btn-add-folder': false,
      '.btn-upload': false,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })

  test('renders all buttons for users with manage_files permissions', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[file]}
        currentFolder={courseFolder}
        contextId="1"
        contextType="courses"
        userCanAddFilesForContext={true}
        userCanEditFilesForContext={true}
        userCanDeleteFilesForContext={true}
        userCanRestrictFilesForContext={true}
      />
    )
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': true,
      '.btn-add-folder': true,
      '.btn-upload': true,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })

  test('does not render add/upload button for users without manage_files_add permission', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[file]}
        currentFolder={courseFolder}
        contextId="1"
        contextType="courses"
        userCanEditFilesForContext={true}
        userCanDeleteFilesForContext={true}
        userCanRestrictFilesForContext={true}
      />
    )
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': true,
      '.btn-add-folder': false,
      '.btn-upload': false,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })

  test('does not render move/restrict button for users without manage_files_edit permission', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[file]}
        currentFolder={courseFolder}
        contextId="1"
        contextType="courses"
        userCanAddFilesForContext={true}
        userCanDeleteFilesForContext={true}
      />
    )
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': false,
      '.btn-restrict': false,
      '.btn-delete': true,
      '.btn-add-folder': true,
      '.btn-upload': true,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })

  test('does not render delete button for users without manage_files_delete permission', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[file]}
        currentFolder={courseFolder}
        contextId="1"
        contextType="courses"
        userCanAddFilesForContext={true}
        userCanEditFilesForContext={true}
        userCanRestrictFilesForContext={true}
      />
    )
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': false,
      '.btn-add-folder': true,
      '.btn-upload': true,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })

  test('disables preview button on folder', () => {
    const toolbar = render(
      <Toolbar
        params="foo"
        query=""
        selectedItems={[userFolder]}
        currentFolder={courseFolder}
        contextId="1"
        contextType="courses"
        userCanAddFilesForContext={true}
        userCanEditFilesForContext={true}
        userCanDeleteFilesForContext={true}
        userCanRestrictFilesForContext={true}
      />
    )
    const config = {
      '.btn-view': false,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': true,
      '.btn-add-folder': true,
      '.btn-upload': true,
    }
    expect(buttonsEnabled(toolbar, config)).toBeTruthy()
  })
})
