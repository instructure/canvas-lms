/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import EditableNumber from '../EditableNumber'

describe('EditableNumber', () => {
  it('renders the value in view mode', () => {
    const {getByText} = render(
      <EditableNumber
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        label="Pick a number"
        value="17"
      />
    )
    expect(getByText('17')).toBeInTheDocument()
    expect(getByText('Pick a number')).toBeInTheDocument()
  })

  it('renders the value in edit mode', () => {
    const {getByDisplayValue} = render(
      <EditableNumber
        mode="edit"
        onChange={() => {}}
        onChangeMode={() => {}}
        label="Pick a number"
        value="17"
      />
    )
    expect(getByDisplayValue('17')).toBeInTheDocument()
  })

  it('does not render edit button when readOnly', () => {
    const {queryByText} = render(
      <EditableNumber
        mode="view"
        onChange={() => {}}
        onChangeMode={() => {}}
        label="Pick a number"
        value="17"
        readOnly
      />
    )
    expect(queryByText('Pick a number')).toBeNull()
  })

  it('exits edit mode on <Enter>', () => {
    const onChangeMode = jest.fn()
    const {getByDisplayValue} = render(
      <EditableNumber
        mode="edit"
        onChange={() => {}}
        onChangeMode={onChangeMode}
        label="Pick a number"
        value="17"
      />
    )
    const input = getByDisplayValue('17')
    fireEvent.keyDown(input, {key: 'Enter', code: 13})
    expect(onChangeMode).toHaveBeenCalledWith('view')
  })

  it('reverts to the old value on Escape', () => {
    const onChange = jest.fn()
    const onInputChange = jest.fn()
    const {getByDisplayValue} = render(
      <EditableNumber
        mode="edit"
        onChange={onChange}
        onChangeMode={() => {}}
        onInputChange={onInputChange}
        label="Pick a number"
        value="17"
      />
    )

    const input = getByDisplayValue('17')
    fireEvent.input(input, {target: {value: '2'}})
    fireEvent.keyDown(input, {key: 'Escape', code: 27})
    expect(onInputChange).toHaveBeenCalledWith('2')
    expect(onChange).toHaveBeenCalledWith('17')
  })

  // I want to test that the input grows in width as the user
  // types, but the component isn't acutally rendered into a DOM
  // where it's given a size. The container and everything w/in
  // is is 0x0.
  // it('grows with the value', () => {
  //   const {getByDisplayValue} = render(
  //     <EditableNumber
  //       mode="edit"
  //       onChange={() => {}}
  //       onChangeMode={() => {}}
  //       label="Pick a number"
  //       value="17"
  //     />
  //   )
  //   let input = getByDisplayValue('17')
  //   const w0 = input.offsetWidth
  //   render(
  //     <EditableNumber
  //       mode="edit"
  //       onChange={() => {}}
  //       onChangeMode={() => {}}
  //       label="Pick a number"
  //       value="1777"
  //     />,
  //     {container}
  //   )
  //   input = getByDisplayValue('1777')
  //   const w1 = input.offsetWidth

  //   expect(w1 > w0).toBeTruthy()
  // })
})
