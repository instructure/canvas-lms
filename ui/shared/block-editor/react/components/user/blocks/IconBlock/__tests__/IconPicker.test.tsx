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
    const {getByText, getAllByTitle} = render(<IconPicker onSelect={() => {}} />)

    expect(getByText('Select an icon')).toBeInTheDocument()
    expect(getByText('No Icon')).toBeInTheDocument()
    expect(getAllByTitle('idea')).toHaveLength(2) // the div and the svg
  })

  it('should call onSelect with the selected icon', () => {
    const onSelect = jest.fn()
    const {getAllByTitle} = render(<IconPicker onSelect={onSelect} />)

    const icon = getAllByTitle('glasses')[0]
    icon.click()

    expect(onSelect).toHaveBeenCalledWith('glasses')
  })
})
