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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {SectionToolbar} from '../SectionToolbar'

const props: Record<string, any> = {} // Initialize props

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props: {iconName: undefined},
      }
    }),
  }
})

describe('SectionToolbar', () => {
  it('renders', () => {
    const {getByText} = render(<SectionToolbar />)

    expect(getByText('Background Color')).toBeInTheDocument()
  })

  it.skip('opens the color modal when the color button is clicked', () => {
    // can't render ColorModal yet due to instui issue. See ColorModal.test.tsx for details
    const {getByText, queryByText} = render(<SectionToolbar />)

    expect(queryByText('Enter a hex color value')).not.toBeInTheDocument()

    getByText('Background Color').click()

    expect(getByText('Enter a hex color value')).toBeInTheDocument()
  })
})
