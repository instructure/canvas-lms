/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import TruncateWithTooltip from '../TruncateWithTooltip'

jest.mock('@instructure/ui-truncate-text', () => ({
  TruncateText: ({children}) => <span data-testid="truncate-text">{children}</span>,
}))
jest.mock('@instructure/ui-tooltip', () => ({
  Tooltip: ({renderTip}) => <div role="tooltip">{renderTip}</div>,
}))

const defaultProps = (props = {}) => ({
  mountNode: document.createElement('div'),
  ...props,
})
const renderTruncateWithTooltip = (text, props = {}) => {
  const ref = React.createRef()
  const wrapper = render(
    <TruncateWithTooltip {...defaultProps(props)} ref={ref}>
      {text}
    </TruncateWithTooltip>
  )

  return {wrapper, ref}
}

describe('TruncateWithTooltip', () => {
  it('renders short text', () => {
    renderTruncateWithTooltip('This is some text')

    expect(screen.getByText('This is some text')).toBeInTheDocument()
  })

  it('shows TruncateText if text is not truncated', () => {
    renderTruncateWithTooltip('TruncateText')

    expect(screen.getByText('TruncateText')).toBeInTheDocument()
    expect(screen.getByTestId('truncate-text')).toBeInTheDocument()
  })

  it('does not include a tooltip for short text', () => {
    renderTruncateWithTooltip('This is some text')

    expect(screen.queryByRole('tooltip')).not.toBeInTheDocument()
  })

  it('shows Tooltip for truncated text', () => {
    const {ref} = renderTruncateWithTooltip('Tooltip', '100px')

    ref.current.setState({isTruncated: true})

    expect(screen.getByRole('tooltip')).toBeInTheDocument()
  })
})
