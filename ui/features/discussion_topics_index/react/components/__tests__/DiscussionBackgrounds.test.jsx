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

import {render, screen} from '@testing-library/react'
import {
  pinnedDiscussionBackground,
  unpinnedDiscussionsBackground,
  closedDiscussionBackground,
} from '../DiscussionBackgrounds'

describe('DiscussionBackgrounds', () => {
  const defaultProps = {
    permissions: {
      create: true,
      manage_content: true,
      moderate: true,
    },
    courseID: 12,
    contextType: 'Course',
  }

  it('renders correct student view for the pinnedDiscussionBackground with manage_content true', () => {
    render(pinnedDiscussionBackground(defaultProps))
    expect(screen.getByText('You currently have no pinned discussions')).toBeInTheDocument()
    expect(screen.getByText('To pin a discussion to the top', {exact: false})).toBeInTheDocument()
  })

  it('renders correct student view for the pinnedDiscussionBackground with manage_content false', () => {
    const props = {
      ...defaultProps,
      permissions: {...defaultProps.permissions, manage_content: false},
    }
    render(pinnedDiscussionBackground(props))
    expect(screen.getByText('You currently have no pinned discussions')).toBeInTheDocument()
    expect(
      screen.queryByText('To pin a discussion to the top', {exact: false})
    ).not.toBeInTheDocument()
  })

  it('renders correct student view for the unpinnedDiscussionsBackground decorative component with create true', () => {
    render(unpinnedDiscussionsBackground(defaultProps))
    expect(screen.getByText('There are no discussions to show in this section')).toBeInTheDocument()
    expect(screen.queryByRole('link')).toBeInTheDocument()
  })

  it('renders correct student view for the unpinnedDiscussionsBackground decorative component with create false', () => {
    const props = {
      ...defaultProps,
      permissions: {...defaultProps.permissions, create: false},
    }
    render(unpinnedDiscussionsBackground(props))
    expect(screen.getByText('There are no discussions to show in this section')).toBeInTheDocument()
    expect(screen.queryByRole('link')).not.toBeInTheDocument()
  })

  it('renders correct student view for the closedDiscussionBackground decorative component with manage_content true', () => {
    render(closedDiscussionBackground(defaultProps))
    expect(
      screen.getByText('You currently have no discussions with closed comments')
    ).toBeInTheDocument()
    expect(
      screen.getByText('To close comments on a discussion', {exact: false})
    ).toBeInTheDocument()
  })

  it('renders correct student view for the closedDiscussionBackground decorative component with manage_content false', () => {
    const props = {
      ...defaultProps,
      permissions: {...defaultProps.permissions, manage_content: false},
    }

    render(closedDiscussionBackground(props))
    expect(
      screen.getByText('You currently have no discussions with closed comments')
    ).toBeInTheDocument()
    expect(
      screen.queryByText('To close comments on a discussion', {exact: false})
    ).not.toBeInTheDocument()
  })
})
