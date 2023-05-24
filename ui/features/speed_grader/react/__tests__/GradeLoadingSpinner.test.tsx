// @ts-nocheck
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

import GradeLoadingSpinner from '../GradeLoadingSpinner'
import {act, render} from '@testing-library/react'
import React from 'react'
import store from '../../stores/index'

describe('GradeLoadingSpinner', () => {
  let props
  beforeEach(() => {
    props = {onLoadingChange: jest.fn()}
  })

  afterEach(() => {
    store.setState({currentStudentId: '', gradesLoading: {}})
  })

  it('renders a spinner when grades are loading for the current student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: true, 5: true}})
    const {getByText} = render(<GradeLoadingSpinner {...props} />)
    expect(getByText('Grade Loading')).toBeInTheDocument()
  })

  it('does not render a spinner when grades are not loading for the current student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: false, 5: true}})
    const {queryByText} = render(<GradeLoadingSpinner {...props} />)
    expect(queryByText('Grade Loading')).not.toBeInTheDocument()
  })

  it('does not render a spinner when loading state does not have an entry for the student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {}})
    const {queryByText} = render(<GradeLoadingSpinner {...props} />)
    expect(queryByText('Grade Loading')).not.toBeInTheDocument()
  })

  it('calls the onLoadingChange prop when grades start loading for a student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: false, 5: true}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({gradesLoading: {4: true, 5: true}}))
    expect(props.onLoadingChange).toHaveBeenCalledTimes(1)
    expect(props.onLoadingChange).toHaveBeenCalledWith(true)
  })

  it('calls the onLoadingChange prop when grades are done loading for a student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: true, 5: true}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({gradesLoading: {4: false, 5: true}}))
    expect(props.onLoadingChange).toHaveBeenCalledTimes(1)
    expect(props.onLoadingChange).toHaveBeenCalledWith(false)
  })

  it('calls the onLoadingChange prop when changing from a student with grades loaded to a student with loading grades', () => {
    store.setState({currentStudentId: '5', gradesLoading: {4: true, 5: false}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({currentStudentId: '4'}))
    expect(props.onLoadingChange).toHaveBeenCalledTimes(1)
    expect(props.onLoadingChange).toHaveBeenCalledWith(true)
  })

  it('calls the onLoadingChange prop when changing from a student with loading grades to a student with grades loaded', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: true, 5: false}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({currentStudentId: '5'}))
    expect(props.onLoadingChange).toHaveBeenCalledTimes(1)
    expect(props.onLoadingChange).toHaveBeenCalledWith(false)
  })

  it('does not call the onLoadingChange prop when loading state updates without changes for the student', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: false, 5: true}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({gradesLoading: {4: false, 5: true}}))
    expect(props.onLoadingChange).not.toHaveBeenCalled()
  })

  it('does not call the onLoadingChange prop when updating from one student with loading grades to another', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: true, 5: true}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({currentStudentId: '5'}))
    expect(props.onLoadingChange).not.toHaveBeenCalled()
  })

  it('does not call the onLoadingChange prop when updating from one student with loaded grades to another', () => {
    store.setState({currentStudentId: '4', gradesLoading: {4: false, 5: false}})
    render(<GradeLoadingSpinner {...props} />)
    props.onLoadingChange.mockClear()
    act(() => store.setState({currentStudentId: '5'}))
    expect(props.onLoadingChange).not.toHaveBeenCalled()
  })
})
