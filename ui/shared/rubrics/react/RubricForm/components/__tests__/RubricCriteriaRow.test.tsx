/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {waitFor} from '@testing-library/dom'
import {RubricCriteriaRow} from '../RubricCriteriaRow'

vi.mock('react-beautiful-dnd', () => ({
  Draggable: ({children}: any) =>
    children({dragHandleProps: {}, draggableProps: {}, innerRef: () => {}}, {}),
  DragDropContext: ({children}: any) => children,
  Droppable: ({children}: any) => children({droppableProps: {}, innerRef: () => {}}, {}),
}))

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

vi.mock('../../../RubricAssessment/queries/useGetRubricOutcome', () => ({
  useGetRubricOutcome: () => ({data: undefined}),
}))

const defaultCriterion = {
  id: 'crit1',
  description: 'Test Criterion',
  longDescription: '',
  points: 10,
  ratings: [
    {id: 'rat1', description: 'Full Marks', longDescription: '', points: 10, criterionId: 'crit1'},
    {id: 'rat2', description: 'No Marks', longDescription: '', points: 0, criterionId: 'crit1'},
  ],
  criterionUseRange: false,
}

const defaultProps = {
  criterion: defaultCriterion,
  freeFormCriterionComments: false,
  hidePoints: false,
  isCompact: false,
  isCompactRatings: false,
  isCompactOutcome: false,
  rowIndex: 1,
  isAIRubricsAvailable: false,
  selectLearningOutcome: vi.fn(),
  onDeleteCriterion: vi.fn(),
  onDuplicateCriterion: vi.fn(),
  onEditCriterion: vi.fn(),
  handleMoveCriterion: vi.fn(),
  criterionIndex: 0,
  isFirstCriterion: false,
  isLastCriterion: false,
}

describe('RubricCriteriaRow', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('RegenerateCriteriaButton visibility', () => {
    it('shows the button when showRegenerateButtonFreeForm conditions are met and isCompactRatings is false', () => {
      const {getByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          freeFormCriterionComments={true}
          showCriteriaRegeneration={true}
          isCompactRatings={false}
          onRegenerateCriterion={vi.fn()}
        />,
      )
      expect(getByTestId('regenerate-criteria-button')).toBeInTheDocument()
    })

    it('hides the button when showRegenerateButtonFreeForm is true but isCompactRatings is true', () => {
      const {queryByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          freeFormCriterionComments={true}
          showCriteriaRegeneration={true}
          isCompactRatings={true}
          onRegenerateCriterion={vi.fn()}
        />,
      )
      expect(queryByTestId('regenerate-criteria-button')).not.toBeInTheDocument()
    })

    it('hides the button when showCriteriaRegeneration is false', () => {
      const {queryByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          freeFormCriterionComments={true}
          showCriteriaRegeneration={false}
          isCompactRatings={false}
          onRegenerateCriterion={vi.fn()}
        />,
      )
      expect(queryByTestId('regenerate-criteria-button')).not.toBeInTheDocument()
    })

    it('hides the button when onRegenerateCriterion is not provided', () => {
      const {queryByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          freeFormCriterionComments={true}
          showCriteriaRegeneration={true}
          isCompactRatings={false}
        />,
      )
      expect(queryByTestId('regenerate-criteria-button')).not.toBeInTheDocument()
    })
  })

  describe('CriterionRowPopover onRegenerate', () => {
    it('passes onRegenerate to the popover when isCompactRatings and showRegenerateButtonRatings are true', async () => {
      const user = userEvent.setup()
      const {getByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          isCompact={true}
          isCompactRatings={true}
          showCriteriaRegeneration={true}
          onRegenerateCriterion={vi.fn()}
        />,
      )

      await user.click(getByTestId('criterion-options-popover'))

      await waitFor(() => {
        expect(getByTestId('regenerate-criterion-menu-item')).toBeInTheDocument()
      })
    })

    it('passes onRegenerate to the popover when isCompactRatings and showRegenerateButtonFreeForm are true', async () => {
      const user = userEvent.setup()
      const {getByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          isCompact={true}
          isCompactRatings={true}
          freeFormCriterionComments={true}
          showCriteriaRegeneration={true}
          onRegenerateCriterion={vi.fn()}
        />,
      )

      await user.click(getByTestId('criterion-options-popover'))

      await waitFor(() => {
        expect(getByTestId('regenerate-criterion-menu-item')).toBeInTheDocument()
      })
    })

    it('does not pass onRegenerate to the popover when isCompactRatings is false', async () => {
      const user = userEvent.setup()
      const {getByTestId, queryByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          isCompact={true}
          isCompactRatings={false}
          showCriteriaRegeneration={true}
          onRegenerateCriterion={vi.fn()}
        />,
      )

      await user.click(getByTestId('criterion-options-popover'))

      await waitFor(() => {
        expect(getByTestId('move-up-criterion-menu-item')).toBeInTheDocument()
      })

      expect(queryByTestId('regenerate-criterion-menu-item')).not.toBeInTheDocument()
    })

    it('does not pass onRegenerate to the popover when neither showRegenerateButtonFreeForm nor showRegenerateButtonRatings are true', async () => {
      const user = userEvent.setup()
      const {getByTestId, queryByTestId} = render(
        <RubricCriteriaRow
          {...defaultProps}
          isCompact={true}
          isCompactRatings={true}
          showCriteriaRegeneration={false}
          onRegenerateCriterion={vi.fn()}
        />,
      )

      await user.click(getByTestId('criterion-options-popover'))

      await waitFor(() => {
        expect(getByTestId('move-up-criterion-menu-item')).toBeInTheDocument()
      })

      expect(queryByTestId('regenerate-criterion-menu-item')).not.toBeInTheDocument()
    })
  })
})
