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

import React, {useState} from 'react'
import DateTimeInput from './DateTimeInput'

export default {
  title: 'Examples/Shared/Date and Time Helpers/DateTimeInput',
  component: DateTimeInput,
}

const locale = 'en-US'
const timezone = 'America/New_York'
const sampleDateTime = '2021-06-01T12:00:00Z'
const divStyles = {
  width: '240px',
  border: '1px solid blue',
  margin: '12px',
  padding: '6px',
}

const Wrapper = props => {
  const [value, setValue] = useState(props.value)

  function onChange(newValue) {
    setValue(newValue)
    props.onChange(newValue)
  }

  return (
    <div style={divStyles}>
      <DateTimeInput {...props} value={value} onChange={onChange} />
    </div>
  )
}

const Template = args => (
  <Wrapper {...args}>
    <DateTimeInput {...args} />
  </Wrapper>
)

export const Selector = Template.bind({})
Selector.args = {
  dateLabel: 'Date',
  timeLabel: 'Time',
  locale,
  timezone,
  onChange: Function.prototype,
  value: sampleDateTime,
  description: 'Pick a Date and Time',
}
