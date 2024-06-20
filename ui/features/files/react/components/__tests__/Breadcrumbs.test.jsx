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
import {render, screen, cleanup} from '@testing-library/react'
import Breadcrumbs from '../Breadcrumbs'
import Folder from '@canvas/files/backbone/models/Folder'
import fakeENV from '@canvas/test-utils/fakeENV'
import filesEnv from '@canvas/files/react/modules/filesEnv'

describe('Files Breadcrumbs Component', () => {
  beforeEach(() => {
    fakeENV.setup({context_asset_string: 'course_1'})
    filesEnv.baseUrl = '/courses/1/files'
  })

  afterEach(() => {
    cleanup()
    fakeENV.teardown()
  })

  test('generates the home, rootFolder, and other links', () => {
    const sampleProps = {
      rootTillCurrentFolder: [
        new Folder({context_type: 'course', context_id: 1}),
        new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'}),
      ],
      contextAssetString: 'course_1',
    }

    render(<Breadcrumbs {...sampleProps} />)

    const links = screen.getAllByRole('link')
    expect(links.length).toBe(3)
    expect(new URL(links[0].href).pathname).toBe('/')
    expect(new URL(links[1].href).pathname).toBe('/courses/1/files')
    expect(new URL(links[2].href).pathname).toBe('/courses/1/files/folder/test_folder_name')
    expect(links[2].textContent).toBe('test_folder_name')
  })
})