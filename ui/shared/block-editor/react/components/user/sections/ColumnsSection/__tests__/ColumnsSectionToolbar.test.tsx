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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {ColumnsSection} from '../ColumnsSection'
import {ColumnsSectionToolbar} from '../ColumnsSectionToolbar'

const user = userEvent.setup()

let props = {...ColumnsSection.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props,
      }
    }),
  }
})

describe('ColumnsSectionToolbar', () => {
  beforeEach(() => {
    props = {...ColumnsSection.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<ColumnsSectionToolbar />)

    expect(getByText('Columns')).toBeInTheDocument()
    expect(getByText('Column style')).toBeInTheDocument()
  })

  it('checks the right column variant', async () => {
    const {getByText} = render(<ColumnsSectionToolbar />)

    const btn = getByText('Column style').closest('button') as HTMLButtonElement
    await user.click(btn)

    const fixed = screen.getByText('Fixed')
    const fluid = screen.getByText('Fluid')

    expect(fixed).toBeInTheDocument()
    expect(fluid).toBeInTheDocument()

    const li = fixed.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('changes the variant prop on changing the style', async () => {
    const {getByText} = render(<ColumnsSectionToolbar />)

    const btn = getByText('Column style').closest('button') as HTMLButtonElement
    await user.click(btn)

    const fluid = screen.getByText('Fluid')
    await user.click(fluid)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.variant).toBe('fluid')
  })

  it('shows the column count button', () => {
    const {getByText} = render(<ColumnsSectionToolbar />)

    const btn = getByText('Columns').closest('button') as HTMLButtonElement
    expect(btn).toBeInTheDocument()
  })

  // the rest is tested in ColumnCountPopup.test.tsx
})
