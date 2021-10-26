/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {Course} from '../../../../graphql/Course'
import {Enrollment} from '../../../../graphql/Enrollment'
import {fireEvent, render} from '@testing-library/react'
import {Group} from '../../../../graphql/Group'
import HeaderInputs from '../HeaderInputs'
import React from 'react'

describe('HeaderInputs', () => {
  const defaultProps = () => ({
    courses: {
      favoriteGroupsConnection: {
        nodes: [Group.mock()]
      },
      favoriteCoursesConnection: {
        nodes: [Course.mock()]
      },
      enrollments: [Enrollment.mock()]
    },
    onContextSelect: jest.fn(),
    onSendIndividualMessagesChange: jest.fn(),
    onSubjectChange: jest.fn(),
    onRemoveMediaComment: jest.fn()
  })

  describe('Media Comments', () => {
    it('does not render a media comment if one is not provided', () => {
      const container = render(<HeaderInputs {...defaultProps()} />)
      expect(container.queryByTestId('media-attachment')).toBeNull()
    })

    it('does render a media comment if one is provided', () => {
      const container = render(
        <HeaderInputs {...defaultProps()} mediaAttachmentTitle="I am Lord Lemon" />
      )
      expect(container.getByTestId('media-attachment')).toBeInTheDocument()
      expect(container.getByText('I am Lord Lemon')).toBeInTheDocument()
    })

    it('calls the onRemoveMediaComment callback when the remove media button is clicked', () => {
      const props = defaultProps()
      const container = render(
        <HeaderInputs {...props} mediaAttachmentTitle="No really I am Lord Lemon" />
      )
      const removeMediaButton = container.getByTestId('remove-media-attachment')
      fireEvent.click(removeMediaButton)
      expect(props.onRemoveMediaComment).toHaveBeenCalled()
    })
  })
})
