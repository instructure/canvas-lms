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
import CoursePublishButton from '../CoursePublishButton'
import {render} from '@testing-library/react'

describe('CoursePublishButton', () => {
  const getProps = (props: Object) => {
    return {
      isPublished: false,
      courseId: '1',
      shouldRedirect: false,
      ...props,
    }
  }

  it('button text is "Unpublished" if the course is not published', () => {
    const {getByText} = render(<CoursePublishButton {...getProps({})} />)
    expect(getByText('Unpublished')).toBeInTheDocument()
  })

  it('button text is "Published" if the course is published', () => {
    const {getByText} = render(<CoursePublishButton {...getProps({isPublished: true})} />)
    expect(getByText('Published')).toBeInTheDocument()
  })

  it('opens menu and displays publish/unpublish buttons when button is clicked', () => {
    const {getByText} = render(<CoursePublishButton {...getProps({})} />)
    getByText('Unpublished').click()
    expect(getByText('Publish')).toBeInTheDocument()
    expect(getByText('Unpublish')).toBeInTheDocument()
  })

  it('unpublish option is disabled if course is unpublished', () => {
    const {getByText, getByLabelText} = render(<CoursePublishButton {...getProps({})} />)
    getByText('Unpublished').click()
    expect(getByLabelText('Unpublish').getAttribute('aria-disabled')).toBeTruthy()
    expect(getByText('Publish').getAttribute('aria-disabled')).toBeNull()
  })

  it('publish option is disabled if course is published', () => {
    const {getByText, getByLabelText} = render(
      <CoursePublishButton {...getProps({isPublished: true})} />
    )
    getByText('Published').click()
    expect(getByLabelText('Publish').getAttribute('aria-disabled')).toBeTruthy()
    expect(getByText('Unpublish').getAttribute('aria-disabled')).toBeNull()
  })
})
