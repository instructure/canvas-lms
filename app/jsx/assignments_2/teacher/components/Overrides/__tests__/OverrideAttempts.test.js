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
import {render, fireEvent} from 'react-testing-library'
import {mockOverride} from '../../../test-utils'
import OverrideAttempts from '../OverrideAttempts'

describe('OverrideAttempts', () => {
  it('renders unlimited override attempts summary', () => {
    const override = mockOverride()

    const {getByText, getByTestId} = render(
      <OverrideAttempts override={override} variant="summary" />
    )
    expect(getByTestId('OverrideAttempts-Summary')).toBeInTheDocument()

    // the attempts
    expect(getByText('Unlimited Attempts')).toBeInTheDocument()
  })

  it('renders limited override attempts summary', () => {
    const override = mockOverride({allowedAttempts: 2})

    const {getByText, getByTestId} = render(
      <OverrideAttempts override={override} variant="summary" />
    )
    expect(getByTestId('OverrideAttempts-Summary')).toBeInTheDocument()

    // the attempts
    expect(getByText('2 Attempts')).toBeInTheDocument()
  })

  it('renders unlimited override attempts detail', () => {
    const override = mockOverride({})

    const {getByLabelText, getByTestId, queryByTestId} = render(
      <OverrideAttempts override={override} onChangeOverride={() => {}} variant="detail" readOnly />
    )
    expect(getByTestId('OverrideAttempts-Detail')).toBeInTheDocument()

    // the attempts
    expect(getByLabelText('Attempts Allowed').value).toBe('Unlimited')
    expect(queryByTestId('OverrideAttempts-Attempts')).toBeNull()

    // score to keep
    expect(getByLabelText('Score to keep').value).toBe('Most Recent')
  })

  it('renders limited override attempts detail', () => {
    const override = mockOverride({allowedAttempts: 2})
    const {getByLabelText, getByTestId} = render(
      <OverrideAttempts override={override} onChangeOverride={() => {}} variant="detail" readOnly />
    )
    expect(getByTestId('OverrideAttempts-Detail')).toBeInTheDocument()

    // the attempts
    expect(getByLabelText('Attempts Allowed').value).toBe('Limited')
    expect(getByLabelText('Attempts').value).toBe('2')

    expect(getByLabelText('Score to keep').value).toBe('Most Recent')
  })

  it('displays the Attempts count when switched from unlimited to limited', () => {
    const override = mockOverride({})

    const {container, getByTestId, queryByTestId} = render(
      <OverrideAttempts override={override} onChangeOverride={() => {}} variant="detail" readOnly />
    )
    expect(queryByTestId('OverrideAttempts-Attempts')).toBeNull()

    override.allowedAttempts = 1
    render(
      <OverrideAttempts
        override={override}
        onChangeOverride={() => {}}
        variant="detail"
        readOnly
      />,
      {container}
    )
    expect(getByTestId('OverrideAttempts-Attempts')).toBeInTheDocument()
  })

  it('increments the limit', () => {
    const override = mockOverride({allowedAttempts: 2})
    const onChange = jest.fn()

    const {getByLabelText} = render(
      <OverrideAttempts override={override} onChangeOverride={onChange} variant="detail" readOnly />
    )

    const numberInput = getByLabelText('Attempts')
    fireEvent.keyDown(numberInput, {key: 'ArrowUp', keyCode: 38})
    expect(onChange).toHaveBeenCalledWith('allowedAttempts', 3)
  })

  it('decrements the limit', () => {
    const override = mockOverride({allowedAttempts: 2})
    const onChange = jest.fn()

    const {getByLabelText} = render(
      <OverrideAttempts override={override} onChangeOverride={onChange} variant="detail" readOnly />
    )

    const numberInput = getByLabelText('Attempts')
    fireEvent.keyDown(numberInput, {key: 'ArrowDown', keyCode: 40})
    expect(onChange).toHaveBeenCalledWith('allowedAttempts', 1)
  })

  it('not to decrements the limit to 0', () => {
    const override = mockOverride({allowedAttempts: 1})
    const onChange = jest.fn()

    const {getByLabelText} = render(
      <OverrideAttempts override={override} onChangeOverride={onChange} variant="detail" readOnly />
    )

    const numberInput = getByLabelText('Attempts')
    fireEvent.keyDown(numberInput, {key: 'ArrowDown', keyCode: 40})
    expect(onChange).not.toHaveBeenCalled()
  })
})
