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
import checkerboardStyle from '../CheckerboardStyling'

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

  it('does not render a spinner', () => {
    const {queryByText} = subject(props)

    expect(queryByText('Loading preview')).not.toBeInTheDocument()
  })

  it('does not have a checkered background by default', () => {
    subject(props)
    const wrapper = document.getElementById('preview-background-wrapper')

    expect(wrapper).not.toHaveAttribute('style')
  })

  describe('when an image data URL is provided', () => {
    beforeEach(() => {
      props = {
        testId: 'preview-icon',
        image:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAQ9CAYAAABwXXr6AAABdGlDQ1BpY2...',
      }
    })

    it('uses the image in the preview', () => {
      const {getByTestId} = subject(props)

      expect(getByTestId('preview-icon')).toHaveStyle(`backgroundImage: url(${props.image})`)
    })
  })

  describe('when a color is provided', () => {
    beforeEach(() => {
      props = {
        color: '#06A3B7',
        testId: 'preview-icon',
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
        testId: 'preview-icon',
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

  describe('when "loading" is true', () => {
    beforeEach(() => {
      props = {
        loading: true,
      }
    })

    it('renders a spinner', () => {
      const {getByText} = subject(props)

      expect(getByText('Loading preview')).toBeInTheDocument()
    })
  })

  describe('when "checkered" is true', () => {
    beforeEach(() => {
      props = {
        checkered: true,
      }
    })

    it('has a checkered background', () => {
      subject(props)
      const wrapper = document.getElementById('preview-background-wrapper')

      expect(wrapper).toHaveStyle(checkerboardStyle(4))
    })
  })
})
