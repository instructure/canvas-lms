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

const moduleId = '1083'

describe('ModuleItemPaging', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    document.body.innerHTML = '<div id="flash_screenreader_holder" role="alert"></div>'
  })
  it('renders loading state', () => {
    const {getAllByText} = render(<ModuleItemPaging moduleId={moduleId} isLoading={true} />)
    expect(getAllByText('Loading items')).toHaveLength(2)
  })

  it('renders pagination', () => {
    const {getByTestId} = render(
      <ModuleItemPaging
        moduleId={moduleId}
        isLoading={false}
        paginationData={{
          currentPage: 1,
          totalPages: 2,
        }}
        onPageChange={() => {}}
      />,
    )
    expect(getByTestId('module-1083-pagination')).toBeInTheDocument()
  })

  it('renders loading and pagination', () => {
    const {getByTestId, getAllByText} = render(
      <ModuleItemPaging
        moduleId={moduleId}
        isLoading={true}
        paginationData={{
          currentPage: 1,
          totalPages: 2,
        }}
        onPageChange={() => {}}
      />,
    )
    expect(getByTestId('module-1083-pagination')).toBeInTheDocument()
    expect(getAllByText('Loading items')).toHaveLength(2)
  })

  it('does not render pagination if there is no onPageChange callback', () => {
    const {queryByTestId} = render(
      <ModuleItemPaging
        moduleId={moduleId}
        isLoading={false}
        paginationData={{
          currentPage: 1,
          totalPages: 2,
        }}
      />,
    )
    expect(queryByTestId('module-1083-pagination')).toBeNull()
  })

  it('renders nothing when no pagination data is provided', () => {
    const {container} = render(
      <ModuleItemPaging moduleId={moduleId} isLoading={false} onPageChange={() => {}} />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('should add positioning style to spinner container on paginationData exist', () => {
    const {queryByTestId} = render(
      <ModuleItemPaging
        moduleId={moduleId}
        isLoading={true}
        paginationData={{
          currentPage: 1,
          totalPages: 2,
        }}
      />,
    )
    const spinnerContainer = queryByTestId('spinner_container_1083')
    const styles = getComputedStyle(spinnerContainer!)
    expect(styles.position).toBe('absolute')
    expect(styles.insetInlineStart).toBe('-3.5em')
    expect(styles.top).toBe('-.25rem')
  })

  it('should not add positioning style to spinner container on paginationData missing', () => {
    const {queryByTestId} = render(<ModuleItemPaging moduleId={moduleId} isLoading={true} />)
    const spinnerContainer = queryByTestId('spinner_container_1083')
    const styles = getComputedStyle(spinnerContainer!)
    expect(styles.position).not.toBe('absolute')
    expect(styles.insetInlineStart).not.toBe('-3.5em')
    expect(styles.top).not.toBe('-.25rem')
  })
})
