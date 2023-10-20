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
import {SelfSignup} from '../SelfSignup'

function Wrapper({state, props}) {
  return (
    <GroupContext.Provider value={state}>
      <SelfSignup {...props} />
    </GroupContext.Provider>
  )
}

const defaultProps = {onChange: Function.prototype}
const both = [true, false]

describe('CreateOrEditSetModal::SelfSignup::', () => {
  describe('checkboxes', () => {
    both.forEach(checked => {
      const v = checked ? 'checked' : 'unchecked'
      it(`tracks ${v} Self Signup`, () => {
        const state = {selfSignup: checked, bySection: false}
        const {getByTestId} = render(<Wrapper state={state} props={defaultProps} />)
        expect(getByTestId('checkbox-allow-self-signup').checked).toBe(checked)
        expect(getByTestId('checkbox-same-section').disabled).toBe(!checked)
      })
    })

    both.forEach(checked => {
      const v = checked ? 'checked' : 'unchecked'
      it(`tracks ${v} Same Section`, () => {
        const state = {selfSignup: true, bySection: checked}
        const {getByTestId} = render(<Wrapper state={state} props={defaultProps} />)
        expect(getByTestId('checkbox-same-section').checked).toBe(checked)
      })
    })
  })

  describe('onChange', () => {
    const onChange = jest.fn()

    beforeEach(() => {
      onChange.mockReset()
    })

    it('fires handler for Self Signup click', () => {
      const state = {selfSignup: false, bySection: false}
      const props = {onChange}
      const {getByTestId} = render(<Wrapper state={state} props={props} />)
      fireEvent.click(getByTestId('checkbox-allow-self-signup'))
      expect(onChange).toHaveBeenCalledTimes(1)
      expect(onChange).toHaveBeenCalledWith({selfSignup: true, bySection: false})
    })

    it('fires handler for Same Section click', () => {
      const state = {selfSignup: true, bySection: false}
      const props = {onChange}
      const {getByTestId} = render(<Wrapper state={state} props={props} />)
      fireEvent.click(getByTestId('checkbox-same-section'))
      expect(onChange).toHaveBeenCalledTimes(1)
      expect(onChange).toHaveBeenCalledWith({selfSignup: true, bySection: true})
    })
  })
})
