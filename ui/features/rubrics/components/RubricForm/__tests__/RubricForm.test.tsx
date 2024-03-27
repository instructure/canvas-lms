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
import {RubricForm} from '../index'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
import * as RubricFormQueries from '../../../queries/RubricFormQueries'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))

const saveRubricMock = jest.fn()
jest.mock('../../../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../../../queries/RubricFormQueries'),
  saveRubric: () => saveRubricMock,
}))

describe('RubricForm Tests', () => {
  beforeEach(() => {
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = () => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <RubricForm />
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
      expect(getByTestId('rubric-hide-points-select')).toBeInTheDocument()
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

    it('save button is enabled when title is not empty', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
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
      const criteriaRowPoints = queryAllByTestId('rubric-criteria-row-points')
      const criteriaRowIndexes = queryAllByTestId('rubric-criteria-row-index')
      expect(criteriaRows.length).toEqual(2)
      expect(criteriaRowDescriptions[0]).toHaveTextContent(criteria[0].description)
      expect(criteriaRowDescriptions[1]).toHaveTextContent(criteria[1].description)
      expect(criteriaRowLongDescriptions[0]).toHaveTextContent(criteria[0].longDescription)
      expect(criteriaRowLongDescriptions[1]).toHaveTextContent(criteria[1].longDescription)
      expect(criteriaRowPoints[0]).toHaveTextContent(criteria[0].points.toString())
      expect(criteriaRowPoints[1]).toHaveTextContent(criteria[1].points.toString())
      expect(criteriaRowIndexes[0]).toHaveTextContent('1.')
      expect(criteriaRowIndexes[1]).toHaveTextContent('2')
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
        fireEvent.change(getByTestId('rubric-criterion-description'), {
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
        fireEvent.change(getByTestId('rubric-criterion-description'), {
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
        fireEvent.change(getByTestId('rubric-criterion-description'), {
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
        fireEvent.change(getByTestId('rubric-criterion-description'), {
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
      expect(queryByTestId('rubric-hide-points-select')).toBeNull()
      expect(queryByTestId('rubric-rating-order-select')).toBeNull()
      expect(queryByTestId('add-criterion-button')).toBeNull()
      expect(queryAllByTestId('rubric-criteria-row-delete-button')).toHaveLength(0)
      expect(queryAllByTestId('rubric-criteria-row-duplicate-button')).toHaveLength(0)
    })
  })
})
