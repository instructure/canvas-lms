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

import {render} from '@testing-library/react'
import React from 'react'

import { CheckpointsSettings } from '../CheckpointsSettings'

import {GradedDiscussionDueDatesContext} from '../../../util/constants'

const setup = ({
  pointsPossibleReplyToTopic = 0,
  setPointsPossibleReplyToTopic = () => {},
  pointsPossibleReplyToEntry = 0,
  setPointsPossibleReplyToEntry = () => {},
  replyToEntryRequiredCount = 0,
  setReplyToEntryRequiredCount = () => {},
} = {}) => {
  return render(
    <GradedDiscussionDueDatesContext.Provider
      value={{
        pointsPossibleReplyToTopic,
        setPointsPossibleReplyToTopic,
        pointsPossibleReplyToEntry,
        setPointsPossibleReplyToEntry,
        replyToEntryRequiredCount,
        setReplyToEntryRequiredCount,
      }}
    >
      <CheckpointsSettings />
    </GradedDiscussionDueDatesContext.Provider>
  )
}

describe('CheckpointsSettings', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText('Checkpoint Settings')).toBeInTheDocument()
    expect(getByText('Points Possible: Reply to Topic')).toBeInTheDocument()
    expect(getByText('Points Possible: Additional Replies')).toBeInTheDocument()
  })

  describe('Points Possible', () => {
    it('displays the correct points possible passed from the useContext', () => {
      const {getByTestId} = setup({
        pointsPossibleReplyToEntry: 8,
        pointsPossibleReplyToTopic: 9,
      })
      expect(getByTestId('points-possible-input-reply-to-topic')).toHaveValue('9')
      expect(getByTestId('points-possible-input-reply-to-entry')).toHaveValue('8')
    })
    it('displays the correct total points', () => {
      const {getByText} = setup({
        pointsPossibleReplyToEntry: 8,
        pointsPossibleReplyToTopic: 9,
      })
      expect(getByText('Total Points Possible: 17')).toBeInTheDocument()
    })
  })
  describe('Additional Replies Required', () => {
    it('displays the correct additional replies required passed from the useContext', () => {
      const {getByTestId} = setup({
        replyToEntryRequiredCount: 5
      })
      expect(getByTestId('reply-to-entry-required-count')).toHaveValue('5')
    })
  })
})
