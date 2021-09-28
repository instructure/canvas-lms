/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PreviewIcon from '../PreviewIcon'

describe('PreviewIcon()', () => {
  let props = {testId: 'preview-icon'}
  const subject = props => render(<PreviewIcon {...props} />)

  it('renders with the correct width', () => {
    const {getByTestId} = subject(props)

    expect(getByTestId('preview-icon')).toHaveStyle('width: 25px')
  })

  it('renders with the correct height', () => {
    const {getByTestId} = subject(props)

    expect(getByTestId('preview-icon')).toHaveStyle('height: 25px')
  })

  describe('when a color is provided', () => {
    beforeEach(() => {
      props = {
        color: '#06A3B7',
        testId: 'preview-icon'
      }
    })

    it('renders the given color', () => {
      const {getByTestId} = subject(props)

      expect(getByTestId('preview-icon')).toHaveStyle('background: rgb(6, 163, 183)')
    })
  })

  describe('when the "large" variant is specified', () => {
    beforeEach(() => {
      props = {
        variant: 'large',
        testId: 'preview-icon'
      }
    })

    it('renders with the correct width', () => {
      const {getByTestId} = subject(props)

      expect(getByTestId('preview-icon')).toHaveStyle('width: 50px')
    })

    it('renders with the correct height', () => {
      const {getByTestId} = subject(props)

      expect(getByTestId('preview-icon')).toHaveStyle('height: 50px')
    })

    it('uses the correct gradient', () => {
      const {getByTestId} = subject(props)

      expect(getByTestId('preview-icon')).toHaveStyle(
        'background: linear-gradient(135deg, rgb(255, 255, 255) 50%, rgb(255, 0, 0) 50%, rgb(255, 0, 0) 53%, rgb(255, 255, 255) 53%)'
      )
    })
  })
})
