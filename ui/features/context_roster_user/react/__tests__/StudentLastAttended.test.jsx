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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen} from '@testing-library/react'
import StudentLastAttended from '../StudentLastAttended'

const defaultProps = (props = {}) => ({
  defaultDate: '2018-03-04T07:00:00.000Z',
  courseID: '1',
  studentID: '1',
  ...props,
})

const renderStudentLastAttended = (props = {}) => {
  const ref = React.createRef()
  const wrapper = render(<StudentLastAttended {...defaultProps(props)} {...props} ref={ref} />)

  return {ref, ...wrapper}
}

describe('StudentLastAttended', () => {
  it('renders the StudentLastAttended component', () => {
    renderStudentLastAttended()

    expect(screen.getByText('Last day attended')).toBeInTheDocument()
  })

  it('renders loading component when loading', () => {
    const {ref} = renderStudentLastAttended()

    ref.current.setState({loading: true})

    expect(screen.getByText('Loading last attended date')).toBeInTheDocument()
  })

  it('onDateSubmit posts date to the endpoint if it differs', () => {
    const {ref} = renderStudentLastAttended()
    const newDate = new Date('2018-03-05T07:00:00.000Z')

    ref.current.state.selectedDate = new Date('2018-03-04T07:00:00.000Z')
    jest.spyOn(ref.current, 'postDateToBackend')

    ref.current.onDateSubmit(newDate)

    expect(ref.current.postDateToBackend).toHaveBeenCalledWith(newDate.toISOString())
  })
})
