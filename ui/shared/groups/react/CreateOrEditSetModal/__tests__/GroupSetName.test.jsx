/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {GroupContext} from '../context'
import {GroupSetName} from '../GroupSetName'

function Wrapper({state, props}) {
  return (
    <GroupContext.Provider value={state}>
      <GroupSetName {...props} />
    </GroupContext.Provider>
  )
}

const defaultProps = {onChange: Function.prototype, errormsg: undefined}
const state = {name: 'Satanaa!'}

describe('CreateOrEditSetModal::GroupSetName::', () => {
  it('sets the ref', () => {
    const elementRef = jest.fn()
    render(<Wrapper state={state} props={{...defaultProps, elementRef}} />)
    expect(elementRef.mock.calls[0][0] instanceof HTMLSpanElement).toBe(true)
  })

  it('displays the name from the context', () => {
    const {container} = render(<Wrapper state={state} props={defaultProps} />)
    const input = container.getElementsByTagName('input')[0]
    expect(input.getAttribute('value')).toBe('Satanaa!')
  })

  it('displays an error message if present', () => {
    const errormsg = 'oh no an error'
    const {getByText} = render(<Wrapper state={state} props={{...defaultProps, errormsg}} />)
    expect(getByText(errormsg)).toBeInTheDocument()
  })

  it('calls the callback if the input is changed', () => {
    const onChange = jest.fn()
    const {container} = render(<Wrapper state={state} props={{...defaultProps, onChange}} />)
    const input = container.getElementsByTagName('input')[0]
    fireEvent.input(input, {target: {value: 'Jumalauta!'}})
    expect(onChange).toHaveBeenCalledWith('Jumalauta!')
  })
})
