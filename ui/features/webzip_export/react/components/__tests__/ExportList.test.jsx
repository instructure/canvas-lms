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
import ExportList from '../ExportList'

describe('ExportList', () => {
  it('renders the ExportList component', () => {
    const exports = [
      {
        date: 'July 4, 1776 at 3:33pm',
        link: 'https://example.com/declarationofindependence',
        workflowState: 'generated',
        newExport: false,
      },
      {
        date: 'Nov 9, 1989 at 9am',
        link: 'https://example.com/berlinwallfalls',
        workflowState: 'generated',
        newExport: false,
      },
    ]

    const {container} = render(<ExportList exports={exports} />)
    const node = container.querySelector('.webzipexport__list')
    expect(node).toBeInTheDocument()
  })

  it('renders empty text if there are no exports', () => {
    const exports = []
    const {getByText} = render(<ExportList exports={exports} />)
    expect(getByText('No exports to display')).toBeInTheDocument()
  })
})
