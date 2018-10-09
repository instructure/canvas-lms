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
import { shallow } from 'enzyme'
import Points from '../Points'

describe('The Points component', () => {
  const component = (props) => shallow(<Points {...props} />)
  const id = { criterion_id: '_7506' }

  const validPoints = (text) => ({ text, valid: true, value: parseFloat(text) })

  it('renders the root component as expected', () => {
    expect(component({
      assessment: { ...id, points: validPoints('1') },
      pointsPossible: 2
    })).toMatchSnapshot()
  })

  it('renders the component when assessing with the expected layout', () => {
    expect(component({
      assessment: { ...id, points: validPoints('1') },
      assessing: true,
      pointsPossible: 2
    })).toMatchSnapshot()
  })

  it('renders the right text for fractional points', () => {
    expect(component({
      assessment: { ...id, points: validPoints('1.1') },
      pointsPossible: 2
    }).find('div').text()).toEqual('1.1 / 2 pts')
  })

  it('renders the provided value on page load with no point text', () => {
    expect(component({
      assessment: { ...id, points: { text: null, valid: true, value: 1.255 } },
      pointsPossible: 2
    }).find('div').text()).toEqual('1.26 / 2 pts')
  })

  it('renders no errors with point text verbatim when valid', () => {
    expect(component({
      assessing: true,
      assessment: { ...id, points: {text: '', valid: true, value: undefined } },
      pointsPossible: 2
    }).find('TextInput').prop('messages')).toHaveLength(0)
  })

  it('renders points possible with no assessment', () => {
    expect(component({
      assessing: false,
      assessment: null,
      pointsPossible: 2
    }).find('div').text()).toEqual('2 pts')
  })

  const withPoints = (points) => component({
    allowExtraCredit: false,
    assessing: true,
    assessment: {
      ...id,
      points
    },
    pointsPossible: 5
  })

  it('renders an error when valid is false', () => {
    const el = withPoints({ text: 'stringy', valid: false, value: null })
    expect(el.find('TextInput').prop('messages')).toHaveLength(1)
  })

  it('renders an error when extra credit cannot be given', () => {
    const el = withPoints({ text: '30', valid: true, value: 30 })
    expect(el.find('TextInput').prop('messages')).toHaveLength(1)
  })

  it('renders no error when valid is true', () => {
    const expectNoErrorsWith = (text, value) =>
      expect(withPoints({ text, valid: true, value })
        .find('TextInput').prop('messages')).toHaveLength(0)

    expectNoErrorsWith('')
    expectNoErrorsWith(null)
    expectNoErrorsWith(undefined)
    expectNoErrorsWith('0', 0)
    expectNoErrorsWith('2.2', 2.2)
  })
})
