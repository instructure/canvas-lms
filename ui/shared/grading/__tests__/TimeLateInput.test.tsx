// @ts-nocheck
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
import {fireEvent, render} from '@testing-library/react'
import TimeLateInput from '../TimeLateInput'

describe('TimeLateInput', () => {
  let props

  const SECONDS_PER_MINUTE = 60
  const SECONDS_PER_HOUR = SECONDS_PER_MINUTE * 60
  const SECONDS_PER_DAY = SECONDS_PER_HOUR * 24

  const HOURS = /hours late/i
  const DAYS = /days late/i

  const renderComponent = () => render(<TimeLateInput {...props} />)

  const getTimeLateInput = name => {
    const {getByRole} = renderComponent()
    return getByRole('textbox', {name})
  }

  const simulateBlurWithValue = value => {
    const name = props.lateSubmissionInterval === 'hour' ? HOURS : DAYS
    const input = getTimeLateInput(name)
    fireEvent.blur(input, {target: {value}})
  }

  beforeEach(() => {
    props = {
      lateSubmissionInterval: 'day',
      locale: 'en',
      renderLabelBefore: false,
      secondsLate: 0,
      onSecondsLateUpdated: jest.fn(),
      width: '5rem',
    }
  })

  it('displays "Days" as the text next to the input when the late policy interval is "day"', () => {
    const {getByText} = renderComponent()
    const numberInputText = getByText('Days')
    expect(numberInputText).toBeInTheDocument()
  })

  it('displays "Day" as the text next to the input when set to be late 1 day', () => {
    props.secondsLate = 60 * 60 * 24
    const {getByText} = renderComponent()
    const numberInputText = getByText('Day')
    expect(numberInputText).toBeInTheDocument()
  })

  it('displays "Hours as the text next to the input when the late policy interval is "hour"', () => {
    props.lateSubmissionInterval = 'hour'
    const {getByText} = renderComponent()
    const numberInputText = getByText('Hours')
    expect(numberInputText).toBeInTheDocument()
  })

  it('displays "Hour" as the text next to the input when set to be late 1 hour', () => {
    props.secondsLate = 60 * 60
    props.lateSubmissionInterval = 'hour'
    const {getByText} = renderComponent()
    const numberInputText = getByText('Hour')
    expect(numberInputText).toBeInTheDocument()
  })

  it('has a label that reads "Days late" if the late policy interval is "day"', () => {
    const input = getTimeLateInput(DAYS)
    expect(input).toBeInTheDocument()
  })

  it('has a label that reads "Hours late" if the late policy interval is "hour"', () => {
    props.lateSubmissionInterval = 'hour'
    const input = getTimeLateInput(HOURS)
    expect(input).toBeInTheDocument()
  })

  it('converts the value unit to days if the late policy interval is "day"', () => {
    props.secondsLate = 2 * SECONDS_PER_DAY
    const input = getTimeLateInput(DAYS) as HTMLInputElement
    expect(input.value).toEqual('2')
  })

  it('converts the value unit to hours if the late policy interval is "hour"', () => {
    props.secondsLate = 2 * SECONDS_PER_DAY
    props.lateSubmissionInterval = 'hour'
    const input = getTimeLateInput(HOURS) as HTMLInputElement
    expect(input.value).toEqual('48')
  })

  it('rounds the input value to two digits after the decimal point', () => {
    props.secondsLate = 2 * SECONDS_PER_DAY + 4 * SECONDS_PER_MINUTE
    props.lateSubmissionInterval = 'hour'
    const input = getTimeLateInput(HOURS) as HTMLInputElement
    expect(input.value).toEqual('48.07')
  })

  it('does not render in the DOM when visible prop is "false"', () => {
    props.visible = false
    const {queryByRole} = renderComponent()
    const input = queryByRole('textbox', {name: DAYS})
    expect(input).not.toBeInTheDocument()
  })

  describe('on blur', () => {
    it('does not call onSecondsLateUpdated if the input value is an empty string', () => {
      simulateBlurWithValue('')
      expect(props.onSecondsLateUpdated).toHaveBeenCalledTimes(0)
    })

    it('does not call onSecondsLateUpdated if the input value cannot be parsed as a number', () => {
      simulateBlurWithValue('foo')
      expect(props.onSecondsLateUpdated).toHaveBeenCalledTimes(0)
    })

    it('does not call onSecondsLateUpdated if the input value matches the current value', () => {
      simulateBlurWithValue('0')
      expect(props.onSecondsLateUpdated).toHaveBeenCalledTimes(0)
    })

    it('does not call onSecondsLateUpdated if the parsed value (2 decimals) matches the current value', () => {
      simulateBlurWithValue('0.004')
      expect(props.onSecondsLateUpdated).toHaveBeenCalledTimes(0)
    })

    it('calls onSecondsLateUpdated if the parsed value differs from the current value', () => {
      simulateBlurWithValue('2')
      expect(props.onSecondsLateUpdated).toHaveBeenCalledTimes(1)
    })

    it('calls onSecondsLateUpdated with latePolicyStatus set to "late"', () => {
      simulateBlurWithValue('2')
      const argumentsFromLastCall = props.onSecondsLateUpdated.mock.calls[0][0]
      expect(argumentsFromLastCall.latePolicyStatus).toEqual('late')
    })

    it('calls onSecondsLateUpdated with the input correctly converted to seconds when interval is hour', () => {
      props.lateSubmissionInterval = 'hour'
      simulateBlurWithValue('2')
      const expectedSeconds = 2 * SECONDS_PER_HOUR
      const argumentsFromLastCall = props.onSecondsLateUpdated.mock.calls[0][0]
      expect(argumentsFromLastCall.secondsLateOverride).toEqual(expectedSeconds)
    })

    it('truncates the remainder if one exists', () => {
      simulateBlurWithValue('2.3737')
      const expectedSeconds = Math.trunc(2.3737 * SECONDS_PER_DAY)
      const argumentsFromLastCall = props.onSecondsLateUpdated.mock.calls[0][0]
      expect(argumentsFromLastCall.secondsLateOverride).toEqual(expectedSeconds)
    })
  })
})
