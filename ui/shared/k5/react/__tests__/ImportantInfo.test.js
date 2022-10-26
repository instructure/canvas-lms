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

import React from 'react'
import {render} from '@testing-library/react'
import ImportantInfo from '../ImportantInfo'

describe('ImportantInfo', () => {
  const getProps = (mainOverrides = {}, infoDetailsOverrides = {}) => ({
    isLoading: false,
    showTitle: true,
    infoDetails: {
      courseId: '10',
      courseName: 'Homeroom',
      canEdit: true,
      content: '<p>Hello class!</p>',
      ...infoDetailsOverrides,
    },
    ...mainOverrides,
  })

  it('shows a title with edit button if showTitle and canEdit', () => {
    const {getByText, getByRole} = render(<ImportantInfo {...getProps()} />)
    expect(getByText('Homeroom')).toBeInTheDocument()
    const button = getByRole('link', {name: 'Edit important info for Homeroom'})
    expect(button).toBeInTheDocument()
    expect(button.href).toContain('/courses/10/assignments/syllabus')
  })

  it('shows a title but no edit button if showTitle but not canEdit', () => {
    const {getByText, queryByRole} = render(<ImportantInfo {...getProps({}, {canEdit: false})} />)
    expect(getByText('Homeroom')).toBeInTheDocument()
    expect(queryByRole('link', {name: 'Edit important info for Homeroom'})).not.toBeInTheDocument()
  })

  it('does not show title or button if neither showTitle nor canEdit', () => {
    const {queryByText, queryByRole} = render(
      <ImportantInfo {...getProps({showTitle: false}, {canEdit: false})} />
    )
    expect(queryByText('Homeroom')).not.toBeInTheDocument()
    expect(queryByRole('link', {name: 'Edit important info for Homeroom'})).not.toBeInTheDocument()
  })

  it('displays the converted user content', () => {
    const {getByText} = render(<ImportantInfo {...getProps()} />)
    expect(getByText('Hello class!')).toBeInTheDocument()
  })
})
