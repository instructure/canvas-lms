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
import OverviewPage from '../OverviewPage'

describe('Overview Content', () => {
  const getProps = (overrides = {}) => ({
    content: '<h1>About this course <p>this is the course overview</p></h1>',
    url: '/courses/12/pages/thehomepage/edit',
    canEdit: true,
    showImmersiveReader: true,
    ...overrides,
  })

  it('renders overview content', () => {
    const {queryByText} = render(<OverviewPage {...getProps()} />)
    expect(queryByText('About this course')).toBeInTheDocument()
  })

  describe('edit button', () => {
    it('renders with correct link if canEdit is true', () => {
      const {getByRole} = render(<OverviewPage {...getProps()} />)
      const button = getByRole('link', {name: 'Edit home page'})
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/12/pages/thehomepage/edit')
    })

    it('does not render when canEdit is false', () => {
      const {queryByRole} = render(<OverviewPage {...getProps({canEdit: false})} />)
      expect(queryByRole('link', {name: 'Edit home page'})).not.toBeInTheDocument()
    })
  })

  describe('immersive reader button', () => {
    it('renders when showImmersiveReader is true', () => {
      const {getByRole} = render(<OverviewPage {...getProps()} />)
      expect(getByRole('button', {name: 'Immersive Reader'})).toBeInTheDocument()
    })

    it('does not render when showImmersiveReader is false', () => {
      const {queryByText} = render(<OverviewPage {...getProps({showImmersiveReader: false})} />)
      expect(queryByText('Immersive Reader')).not.toBeInTheDocument()
    })
  })
})
