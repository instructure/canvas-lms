/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import HeaderFilterView from '../HeaderFilterView'

describe('Test redraw function', () => {
  let grid
  let redrawFn
  let averageFn

  const defaultProps = (props = {}) => ({
    grid,
    averageFn,
    redrawFn,
    ...props,
  })

  beforeEach(() => {
    grid = {}
    redrawFn = jest.fn()
    averageFn = "mean"
  })

  it('calls redrawFn with \"median\" when averageFn is \"mean\"', () => {
    const {getByTestId} = render(<HeaderFilterView {...defaultProps()} />)
    fireEvent.click(getByTestId('lmgb-course-calc-dropdown'))
    fireEvent.click(getByTestId('course-median-calc-option'))
    expect(redrawFn).toHaveBeenCalledWith({}, "median")
  })

  it('calls redrawFn with \"mean\" when averageFn is \"median\"', () => {
    const {getByTestId} = render(<HeaderFilterView {...defaultProps({averageFn: "median"})} />)
    fireEvent.click(getByTestId('lmgb-course-calc-dropdown'))
    fireEvent.click(getByTestId('course-average-calc-option'))
    expect(redrawFn).toHaveBeenCalledWith({}, "mean")
  })

  it('does not call redrawFn when selecting \"mean\" and calculation is already \"mean\"', () => {
    const {getByTestId} = render(<HeaderFilterView {...defaultProps()} />)
    fireEvent.click(getByTestId('lmgb-course-calc-dropdown'))
    fireEvent.click(getByTestId('course-average-calc-option'))
    expect(redrawFn).not.toHaveBeenCalled()
  })

  it('does not call redrawFn when selecting \"median\" and calculation is already \"median\"', () => {
    const {getByTestId} = render(<HeaderFilterView {...defaultProps({averageFn: "median"})} />)
    fireEvent.click(getByTestId('lmgb-course-calc-dropdown'))
    fireEvent.click(getByTestId('course-median-calc-option'))
    expect(redrawFn).not.toHaveBeenCalled()
  })
})
