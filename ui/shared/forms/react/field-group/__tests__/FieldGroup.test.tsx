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
import FieldGroup, {type FieldGroupProps} from '../FieldGroup'

describe('FieldGroup', () => {
  const errorMessage = {type: 'newError', text: 'Error message'} as const
  const hintMessage = {type: 'hint', text: 'Hint message'} as const
  const props: FieldGroupProps = {
    title: 'Search Criteria',
    children: 'Content',
  }

  it('should render the title and the content', () => {
    render(<FieldGroup {...props} />)
    const title = screen.getByText(props.title)
    const content = screen.getByText('Content')

    expect(title).toBeInTheDocument()
    expect(content).toBeInTheDocument()
  })

  describe('when the group is required', () => {
    it('should render the title with an asterisk', () => {
      render(<FieldGroup {...props} isRequired={true} />)
      const title = screen.getByText(props.title)

      expect(title).toHaveTextContent(`${props.title}*`)
    })
  })

  describe('when the group is NOT required', () => {
    it('should render the title without an asterisk', () => {
      render(<FieldGroup {...props} isRequired={false} />)
      const title = screen.getByText(props.title)

      expect(title).toBeInTheDocument()
    })
  })

  describe('when an error message is provided', () => {
    it('should render the error message', () => {
      render(<FieldGroup {...props} messages={[errorMessage]} />)
      const error = screen.getByText(errorMessage.text)
      const errorIcon = screen.getByTestId('error-icon')

      expect(error).toBeInTheDocument()
      expect(errorIcon).toBeInTheDocument()
    })
  })

  describe('when an hint message is provided', () => {
    it('should render the hint message', () => {
      render(<FieldGroup {...props} messages={[hintMessage]} />)
      const hint = screen.getByText(hintMessage.text)

      expect(hint).toBeInTheDocument()
    })
  })
})
