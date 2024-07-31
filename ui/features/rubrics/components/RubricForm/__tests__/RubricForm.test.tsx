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
import Router from 'react-router'
import {BrowserRouter} from 'react-router-dom'
import {fireEvent, render} from '@testing-library/react'
import {QueryProvider, queryClient} from '@canvas/query'
import {RubricForm, reorder} from '../index'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
import * as RubricFormQueries from '../../../queries/RubricFormQueries'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))

const saveRubricMock = jest.fn()
jest.mock('../../../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../../../queries/RubricFormQueries'),
  saveRubric: () => saveRubricMock,
}))

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
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})

    window.ENV = {
      ...window.ENV,
      context_asset_string: 'user_1',
    }
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = () => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <RubricForm rootOutcomeGroup={ROOT_OUTCOME_GROUP} />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent

  describe('without rubricId', () => {
    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId, getByText} = renderComponent()
      expect(getByText('Create New Rubric')).toBeInTheDocument()
      expect(getByTestId('rubric-form-title')).toHaveValue('')
      // expect(getByTestId('rubric-hide-points-select')).toBeInTheDocument()
      expect(getByTestId('rubric-rating-order-select')).toBeInTheDocument()
      expect(getByTestId('save-as-draft-button')).toBeInTheDocument()
    })
  })

  describe('with rubricId', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({rubricId: '1'})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
    })
  })

  describe('save rubric', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
    })

    afterEach(() => {
      jest.resetAllMocks()
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
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(getByTestId('save-rubric-button')).toBeEnabled()
    })

    it('will navigate back to /rubrics after successfully saving', async () => {
      jest.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
        Promise.resolve({
          id: '1',
          title: 'Rubric 1',
          pointsPossible: 10,
          buttonDisplay: 'numeric',
          ratingOrder: 'descending',
          unassessed: true,
          hasRubricAssociations: false,
        })
      )
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      fireEvent.click(getByTestId('add-criterion-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))
      fireEvent.click(getByTestId('save-rubric-button'))

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getSRAlert()).toEqual('Rubric saved successfully')
    })

    it('does not display save as draft button if rubric has associations', () => {
      jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1', rubricId: '1'})

      queryClient.setQueryData(['fetch-rubric-1'], {
        ...RUBRICS_QUERY_RESPONSE,
        hasRubricAssociations: true,
      })

      const {queryByTestId} = renderComponent()
      expect(queryByTestId('save-as-draft-button')).toBeNull()
    })
  })

  describe('rubric criteria', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({rubricId: '1'})
    })

    it('renders all criteria rows for a rubric', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent()
      const criteriaRows = queryAllByTestId('rubric-criteria-row')
      const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
      const criteriaRowLongDescriptions = queryAllByTestId('rubric-criteria-row-long-description')
      const criteriaRowThresholds = queryAllByTestId('rubric-criteria-row-threshold')
      const criteriaRowPoints = queryAllByTestId('rubric-criteria-row-points')
      const criteriaRowIndexes = queryAllByTestId('rubric-criteria-row-index')
      expect(criteriaRows.length).toEqual(2)
      expect(criteriaRowDescriptions[0]).toHaveTextContent(criteria[0].description)
      expect(criteriaRowDescriptions[1]).toHaveTextContent(criteria[1].longDescription ?? '')
      expect(criteriaRowLongDescriptions[0]).toHaveTextContent(criteria[0].longDescription ?? '')
      expect(criteriaRowPoints[0]).toHaveTextContent(criteria[0].points.toString())
      expect(criteriaRowPoints[1]).toHaveTextContent(criteria[1].points.toString())
      expect(criteriaRowIndexes[0]).toHaveTextContent('1.')
      expect(criteriaRowIndexes[1]).toHaveTextContent('2')
      expect(criteriaRowThresholds.length).toEqual(1)
      expect(criteriaRowThresholds[0]).toHaveTextContent('Threshold: 3')
    })

    it('renders the criterion ratings accordion button', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent()
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      expect(ratingScaleAccordion.length).toEqual(2)
      expect(ratingScaleAccordion[0]).toHaveTextContent(
        `Rating Scale: ${criteria[0].ratings.length}`
      )
      expect(ratingScaleAccordion[1]).toHaveTextContent(
        `Rating Scale: ${criteria[0].ratings.length}`
      )
    })

    it('renders the criterion ratings accordion items when button is clicked', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent()
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      fireEvent.click(ratingScaleAccordion[0])
      const ratingScaleAccordionItems = queryAllByTestId('rating-scale-accordion-item')
      expect(ratingScaleAccordionItems.length).toEqual(criteria[0].ratings.length)
    })

    it('does not render the criterion ratings accordion items when accordion is closed', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {queryAllByTestId} = renderComponent()
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      fireEvent.click(ratingScaleAccordion[0])
      fireEvent.click(ratingScaleAccordion[0])

      const ratingScaleAccordionItems = queryAllByTestId('rating-scale-accordion-item')
      expect(ratingScaleAccordionItems.length).toEqual(0)
    })

    it('should reorder all criteria after drag and drop, but keep original point values of criteria', () => {
      const criteria = [
        {
          id: '1',
          points: 5,
          description: 'Criterion 1',
          longDescription: 'Long description for criterion 1',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 5,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
        {
          id: '2',
          points: 15,
          description: 'Criterion 2',
          longDescription: 'Long description for criterion 2',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 15,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
        {
          id: '3',
          points: 10,
          description: 'Criterion 3',
          longDescription: 'Long description for criterion 3',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 10,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
      ]

      const startIndex = 0
      const endIndex = 2

      const reorderedCriteria = reorder({list: criteria, startIndex, endIndex})

      expect(reorderedCriteria[0]).toEqual(criteria[1])
      expect(reorderedCriteria[1]).toEqual(criteria[2])
      expect(reorderedCriteria[2]).toEqual(criteria[0])
    })

    it('renders a lock icon with a tooltip next to the outcome name', async () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId, getByTestId} = renderComponent()

      const outcomeLockIcons = queryAllByTestId(/^outcome-lock-icon/)
      expect(outcomeLockIcons.length).toEqual(1)

      expect(getByTestId('outcome-lock-icon-2')).toBeInTheDocument()
    })

    /**
     * EVAL-4246
     * This test is skipped because it is dependent on a legacy FindDialog backbone component
     * It currently has failures in packages/jquery and is incompatible with the current React test environment
     * These tests should be re-enabled once the Outcomes Tray React component is implemented
     */
    describe.skip('new outcome criterion modal', () => {
      it('imports an outcome linked criteria when the import button is clicked in the find outcome modal', () => {
        const outcomeData = {
          attributes: {
            points_possible: 10,
            description: '<p>Sample description</p>',
            display_name: 'Sample Outcome Display Name',
            mastery_points: 8,
            ratings: ['A', 'B', 'C'],
          },
          outcomeLink: {
            outcome: {
              title: 'Sample Outcome Title',
              id: '123',
            },
          },
        }
        jest.spyOn(FindDialog.prototype, 'import').mockImplementation(function () {
          // @ts-ignore
          ;(this as FindDialog).trigger('import', {...outcomeData})
        })
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText, queryAllByTestId} = renderComponent()
        fireEvent.click(getByTestId('create-from-outcome-button'))
        fireEvent.click(getByText('Import'))

        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(3)
        expect(queryAllByTestId('rubric-criteria-row-description')[2]).toHaveTextContent(
          'Sample description'
        ) // removes p tags correctly
        expect(queryAllByTestId('rubric-criteria-outcome-subtitle')[1]).toHaveTextContent(
          'Sample Outcome Display Name'
        )
        expect(queryAllByTestId('rubric-criteria-row-outcome-tag')[1]).toHaveTextContent(
          'Sample Outcome Title'
        )
      })

      it('displays a flash error if the outcome has already been imported into the current rubric', () => {
        const outcomeData = {
          attributes: {
            points_possible: 10,
            description: '<p>Sample description</p>',
            display_name: 'Sample Outcome Display Name',
            mastery_points: 8,
            ratings: ['A', 'B', 'C'],
          },
          outcomeLink: {
            outcome: {
              title: 'Sample Outcome Title',
              id: '12345',
            },
          },
        }
        jest.spyOn(FindDialog.prototype, 'import').mockImplementation(function () {
          // @ts-ignore
          ;(this as FindDialog).trigger('import', {...outcomeData})
        })
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText, getAllByText} = renderComponent()
        fireEvent.click(getByTestId('create-from-outcome-button'))
        fireEvent.click(getByText('Import'))

        expect(
          getAllByText('This Outcome has not been added as it already exists in this rubric.')[0]
        ).toBeInTheDocument()
      })
    })

    describe('criterion modal', () => {
      it('opens the criterion modal when the add criterion button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent()
        expect(queryByTestId('rubric-criterion-modal')).toBeNull()
        fireEvent.click(getByTestId('add-criterion-button'))

        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      it('does not save new criterion when the cancel button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent()
        fireEvent.click(getByTestId('add-criterion-button'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-cancel'))
        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)
      })

      it('saves new criterion when the save button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent()
        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)

        fireEvent.click(getByTestId('add-criterion-button'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(3)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[2]).toHaveTextContent('New Criterion Test')
      })

      it('updates existing criterion when the save button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent()
        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)

        fireEvent.click(queryAllByTestId('rubric-criteria-row-edit-button')[0])
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'Updated Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[0]).toHaveTextContent('Updated Criterion Test')
      })

      it('does not update existing criterion when the cancel button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent()
        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)

        fireEvent.click(queryAllByTestId('rubric-criteria-row-edit-button')[0])
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'Updated Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-cancel'))

        expect(queryAllByTestId('rubric-criteria-row').length).toEqual(2)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[0]).not.toHaveTextContent('Updated Criterion Test')
      })
    })
  })

  describe('assessed rubrics', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({rubricId: '1'})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('only renders text inputs for an assessed rubric', () => {
      const rubricQueryResponse = {...RUBRICS_QUERY_RESPONSE, unassessed: false}
      queryClient.setQueryData(['fetch-rubric-1'], rubricQueryResponse)

      const {getByTestId, queryByTestId, queryAllByTestId} = renderComponent()
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
      // expect(queryByTestId('rubric-hide-points-select')).toBeNull()
      expect(queryByTestId('rubric-rating-order-select')).toBeNull()
      expect(queryByTestId('add-criterion-button')).toBeNull()
      expect(queryAllByTestId('rubric-criteria-row-delete-button')).toHaveLength(0)
      expect(queryAllByTestId('rubric-criteria-row-duplicate-button')).toHaveLength(0)
    })
  })
})
