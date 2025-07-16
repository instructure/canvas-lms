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
import {ModuleHeaderCompletionRequirement, getPillColor} from '../ModuleHeaderCompletionRequirement'

type Props = {
  requirementCount?: number
  completed?: boolean
}

const setUp = (props: Props) => {
  return render(<ModuleHeaderCompletionRequirement {...props} />)
}

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {
    requirementCount: undefined,
    completed: false,
  }

  return {...defaultProps, ...overrides}
}

describe('ModuleHeaderCompletionRequirement', () => {
  it('renders properly with default props', () => {
    const {container} = setUp(buildDefaultProps())
    expect(container).not.toBeEmptyDOMElement()
  })

  describe('incomplete text', () => {
    it('renders with "Complete all items" text when no requirementCount and not completed', () => {
      const {getByText} = setUp(buildDefaultProps({requirementCount: undefined, completed: false}))
      expect(getByText('Complete all items')).toBeInTheDocument()
    })

    it('renders with "Complete 1 item" text when requirementCount is provided and not completed', () => {
      const {getByText} = setUp(buildDefaultProps({requirementCount: 1, completed: false}))
      expect(getByText('Complete 1 item')).toBeInTheDocument()
    })
  })

  describe('completed text', () => {
    it('renders with "Completed all items" text when no requirementCount and is completed', () => {
      const {getByText, getByTestId} = setUp(
        buildDefaultProps({requirementCount: undefined, completed: true}),
      )
      expect(getByText('Completed all items')).toBeInTheDocument()
      expect(getByTestId('module-header-completion-requirement-icon')).toBeInTheDocument()
    })

    it('renders with "Completed 1 item" text when requirementCount is provided and is completed', () => {
      const {getByText, getByTestId} = setUp(
        buildDefaultProps({requirementCount: 1, completed: true}),
      )
      expect(getByText('Completed 1 item')).toBeInTheDocument()
      expect(getByTestId('module-header-completion-requirement-icon')).toBeInTheDocument()
    })
  })

  describe('pill color', () => {
    it('renders with success pill color when completed', () => {
      expect(getPillColor(true)).toBe('success')
    })

    it('renders with info pill color when not completed', () => {
      expect(getPillColor(false)).toBe('info')
    })
  })
})
