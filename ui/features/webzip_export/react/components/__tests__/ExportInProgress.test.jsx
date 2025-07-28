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
import {render} from '@testing-library/react'
import ExportInProgress from '../ExportInProgress'

describe('ExportInProgress', () => {
  test('renders the ExportInProgress component', () => {
    const webzip = {progressId: '117'}
    const {container} = render(<ExportInProgress webzip={webzip} loadExports={() => {}} />)
    const node = container.querySelector('.webzipexport__inprogress')

    expect(node).toBeInTheDocument()
  })

  test('does not render when completed is true', () => {
    const webzip = {progressId: '117'}
    const {container, rerender} = render(
      <ExportInProgress webzip={webzip} loadExports={() => {}} />,
    )

    expect(container.querySelector('.webzipexport__inprogress')).toBeInTheDocument()
  })
})
