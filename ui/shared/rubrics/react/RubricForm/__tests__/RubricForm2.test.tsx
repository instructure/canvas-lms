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
import {fireEvent, render, within, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import * as ProgressHelpers from '@canvas/progress/ProgressHelpers'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import {queryClient} from '@canvas/query'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
import {RUBRIC, RUBRIC_ASSOCIATION} from '../../RubricAssignment/__tests__/fixtures'
import {defaultGenerateCriteriaForm} from '../components/AIGeneratedCriteria/GeneratedCriteriaForm'

jest.mock('../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../queries/RubricFormQueries'),
  saveRubric: jest.fn(),
  generateCriteria: jest.fn(),
  regenerateCriteria: jest.fn(),
}))

jest.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: jest.fn(),
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

describe('RubricForm Tests', () => {
  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      context_asset_string: 'user_1',
    }
  })

  afterEach(() => {
    jest.resetAllMocks()
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

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent?.trim()

  describe('save rubric', () => {
    afterEach(() => {
      jest.resetAllMocks()
    })

    it('will navigate back to /rubrics after successfully saving', async () => {
      jest.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
        Promise.resolve({
          rubric: {
            id: '1',
            criteriaCount: 1,
            pointsPossible: 10,
            title: 'Rubric 1',
            criteria: [
              {
                id: '1',
                description: 'Criterion 1',
                points: 10,
                criterionUseRange: false,
                ratings: [],
              },
            ],
          },
          rubricAssociation: {
            hidePoints: false,
            hideScoreTotal: false,
            hideOutcomeResults: false,
            id: '1',
            useForGrading: true,
            associationType: 'Assignment',
            associationId: '1',
          },
        }),
      )
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      fireEvent.click(getByTestId('add-criterion-button'))

      // Wait for modal to appear
      await waitFor(() => {
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))
      fireEvent.click(getByTestId('save-rubric-button'))

      // Wait for save operation to complete
      await waitFor(() => {
        expect(getSRAlert()).toContain('Rubric saved successfully')
      })
    })

    it('save button is disabled when title is empty', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is disabled when title is whitespace', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: ' '}})
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is disabled when title is 255 whitespace even with criteria', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {
        target: {
          value:
            '                                                                                                                                                                                                                                                               ',
        },
      })
      fireEvent.click(getByTestId('add-criterion-button'))

      await waitFor(() => {
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      await waitFor(() => {
        expect(getByTestId('save-rubric-button')).toBeDisabled()
      })
    })

    it('save button is enabled when title is 254 whitespace and 1 letter', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {
        target: {
          value:
            'e                                                                                                                                                                                                                                                              ',
        },
      })
      fireEvent.click(getByTestId('add-criterion-button'))

      await waitFor(() => {
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      await waitFor(() => {
        expect(getByTestId('save-rubric-button')).toBeEnabled()
      })
    })

    it('save button is disabled when there are no criteria', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is enabled when title is not empty and there is criteria', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})

      fireEvent.click(getByTestId('add-criterion-button'))

      await waitFor(() => {
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      await waitFor(() => {
        expect(getByTestId('save-rubric-button')).toBeEnabled()
      })
    })

    it('preserves masteryPoints when saving a rubric with outcome criteria', async () => {
      const saveRubricSpy = jest.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
        Promise.resolve({
          rubric: {
            id: '1',
            criteriaCount: 1,
            pointsPossible: 10,
            title: 'Rubric with Outcome',
            criteria: [
              {
                id: '2',
                description: 'Outcome Criterion',
                points: 5,
                criterionUseRange: false,
                masteryPoints: 3.5,
                learningOutcomeId: 'outcome_123',
                ratings: [],
              },
            ],
          },
          rubricAssociation: {
            hidePoints: false,
            hideScoreTotal: false,
            hideOutcomeResults: false,
            id: '1',
            useForGrading: true,
            associationType: 'Assignment',
            associationId: '1',
          },
        }),
      )

      // Load a rubric with an outcome criterion that has masteryPoints
      queryClient.setQueryData(['fetch-rubric', '1'], {
        ...RUBRICS_QUERY_RESPONSE,
        criteria: [
          {
            id: '2',
            points: 5,
            description: 'Outcome Criterion',
            longDescription: '',
            ignoreForScoring: false,
            masteryPoints: 3.5,
            criterionUseRange: false,
            outcome: {
              displayName: 'Test Outcome',
              title: 'Test Outcome Title',
            },
            learningOutcomeId: 'outcome_123',
            ratings: [
              {
                id: '1',
                description: 'Excellent',
                longDescription: '',
                points: 5,
              },
            ],
          },
        ],
      })

      const {getByTestId} = renderComponent({rubricId: '1'})
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric with Outcome'}})
      fireEvent.click(getByTestId('save-rubric-button'))

      await waitFor(() => {
        expect(getSRAlert()).toContain('Rubric saved successfully')
      })

      // Verify saveRubric was called with masteryPoints preserved
      expect(saveRubricSpy).toHaveBeenCalledTimes(1)
      const rubricArg = saveRubricSpy.mock.calls[0][0]
      expect(rubricArg.criteria[0].masteryPoints).toBe(3.5)
      expect(rubricArg.criteria[0].learningOutcomeId).toBe('outcome_123')
    })

    it('does not display save as draft button if rubric has associations', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], {
        ...RUBRICS_QUERY_RESPONSE,
        hasRubricAssociations: true,
      })

      const {queryByTestId} = renderComponent({rubricId: '1'})
      expect(queryByTestId('save-as-draft-button')).toBeNull()
    })

    describe('Confirmation Modal', () => {
      afterEach(() => {
        jest.clearAllMocks()
      })

      it('does not render when not on assignment level', () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
        })
        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        const typeInput = getByTestId('rubric-rating-type-select')
        fireEvent.click(typeInput)
        fireEvent.click(getByTestId('rating_type_free_form'))

        const scoringTypeInput = getByTestId('rubric-rating-scoring-type-select')
        fireEvent.click(scoringTypeInput)
        fireEvent.click(getByTestId('scoring_type_unscored'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('does not render when the rubric is unchanged', () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('does not render when only assignment level settings are changed', () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        fireEvent.click(getByTestId('hide-outcome-results-checkbox'))
        fireEvent.click(getByTestId('use-for-grading-checkbox'))
        fireEvent.click(getByTestId('hide-score-total-checkbox'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('renders when the rubric base settings are changed on the assignment level', async () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        const typeInput = getByTestId('rubric-rating-type-select')
        fireEvent.click(typeInput)
        fireEvent.click(getByTestId('rating_type_free_form'))

        const scoringTypeInput = getByTestId('rubric-rating-scoring-type-select')
        fireEvent.click(scoringTypeInput)
        fireEvent.click(getByTestId('scoring_type_unscored'))

        fireEvent.click(getByTestId('rubric-criteria-row-edit-button'))

        const criterionNameInput = getByTestId('rubric-criterion-name-input')
        fireEvent.change(criterionNameInput, {target: {value: 'Criterion 1 (edited)'}})
        fireEvent.click(getByTestId('rubric-criterion-save'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeInTheDocument()
      })

      it('calls save on confirmation', async () => {
        const {getByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        fireEvent.click(getByTestId('save-rubric-button'))

        fireEvent.click(getByTestId('edit-confirm-btn'))

        await waitFor(() => {
          expect(RubricFormQueries.saveRubric).toHaveBeenCalled()
        })
      })

      it('does not call save on cancel', async () => {
        const {getByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        fireEvent.click(getByTestId('save-rubric-button'))

        fireEvent.click(getByTestId('edit-cancel-btn'))

        await waitFor(() => {
          expect(RubricFormQueries.saveRubric).not.toHaveBeenCalled()
        })
      })
    })
  })

  describe('ai rubrics', () => {
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
        expect(getByTestId('points-per-criterion-input')).toHaveValue('20')
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

      it('does not show the form when there is no assignmentId', () => {
        const {queryByTestId} = renderComponent({
          aiRubricsEnabled: true,
        })

        expect(queryByTestId('generate-criteria-form')).not.toBeInTheDocument()
      })

      it('validates points per criterion input', async () => {
        const {getByTestId} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const pointsInput = getByTestId('points-per-criterion-input')
        fireEvent.change(pointsInput, {target: {value: '-1'}})

        const generateButton = getByTestId('generate-criteria-button')
        fireEvent.click(generateButton)

        expect(RubricFormQueries.generateCriteria as jest.Mock).not.toHaveBeenCalled()
        expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
          'Points per criterion must be a valid number',
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
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
            _onFetchError: (error: Error) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
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
            pointsPerCriterion: '20',
            useRange: false,
            additionalPromptInfo: '',
            standard: standardText,
            gradeLevel: 'higher-ed',
          })
        })

        await waitFor(() => {
          expect(getByTestId('rubric-criteria-container')).toHaveTextContent(
            'Generated Criterion 1',
          )
        })
      })

      it('renders the ai icon for generated criteria', async () => {
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
            _onFetchError: (error: Error) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
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
        })
      })

      it('shows error when generateCriteria fails', async () => {
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
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
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
            _onFetchError: (error: Error) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'failed',
              message: null,
              completion: 1,
              results: undefined,
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
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
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

      it('shows the feedback link after criteria are generated', async () => {
        window.ENV = {
          ...window.ENV,
          AI_FEEDBACK_LINK: 'https://example.com/feedback',
        }

        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
            _onFetchError: (error: Error) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
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
          expect(getByTestId('give-feedback-link')).toHaveTextContent('Give Feedback')
        })
      })

      it('disables generate button when progress is running', async () => {
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'running',
              message: null,
              completion: 50,
              results: undefined,
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
        const generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
        })

        const progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'failed',
              message: null,
              completion: 100,
              results: undefined,
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

    describe('regenerate criteria', () => {
      let generateCriteriaMock: jest.Mock
      let regenerateCriteriaMock: jest.Mock
      let progressUpdateMock: jest.Mock

      beforeEach(() => {
        generateCriteriaMock = RubricFormQueries.generateCriteria as jest.Mock
        generateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        regenerateCriteriaMock = RubricFormQueries.regenerateCriteria as jest.Mock
        regenerateCriteriaMock.mockResolvedValue({
          id: 1,
          workflow_state: 'running',
          message: null,
          completion: 1,
        })

        progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
            _onFetchError: (error: Error) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
            })
          },
        )
      })

      afterEach(() => {
        jest.clearAllMocks()
      })

      it('shows regenerate button after criteria has been generated', async () => {
        const {getByTestId, queryAllByTestId} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const generateButton = getByTestId('generate-criteria-button')
        fireEvent.click(generateButton)

        await waitFor(() => {
          expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(2)
        })
      })

      it('does not show regenerate button if ai rubrics is disabled and new assignment rubric is being created', async () => {
        const {queryAllByTestId, getByTestId} = renderComponent({
          aiRubricsEnabled: false,
          assignmentId: '1',
          courseId: '1',
        })

        fireEvent.click(getByTestId('add-criterion-button'))

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })

        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        await waitFor(() => {
          expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
          expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(0)
        })
      })

      it('does not show regenerate button if ai rubrics is enabled and an assignment rubric is being edited', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {queryAllByTestId} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
          rubricId: '1',
        })

        await waitFor(() => {
          expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
          expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(0)
        })
      })

      it('displays the regenerate dialog with proper content when regenerate all is initiated', async () => {
        const {getByTestId, getByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const generateButton = getByTestId('generate-criteria-button')
        fireEvent.click(generateButton)

        await waitFor(() => {
          expect(getByTestId('generate-criteria-header')).toBeInTheDocument()
        })

        const generateCriteriaHeader = getByTestId('generate-criteria-header')
        const regenerateButton = within(generateCriteriaHeader).getByTestId(
          'regenerate-criteria-button',
        )

        expect(regenerateButton).toBeInTheDocument()
        fireEvent.click(regenerateButton)

        await waitFor(() => {
          expect(getByText('Regenerate Criteria')).toBeInTheDocument()
        })

        expect(getByTestId('regenerate-criteria-modal-description')).toHaveTextContent(
          'regenerate the criteria',
        )
        expect(getByTestId('additional-prompt-textarea')).toBeInTheDocument()
      })

      it('displays the regenerate dialog with proper content when regenerate for a specific criterion is initiated', async () => {
        const {queryAllByTestId, getByTestId, getByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        await waitFor(() => {
          expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(0)
        })

        fireEvent.click(getByTestId('add-criterion-button'))

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        await waitFor(() => {
          expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
        })

        fireEvent.click(getByTestId('regenerate-criteria-button'))

        await waitFor(() => {
          expect(getByText('Regenerate Criterion')).toBeInTheDocument()
        })

        expect(getByText('Regenerate Criterion')).toBeInTheDocument()
        expect(getByTestId('regenerate-criteria-modal-description')).toHaveTextContent(
          'Please provide more information about how you would like to regenerate the criterion',
        )
        expect(getByTestId('additional-prompt-textarea')).toBeInTheDocument()
      })

      it('validates the additional prompt input', async () => {
        const {getByTestId, getByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const generateButton = getByTestId('generate-criteria-button')
        fireEvent.click(generateButton)

        await waitFor(() => {
          expect(getByTestId('generate-criteria-header')).toBeInTheDocument()
        })

        const generateCriteriaHeader = getByTestId('generate-criteria-header')
        const regenerateButton = within(generateCriteriaHeader).getByTestId(
          'regenerate-criteria-button',
        )

        expect(regenerateButton).toBeInTheDocument()
        fireEvent.click(regenerateButton)

        await waitFor(() => {
          expect(getByText('Regenerate Criteria')).toBeInTheDocument()
        })

        expect(getByText('Regenerate Criteria')).toBeInTheDocument()
        expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()

        const additionalPromptInput = getByTestId('additional-prompt-textarea')
        const longText = 'a'.repeat(1001)

        fireEvent.change(additionalPromptInput, {target: {value: longText}})

        expect(
          getByText('Additional prompt information must be less than 1000 characters'),
        ).toBeInTheDocument()
        expect(getByTestId('regenerate-criteria-submit-button')).toBeDisabled()
      })

      it('calls regenerate with additional prompt', async () => {
        const assignmentId = '1'
        const courseId = '1'
        const {getByTestId, getByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId,
          courseId,
        })

        const generateButton = getByTestId('generate-criteria-button')
        fireEvent.click(generateButton)

        await waitFor(() => {
          expect(getByTestId('generate-criteria-header')).toBeInTheDocument()
        })

        const generateCriteriaHeader = getByTestId('generate-criteria-header')
        const regenerateButton = within(generateCriteriaHeader).getByTestId(
          'regenerate-criteria-button',
        )

        expect(regenerateButton).toBeInTheDocument()
        fireEvent.click(regenerateButton)

        await waitFor(() => {
          expect(getByText('Regenerate Criteria')).toBeInTheDocument()
        })

        const additionalPromptInput = getByTestId('additional-prompt-textarea')
        const additionalPrompt = 'User regenerate prompt'

        fireEvent.change(additionalPromptInput, {target: {value: additionalPrompt}})
        expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()

        fireEvent.click(getByTestId('regenerate-criteria-submit-button'))

        await waitFor(() => {
          expect(regenerateCriteriaMock).toHaveBeenCalledWith(
            courseId,
            assignmentId,
            expect.any(Array),
            additionalPrompt,
            undefined,
            defaultGenerateCriteriaForm,
          )
        })

        await waitForElementToBeRemoved(() => getByText('Regenerate Criteria'))
      })

      it('closes the regenerate dialog when cancel is clicked', async () => {
        progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'running',
              message: null,
              completion: 50,
              results: undefined,
            })
          },
        )

        const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        // Add criterion
        const addCriterionButton = getByTestId('add-criterion-button')
        fireEvent.click(addCriterionButton)

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })

        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)

        const regenerateCriterionButton = getByTestId('regenerate-criteria-button')
        fireEvent.click(regenerateCriterionButton)

        await waitFor(() => {
          expect(queryByText('Regenerate Criterion')).toBeInTheDocument()
        })

        const cancelButton = getByTestId('regenerate-criteria-cancel-button')
        fireEvent.click(cancelButton)

        await waitFor(() => {
          expect(regenerateCriteriaMock).not.toHaveBeenCalled()
        })

        await waitForElementToBeRemoved(queryByText('Regenerate Criterion'))
      })

      it('disables the regenerate button when progress is running', async () => {
        progressUpdateMock = ProgressHelpers.monitorProgress as jest.Mock
        progressUpdateMock.mockImplementation(
          (
            progressId: string,
            setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
          ) => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'running',
              message: null,
              completion: 50,
              results: undefined,
            })
          },
        )

        const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const addCriterionButton = getByTestId('add-criterion-button')
        fireEvent.click(addCriterionButton)

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)

        // Start criterion regeneration
        const regenerateCriterionButton = getByTestId('regenerate-criteria-button')
        fireEvent.click(regenerateCriterionButton)

        await waitFor(() => {
          expect(queryByText('Regenerate Criterion')).toBeInTheDocument()
        })

        const submitCriterionRegenerateButton = getByTestId('regenerate-criteria-submit-button')
        expect(submitCriterionRegenerateButton).toBeEnabled()
        fireEvent.click(submitCriterionRegenerateButton)

        await waitFor(() => {
          expect(regenerateCriteriaMock).toHaveBeenCalled()
        })

        // Wait for the modal to close using waitFor for more reliability
        await waitForElementToBeRemoved(queryByText('Regenerate Criterion'))

        expect(getByTestId('generate-criteria-button')).toBeDisabled()
        expect(getByTestId('regenerate-criteria-button')).toBeDisabled()
      })

      it('displays error message if criteria regeneration fails', async () => {
        regenerateCriteriaMock = RubricFormQueries.regenerateCriteria as jest.Mock
        regenerateCriteriaMock.mockRejectedValueOnce(new Error('Failed to regenerate'))

        const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const addCriterionButton = getByTestId('add-criterion-button')
        fireEvent.click(addCriterionButton)

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)

        const regenerateCriterionButton = getByTestId('regenerate-criteria-button')
        fireEvent.click(regenerateCriterionButton)

        await waitFor(() => {
          expect(queryByText('Regenerate Criterion')).toBeInTheDocument()
        })

        const submitCriterionRegenerateButton = getByTestId('regenerate-criteria-submit-button')
        expect(submitCriterionRegenerateButton).toBeEnabled()
        fireEvent.click(submitCriterionRegenerateButton)

        // Wait for the modal to close using the same pattern as other tests
        await waitForElementToBeRemoved(queryByText('Regenerate Criterion'))

        await waitFor(
          () => {
            expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
              'Failed to regenerate criteria',
            )
          },
          {timeout: 5000},
        )
      })

      it('replaces the criterions with the regenerated one', async () => {
        const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
          aiRubricsEnabled: true,
          assignmentId: '1',
          courseId: '1',
        })

        const addCriterionButton = getByTestId('add-criterion-button')
        fireEvent.click(addCriterionButton)

        await waitFor(() => {
          expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        })
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
        expect(queryByText('New Criterion Test')).toBeInTheDocument()

        const regenerateCriterionButton = getByTestId('regenerate-criteria-button')
        fireEvent.click(regenerateCriterionButton)

        await waitFor(() => {
          expect(queryByText('Regenerate Criterion')).toBeInTheDocument()
        })

        const submitCriterionRegenerateButton = getByTestId('regenerate-criteria-submit-button')
        expect(submitCriterionRegenerateButton).toBeEnabled()
        fireEvent.click(submitCriterionRegenerateButton)

        // Wait for the modal to close using waitFor for more reliability
        await waitForElementToBeRemoved(queryByText('Regenerate Criterion'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
        expect(queryByText('New Criterion Test')).not.toBeInTheDocument()
        expect(queryByText('Generated Criterion 1')).toBeInTheDocument()
      })
    })
  })
})
