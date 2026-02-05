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

import {render, fireEvent} from '@testing-library/react'
import {DisplayRubricModal} from '../DisplayRubricModal'
import type {AssignmentRubric} from '@canvas/rubrics/react/RubricAssignment/queries'
import type {RubricAssociation} from '@canvas/rubrics/react/types/rubric'
import {queryClient} from '@canvas/query'
import * as RubricFormQueries from '@canvas/rubrics/react/RubricForm/queries/RubricFormQueries'
import fakeENV from '@canvas/test-utils/fakeENV'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/rubrics/react/RubricForm/queries/RubricFormQueries', async importOriginal => {
  const actual =
    await importOriginal<
      typeof import('@canvas/rubrics/react/RubricForm/queries/RubricFormQueries')
    >()
  return {
    ...actual,
    saveRubric: vi.fn(),
  }
})

vi.mock('@canvas/rubrics/react/RubricAssignment/queries', async importOriginal => {
  const actual =
    await importOriginal<typeof import('@canvas/rubrics/react/RubricAssignment/queries')>()
  return {
    ...actual,
    removeRubricFromAssignment: vi.fn(),
    addRubricToAssignment: vi.fn(),
    getGradingRubricContexts: vi.fn().mockResolvedValue([]),
    getGradingRubricsForContext: vi.fn().mockResolvedValue([]),
    getRubricSelfAssessmentSettings: vi.fn().mockResolvedValue({
      canUpdateRubricSelfAssessment: true,
      rubricSelfAssessmentEnabled: true,
    }),
    setRubricSelfAssessment: vi.fn().mockResolvedValue({}),
  }
})

const MOCK_RUBRIC: AssignmentRubric = {
  id: '1',
  title: 'Test Rubric',
  criteriaCount: 2,
  pointsPossible: 100,
  buttonDisplay: 'numeric',
  ratingOrder: 'descending',
  freeFormCriterionComments: false,
  criteria: [
    {
      id: '1',
      description: 'Criterion 1',
      points: 50,
      criterionUseRange: false,
      ratings: [
        {
          id: '1',
          description: 'Excellent',
          points: 50,
          longDescription: 'Excellent work',
        },
      ],
    },
  ],
  can_update: true,
}

const MOCK_RUBRIC_ASSOCIATION: RubricAssociation = {
  id: '1',
  hidePoints: false,
  hideScoreTotal: false,
  useForGrading: true,
  hideOutcomeResults: false,
  associationType: 'Assignment',
  associationId: '1',
}

describe('DisplayRubricModal', () => {
  const defaultProps = {
    aiRubricsEnabled: false,
    assignmentId: '1',
    assignmentPointsPossible: 100,
    canManageRubrics: true,
    courseId: '1',
    currentUserId: '1',
    isOpen: true,
    rubricSelfAssessmentFFEnabled: true,
    onClose: vi.fn(),
  }

  beforeEach(() => {
    fakeENV.setup()
    vi.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
      Promise.resolve({
        rubric: MOCK_RUBRIC,
        rubricAssociation: MOCK_RUBRIC_ASSOCIATION,
      }),
    )

    const rubricSelfAssessmentSettings = {
      canUpdateRubricSelfAssessment: true,
      rubricSelfAssessmentEnabled: true,
    }

    queryClient.setQueryData(
      ['assignment-self-assessment-settings', '1', MOCK_RUBRIC.id],
      rubricSelfAssessmentSettings,
    )

    queryClient.setDefaultOptions({
      queries: {
        retry: false,
      },
    })
  })

  afterEach(() => {
    destroyFlashAlertContainer()
    fakeENV.teardown()
    vi.clearAllMocks()
    queryClient.clear()
  })

  describe('modal rendering', () => {
    it('renders the modal when isOpen is true', () => {
      const {getByTestId, getByText} = render(<DisplayRubricModal {...defaultProps} />)

      const modal = getByTestId('assignment-rubric-modal')
      expect(modal).toBeInTheDocument()
      expect(getByText('Assignment Rubric Details')).toBeInTheDocument()
    })

    it('does not render the modal when isOpen is false', () => {
      const {queryByTestId} = render(<DisplayRubricModal {...defaultProps} isOpen={false} />)

      expect(queryByTestId('assignment-rubric-modal')).not.toBeInTheDocument()
    })

    it('renders the close button', () => {
      const {getByText} = render(<DisplayRubricModal {...defaultProps} />)

      const closeButton = getByText('Close')
      expect(closeButton).toBeInTheDocument()
    })

    it('renders the modal header with correct text', () => {
      const {getByText} = render(<DisplayRubricModal {...defaultProps} />)

      expect(getByText('Assignment Rubric Details')).toBeInTheDocument()
    })
  })

  describe('close functionality', () => {
    it('calls onClose when close button is clicked', () => {
      const onClose = vi.fn()
      const {getByText} = render(<DisplayRubricModal {...defaultProps} onClose={onClose} />)

      const closeButton = getByText('Close').closest('button')
      fireEvent.click(closeButton!)

      expect(onClose).toHaveBeenCalledTimes(1)
    })

    it('does not close on document click due to shouldCloseOnDocumentClick={false}', () => {
      const onClose = vi.fn()
      const {getByTestId} = render(<DisplayRubricModal {...defaultProps} onClose={onClose} />)

      const modal = getByTestId('assignment-rubric-modal')
      fireEvent.click(modal)

      expect(onClose).not.toHaveBeenCalled()
    })
  })

  describe('rubric display', () => {
    it('displays rubric title when rubric is provided', () => {
      const {getByText} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
        />,
      )

      expect(getByText('Test Rubric')).toBeInTheDocument()
    })

    it('shows create and find buttons when no rubric is provided', () => {
      const {getByTestId} = render(<DisplayRubricModal {...defaultProps} />)

      expect(getByTestId('create-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('find-assignment-rubric-button')).toBeInTheDocument()
    })

    it('displays preview button when rubric is provided', () => {
      const {getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
        />,
      )

      expect(getByTestId('preview-assignment-rubric-button')).toBeInTheDocument()
    })

    it('displays edit button when rubric is provided and user can manage rubrics', () => {
      const {getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
          canManageRubrics={true}
        />,
      )

      expect(getByTestId('edit-assignment-rubric-button')).toBeInTheDocument()
    })

    it('displays remove button when rubric is provided and user can manage rubrics', () => {
      const {getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
          canManageRubrics={true}
        />,
      )

      expect(getByTestId('remove-assignment-rubric-button')).toBeInTheDocument()
    })

    it('does not display edit and remove buttons when user cannot manage rubrics', () => {
      const {queryByTestId, getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
          canManageRubrics={false}
        />,
      )

      expect(queryByTestId('edit-assignment-rubric-button')).not.toBeInTheDocument()
      expect(queryByTestId('remove-assignment-rubric-button')).not.toBeInTheDocument()
      // Preview button should still be available
      expect(getByTestId('preview-assignment-rubric-button')).toBeInTheDocument()
    })
  })

  describe('preview interaction', () => {
    it('opens preview tray when preview button is clicked', () => {
      const {getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
        />,
      )

      const previewButton = getByTestId('preview-assignment-rubric-button')
      fireEvent.click(previewButton)

      // Check that the preview tray is opened
      const rubricTray = document.querySelector(
        '[role="dialog"][aria-label="Rubric Assessment Tray"]',
      )
      expect(rubricTray).toBeInTheDocument()
    })

    it('displays rubric criteria in preview tray', () => {
      const {getByTestId} = render(
        <DisplayRubricModal
          {...defaultProps}
          rubric={MOCK_RUBRIC}
          rubricAssociation={MOCK_RUBRIC_ASSOCIATION}
        />,
      )

      const previewButton = getByTestId('preview-assignment-rubric-button')
      fireEvent.click(previewButton)

      // Check for criterion ratings in the preview
      expect(getByTestId('traditional-criterion-1-ratings-0')).toBeInTheDocument()
    })
  })

  describe('create rubric flow', () => {
    it('opens create modal when create button is clicked', () => {
      const {getByTestId} = render(<DisplayRubricModal {...defaultProps} />)

      const createButton = getByTestId('create-assignment-rubric-button')
      fireEvent.click(createButton)

      expect(getByTestId('rubric-assignment-create-modal')).toBeInTheDocument()
    })

    it('opens find rubric tray when find button is clicked', () => {
      const {getByTestId} = render(<DisplayRubricModal {...defaultProps} />)

      const findButton = getByTestId('find-assignment-rubric-button')
      fireEvent.click(findButton)

      expect(getByTestId('rubric-search-tray')).toBeInTheDocument()
    })
  })
})
