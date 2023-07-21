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
import {render, fireEvent} from '@testing-library/react'
import ModulePositionPicker from '../ModulePositionPicker'
import {useCourseModuleItemApi} from '../../effects/useModuleCourseSearchApi'

jest.mock('../../effects/useModuleCourseSearchApi')

describe('ModulePositionPicker', () => {
  it("shows 'loading additional items' when it's still loading data", () => {
    useCourseModuleItemApi.mockImplementationOnce(({success, loading}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
      loading(true)
    })
    const {getByText, getByTestId} = render(<ModulePositionPicker courseId="1" moduleId="1" />)
    fireEvent.change(getByTestId('select-position'), {target: {value: 'before'}})
    expect(getByText('Loading additional items...')).toBeInTheDocument()
  })

  it('should not show the module items unless a relative position is chosen', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const {getByText, getByTestId, queryByText} = render(
      <ModulePositionPicker courseId="1" moduleId="1" />
    )
    expect(getByText(/At the Bottom/i)).toBeInTheDocument()
    fireEvent.change(getByTestId('select-position'), {target: {value: 'last'}})
    expect(queryByText('abc')).not.toBeInTheDocument()
    expect(queryByText('cde')).not.toBeInTheDocument()
  })

  it('should show the module items when a relative position is chosen', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const {getByText, getByTestId} = render(<ModulePositionPicker courseId="1" moduleId="1" />)
    expect(getByText(/At the Top/i)).toBeInTheDocument()
    fireEvent.change(getByTestId('select-position'), {target: {value: 'after'}})
    expect(getByText('abc')).toBeInTheDocument()
    expect(getByText('cde')).toBeInTheDocument()
  })

  it('should call setModuleItemPosition with 1 on load', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const positionSetter = jest.fn()
    render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    expect(positionSetter).toHaveBeenCalledWith(1)
  })

  it('should call setModuleItemPosition with 1 when "at the top" is chosen', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'first'}})
    expect(positionSetter).toHaveBeenCalledTimes(2)
    expect(positionSetter).toHaveBeenLastCalledWith(1)
  })

  it('should call setModuleItemPosition with null when "at the bottom" is chosen', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'last'}})
    expect(positionSetter).toHaveBeenCalledTimes(2)
    expect(positionSetter).toHaveBeenLastCalledWith(null)
  })

  it('should call setModuleItemPosition with 1 when "before" is chosen with the default module item', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'before'}})
    expect(positionSetter).toHaveBeenCalledTimes(2)
    expect(positionSetter).toHaveBeenLastCalledWith(1)
  })

  it('should call setModuleItemPosition with 2 when "after" is chosen with the default module item', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '5'},
        {id: 'cde', title: 'cde', position: '6'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'after'}})
    expect(positionSetter).toHaveBeenCalledTimes(2)
    expect(positionSetter).toHaveBeenLastCalledWith(2)
  })

  it('should call setModuleItemPosition with the 1-based index of the module item when "before" is chosen with a non-default module item', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '5'},
        {id: 'cde', title: 'cde', position: '6'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'before'}})
    fireEvent.change(getByTestId('select-sibling'), {target: {value: '0'}})
    expect(positionSetter).toHaveBeenCalledTimes(3)
    expect(positionSetter).toHaveBeenLastCalledWith(1)
  })

  it('should call setModuleItemPosition with the 1-based index of the module item when "after" is chosen with a non-default module item', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '5'},
        {id: 'cde', title: 'cde', position: '6'},
      ])
    })
    const positionSetter = jest.fn()
    const {getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'after'}})
    fireEvent.change(getByTestId('select-sibling'), {target: {value: '1'}})
    expect(positionSetter).toHaveBeenCalledTimes(3)
    expect(positionSetter).toHaveBeenLastCalledWith(3)
  })

  it('should reset the module items and send a new position to setModuleItemPosition if a new module is chosen', () => {
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', title: 'abc', position: '5'},
        {id: 'cde', title: 'cde', position: '6'},
      ])
    })
    const positionSetter = jest.fn()
    const {rerender, getByTestId} = render(
      <ModulePositionPicker courseId="1" moduleId="1" setModuleItemPosition={positionSetter} />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'after'}})
    fireEvent.change(getByTestId('select-sibling'), {target: {value: '1'}})
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'fgh', title: 'fgh', position: '7'},
        {id: 'ijk', title: 'ijk', position: '8'},
      ])
    })
    rerender(
      <ModulePositionPicker courseId="1" moduleId="2" setModuleItemPosition={positionSetter} />
    )
    expect(positionSetter).toHaveBeenCalledTimes(4)
    expect(positionSetter).toHaveBeenLastCalledWith(2)
  })
})
