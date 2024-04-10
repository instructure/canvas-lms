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
import {render} from '@testing-library/react'
import AnnouncementEmptyState from '../AnnouncementEmptyState'


const renderComponent = (props = {}) => {
  const defaultProps = {
    canCreate: true,
  }
  return render(<AnnouncementEmptyState {...defaultProps} {...props} />)
}

test('renders the AnnouncementsEmptyState component', () => {
  const tree = renderComponent()
  expect(tree.getByText('No Announcements')).toBeInTheDocument()
})

test('renders the AnnouncementsEmptyState component when teacher', () => {
  const tree = renderComponent()
  expect(tree.getByText('Create announcements above')).toBeInTheDocument()
})

test('renders the AnnouncementsEmptyState component when student', () => {
  const tree = renderComponent({canCreate: false})
  expect(tree.getByText('Check back later')).toBeInTheDocument()
})
