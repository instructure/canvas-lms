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
import {IconPicker} from '..'

describe('IconPicker', () => {
  it('should render', () => {
    // @ts-expect-error
    const {getByText, getByTitle} = render(<IconPicker onSelect={() => {}} />)

    expect(getByText('Select an icon')).toBeInTheDocument()
    expect(getByText('No Icon')).toBeInTheDocument()
    expect(getByTitle('idea')).toBeInTheDocument() // an arbitrary icon
  })

  it('should call onSelect with the selected icon', () => {
    const onSelect = jest.fn()
    // @ts-expect-error
    const {getByTitle} = render(<IconPicker onSelect={onSelect} />)

    const icon = getByTitle('glasses').closest('div[role="button"]') as HTMLButtonElement
    icon.click()

    expect(onSelect).toHaveBeenCalledWith('glasses')
  })

  it('should select the given icon', () => {
    // @ts-expect-error
    const {getByTitle} = render(<IconPicker iconName="idea" onSelect={() => {}} />)

    const some_icon = getByTitle('calendar').closest('div[role="button"]') as HTMLButtonElement
    expect(some_icon).toHaveAttribute('class', 'icon-picker__icon')

    const selected_icon = getByTitle('idea').closest('div[role="button"]') as HTMLButtonElement
    expect(selected_icon).toHaveAttribute('class', 'icon-picker__icon selected')
  })
})
