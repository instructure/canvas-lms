/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import SubmissionTrayRadioInput from '../SubmissionTrayRadioInput'

type Props = {
  checked: boolean
  color?: string
  disabled: boolean
  latePolicy: {
    lateSubmissionInterval: 'day' | 'hour'
  }
  locale: string
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void
  submission: {
    id: string
    secondsLate: number
  }
  text: string
  updateSubmission: (submission: {secondsLateOverride: number}) => void
  value: string
}

const defaultProps: Props = {
  checked: false,
  color: '#FEF7E5',
  disabled: false,
  latePolicy: {lateSubmissionInterval: 'day'},
  locale: 'en',
  onChange: () => {},
  submission: {
    id: '1',
    secondsLate: 0,
  },
  text: 'Missing',
  updateSubmission: () => {},
  value: 'missing',
}

describe('SubmissionTrayRadioInput', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderComponent = (customProps: Partial<Props> = {}) => {
    const props = {...defaultProps, ...customProps}
    return render(<SubmissionTrayRadioInput {...props} />)
  }

  describe('radio input', () => {
    it('renders with the expected name attribute', () => {
      const {getByRole} = renderComponent()
      expect(getByRole('radio')).toHaveAttribute('name', 'SubmissionTrayRadioInput')
    })

    it('applies the specified background color', () => {
      const {container} = renderComponent({color: 'green'})
      const radioContainer = container.querySelector('.SubmissionTray__RadioInput')
      expect(radioContainer).toHaveStyle({backgroundColor: 'rgb(0, 128, 0)'})
    })

    it('uses transparent background when no color specified', () => {
      const {container} = renderComponent({color: undefined})
      const radioContainer = container.querySelector('.SubmissionTray__RadioInput')
      expect(radioContainer).toHaveStyle({backgroundColor: 'rgba(0, 0, 0, 0)'})
    })

    it('is enabled by default', () => {
      const {getByRole} = renderComponent()
      expect(getByRole('radio')).not.toBeDisabled()
    })

    it('can be disabled', () => {
      const {getByRole} = renderComponent({disabled: true})
      expect(getByRole('radio')).toBeDisabled()
    })

    it('can be checked', () => {
      const {getByRole} = renderComponent({checked: true})
      expect(getByRole('radio')).toBeChecked()
    })

    it('is unchecked by default', () => {
      const {getByRole} = renderComponent()
      expect(getByRole('radio')).not.toBeChecked()
    })

    it('calls onChange when clicked', async () => {
      const onChange = jest.fn()
      const {getByRole} = renderComponent({onChange})
      const user = userEvent.setup()
      await user.click(getByRole('radio'))
      expect(onChange).toHaveBeenCalledTimes(1)
    })
  })

  describe('NumberInput', () => {
    it('is not rendered by default', () => {
      const {container} = renderComponent()
      expect(
        container.querySelector('.NumberInput__Container input[type="text"]'),
      ).not.toBeInTheDocument()
    })

    it('is rendered when value is "late" and checked', () => {
      const {container} = renderComponent({value: 'late', checked: true})
      expect(
        container.querySelector('.NumberInput__Container input[type="text"]'),
      ).toBeInTheDocument()
    })

    it('is not rendered when value is "late" but unchecked', () => {
      const {container} = renderComponent({value: 'late', checked: false})
      expect(
        container.querySelector('.NumberInput__Container input[type="text"]'),
      ).not.toBeInTheDocument()
    })

    it('is enabled by default when rendered', () => {
      const {container} = renderComponent({value: 'late', checked: true})
      const input = container.querySelector('.NumberInput__Container input[type="text"]')
      expect(input).not.toBeDisabled()
    })

    it('can be disabled', () => {
      const {container} = renderComponent({value: 'late', checked: true, disabled: true})
      const input = container.querySelector('.NumberInput__Container input[type="text"]')
      expect(input).toBeDisabled()
    })

    it('appears when radio value changes to "late" and becomes checked', () => {
      const {container, rerender} = render(
        <SubmissionTrayRadioInput {...defaultProps} value="late" checked={false} />,
      )
      rerender(<SubmissionTrayRadioInput {...defaultProps} value="late" checked={true} />)
      expect(
        container.querySelector('.NumberInput__Container input[type="text"]'),
      ).toBeInTheDocument()
    })
  })
})
