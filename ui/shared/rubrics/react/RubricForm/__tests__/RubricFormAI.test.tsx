/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {type Mock} from 'vitest'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import * as ProgressHelpers from '@canvas/progress/ProgressHelpers'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'
import {queryClient} from '@canvas/query'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'

vi.mock('../queries/RubricFormQueries', async () => ({
  ...(await vi.importActual('../queries/RubricFormQueries')),
  saveRubric: vi.fn(),
  generateCriteria: vi.fn(),
}))

vi.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: vi.fn(),
}))

const mockCriteria = [
  {
    id: '1',
    description: 'Generated Criterion 1',
    points: 20,
    ratings: [],
    longDescription: '',
    outcome: undefined,
    learningOutcomeId: undefined,
    ignoreForScoring: false,
    criterionUseRange: false,
    masteryPoints: 0,
  },
]

const ROOT_OUTCOME_GROUP = {
  id: '1',
  title: 'Root Outcome Group',
  vendor_guid: '12345',
  subgroups_url: 'https://example.com/subgroups',
  outcomes_url: 'https://example.com/outcomes',
  can_edit: true,
  import_url: 'https://example.com/import',
  context_id: '1',
  context_type: 'Account',
  description: 'Root Outcome Group Description',
  url: 'https://example.com/root',
}

describe('RubricForm AI Tests', () => {
  beforeEach(() => {
    fakeEnv.setup({
      context_asset_string: 'user_1',
      AI_FEEDBACK_LINK: 'https://example.com/feedback',
    })
  })

  afterEach(() => {
    vi.resetAllMocks()
    fakeEnv.teardown()
    destroyFlashAlertContainer()
  })

  const renderComponent = (props?: Partial<RubricFormComponentProp>) => {
    return render(
      <MockedQueryProvider>
        <RubricForm
          rootOutcomeGroup={ROOT_OUTCOME_GROUP}
          criterionUseRangeEnabled={false}
          canManageRubrics={true}
          onCancel={() => {}}
          onSaveRubric={() => {}}
          accountId="1"
          showAdditionalOptions={true}
          aiRubricsEnabled={false}
          {...props}
        />
      </MockedQueryProvider>,
    )
  }

  describe('generate criteria form', () => {
    it('shows the generate criteria form when aiRubricsEnabled is true and there is an assignmentId', () => {
      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      expect(getByTestId('generate-criteria-form')).toBeInTheDocument()
      expect(getByTestId('grade-level-input')).toHaveValue('Higher Education')
      expect(getByTestId('criteria-count-input')).toHaveValue('5')
      expect(getByTestId('rating-count-input')).toHaveValue('4')
      expect(getByTestId('criteria-total-points-input')).toHaveValue('20')
      expect(getByTestId('standard-objective-input')).toBeInTheDocument()
      expect(getByTestId('additional-prompt-info-input')).toBeInTheDocument()
    })

    it('does not show the form when aiRubricsEnabled is false', () => {
      const {queryByTestId} = renderComponent({
        aiRubricsEnabled: false,
        assignmentId: '1',
      })

      expect(queryByTestId('generate-criteria-form')).not.toBeInTheDocument()
    })

    it('does not show regenerate button when aiRubricsEnabled is false', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {queryAllByTestId} = renderComponent({
        aiRubricsEnabled: false,
        assignmentId: '1',
        courseId: '1',
        rubricId: '1',
      })

      expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
      expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(0)
    })

    it('does not show the form when there is no assignmentId', () => {
      const {queryByTestId} = renderComponent({
        aiRubricsEnabled: true,
      })

      expect(queryByTestId('generate-criteria-form')).not.toBeInTheDocument()
    })

    it('validates total points input', async () => {
      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const pointsInput = getByTestId('criteria-total-points-input')
      fireEvent.change(pointsInput, {target: {value: '-1'}})

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      expect(RubricFormQueries.generateCriteria as Mock).not.toHaveBeenCalled()
      expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
        'Total points must be a valid positive number',
      )
    })

    it('validates standard objective length', async () => {
      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const longText = 'a'.repeat(1001)
      const standardObjectiveInput = getByTestId('standard-objective-input')
      fireEvent.change(standardObjectiveInput, {target: {value: longText}})

      expect(getByTestId('generate-criteria-button')).toBeDisabled()
      const form = getByTestId('generate-criteria-form')
      expect(form).toHaveTextContent(
        'Standard and Outcome information must be less than 1000 characters',
      )
    })

    it('validates additional prompt info length', async () => {
      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const longText = 'a'.repeat(1001)
      const additionalPromptInput = getByTestId('additional-prompt-info-input')
      fireEvent.change(additionalPromptInput, {target: {value: longText}})

      expect(getByTestId('generate-criteria-button')).toBeDisabled()
      const form = getByTestId('generate-criteria-form')
      expect(form).toHaveTextContent(
        'Additional prompt information must be less than 1000 characters',
      )
    })

    it('calls generateCriteria with correct parameters when generate button is clicked', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          progressId: string,
          setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          _onFetchError: (error: Error) => void,
        ) => {
          queueMicrotask(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
            })
          })
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const standardText = `Compare and contrast the experience of reading a story, drama, or poem to listening to or viewing an audio, video, or live version of the text, including contrasting what they "see" and "hear" when reading the text to what they perceive when they listen or watch.`
      const standardObjectiveInput = getByTestId('standard-objective-input')
      fireEvent.change(standardObjectiveInput, {target: {value: standardText}})

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(generateCriteriaMock).toHaveBeenCalledWith('1', '1', {
          criteriaCount: 5,
          ratingCount: 4,
          totalPoints: '20',
          useRange: false,
          additionalPromptInfo: '',
          standard: standardText,
          gradeLevel: 'higher-ed',
        })
      })

      await waitFor(() => {
        expect(getByTestId('rubric-criteria-container')).toHaveTextContent('Generated Criterion 1')
      })
    })

    it('renders the ai icon and feedback link after criteria are generated', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
        message: null,
        completion: 1,
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          progressId: string,
          setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          _onFetchError: (error: Error) => void,
        ) => {
          queueMicrotask(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
            })
          })
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        const criteriaRows = getByTestId('rubric-criteria-container')
        expect(
          criteriaRows.querySelector('[data-testid="rubric-criteria-row-ai-icon"]'),
        ).toBeInTheDocument()
        expect(getByTestId('give-feedback-link')).toBeInTheDocument()
      })
    })

    it('shows error when generateCriteria fails', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockRejectedValueOnce(new Error('Failed to generate'))

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
          'Failed to generate criteria',
        )
      })
    })

    it('shows error when progress fails', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
        message: null,
        completion: 1,
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          progressId: string,
          setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          _onFetchError: (error: Error) => void,
        ) => {
          queueMicrotask(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'failed',
              message: null,
              completion: 1,
              results: undefined,
            })
          })
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
          'Failed to generate criteria',
        )
      })
    })

    it('shows error when progress errors', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
        message: null,
        completion: 1,
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          _progressId: string,
          _setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          onFetchError: (error: Error) => void,
        ) => {
          onFetchError(new Error('Failed to generate'))
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
          'Failed to generate criteria',
        )
      })
    })

    it('disables generate button when progress is running', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          progressId: string,
          setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
        ) => {
          queueMicrotask(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'running',
              message: null,
              completion: 50,
              results: undefined,
            })
          })
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(generateButton).toBeDisabled()
      })
    })

    it('enables generate button when progress fails', async () => {
      const generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
      })

      const progressUpdateMock = ProgressHelpers.monitorProgress as Mock
      progressUpdateMock.mockImplementation(
        (
          progressId: string,
          setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
        ) => {
          queueMicrotask(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'failed',
              message: null,
              completion: 100,
              results: undefined,
            })
          })
        },
      )

      const {getByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(generateButton).not.toBeDisabled()
      })
    })
  })
})
