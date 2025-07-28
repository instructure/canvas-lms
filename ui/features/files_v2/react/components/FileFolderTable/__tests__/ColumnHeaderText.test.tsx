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

import {ColumnHeaderText, ColumnHeaderTextProps} from '../ColumnHeaderText'
import {render, screen} from '@testing-library/react'

const defaultProps: ColumnHeaderTextProps = {
  columnHeader: {
    id: 'name',
    title: 'Name',
    textAlign: 'start',
    isSortable: true,
    screenReaderLabel: 'Sort by name',
  },
  isStacked: false,
}

const renderComponent = (props: Partial<ColumnHeaderTextProps> = {}) => {
  const mergedProps = {...defaultProps, ...props}
  return render(<ColumnHeaderText {...mergedProps} />)
}

describe('ColumnHeaderText', () => {
  it('renders title and screen reader content', () => {
    renderComponent()
    const nameText = screen.getByText('Name')
    expect(nameText).toBeInTheDocument()
    expect(nameText).toHaveAttribute('aria-hidden', 'true')
    expect(screen.getByText('Sort by name')).toBeInTheDocument()
  })

  it('does not render the screen reader label when stacked', () => {
    renderComponent({isStacked: true})
    const nameText = screen.getByText('Name')
    expect(nameText).toBeInTheDocument()
    expect(nameText).toHaveAttribute('aria-hidden', 'false')
    expect(screen.queryByText('Sort by name')).not.toBeInTheDocument()
  })
})
