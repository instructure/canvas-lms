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
import {render, screen} from '@testing-library/react'
import File from '@canvas/files/backbone/models/File'
import DragFeedback from '../DragFeedback'

describe('DragFeedback', () => {
  test('DF: shows a badge with the number of items being dragged', () => {
    const file = new File({id: 1, name: 'Test File', thumbnail_url: 'blah'})
    const file2 = new File({id: 2, name: 'Test File 2', thumbnail_url: 'blah'})
    file.url = () => 'some_url'
    file2.url = () => 'some_url'

    render(<DragFeedback pageX={1} pageY={1} itemsToDrag={[file, file2]} />)

    const badge = screen.getByText('2') // assuming the badge directly contains the text '2'
    expect(badge).toBeInTheDocument() // checks if the badge is in the document
    expect(badge).toHaveTextContent('2') // checks if the badge text content is '2'
  })
})
