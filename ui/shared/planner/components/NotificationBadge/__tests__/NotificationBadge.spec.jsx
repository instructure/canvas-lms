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

import React from 'react'
import {render} from '@testing-library/react'
import {NotificationBadge, NewActivityIndicator} from '../index'

it('renders an indicator', () => {
  const {container} = render(
    <NotificationBadge>
      <NewActivityIndicator title="blah" itemIds={['first', 'second']} />
    </NotificationBadge>,
  )
  expect(container.querySelectorAll('style')).toHaveLength(1)
  const contentDiv = container.querySelector('.NotificationBadge-styles__activityIndicator')
  expect(contentDiv).toBeInTheDocument()
  expect(contentDiv.children).toHaveLength(1)
})

it('renders an empty div when no children', () => {
  const {container} = render(<NotificationBadge>{null}</NotificationBadge>)
  expect(container.querySelectorAll('style')).toHaveLength(1)
  const contentDiv = container.querySelector('.NotificationBadge-styles__activityIndicator')
  expect(contentDiv).toBeInTheDocument()
  expect(contentDiv.children).toHaveLength(0)
})
