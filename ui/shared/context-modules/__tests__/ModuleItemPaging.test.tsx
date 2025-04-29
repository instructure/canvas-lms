/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {ModuleItemPaging} from '../utils/ModuleItemPaging'

describe('ModuleItemPaging', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    document.body.innerHTML = '<div id="flash_screenreader_holder" role="alert"></div>'
  })
  it('renders loading state', () => {
    const {getAllByText} = render(<ModuleItemPaging isLoading={true} />)
    expect(getAllByText('Loading items')).toHaveLength(2)
  })

  it('renders pagination', () => {
    const {getByTestId} = render(
      <ModuleItemPaging
        isLoading={false}
        paginationOpts={{
          moduleId: '1083',
          currentPage: 1,
          totalPages: 2,
          onPageChange: () => {},
        }}
      />,
    )
    expect(getByTestId('module-1083-pagination')).toBeInTheDocument()
  })

  it('renders nothing when no pagination options are provided', () => {
    const {container} = render(<ModuleItemPaging isLoading={false} />)
    expect(container).toBeEmptyDOMElement()
  })
})
