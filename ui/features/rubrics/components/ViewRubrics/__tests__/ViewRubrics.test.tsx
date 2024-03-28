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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {QueryProvider, queryClient} from '@canvas/query'
import {ViewRubrics} from '../index'
import {RUBRICS_QUERY_RESPONSE, RUBRIC_PREVIEW_QUERY_RESPONSE} from './fixtures'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))

describe('ViewRubrics Tests', () => {
  const renderComponent = () => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <ViewRubrics />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  describe('account level rubrics', () => {
    beforeAll(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
    })

    it('renders the ViewRubrics component with all rubric data split rubrics by workflow state', () => {
      queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId, getByText} = renderComponent()

      // total rubrics length per workflow state + header row
      expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toEqual(3)

      expect(getByTestId('rubric-title-0')).toHaveTextContent('Rubric 1')
      expect(getByTestId('rubric-points-0')).toHaveTextContent('5')
      expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent('1')
      expect(getByTestId('rubric-locations-0')).toHaveTextContent('-')

      expect(getByTestId('rubric-title-1')).toHaveTextContent('Rubric 3')
      expect(getByTestId('rubric-points-1')).toHaveTextContent('15')
      expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent('3')
      expect(getByTestId('rubric-locations-1')).toHaveTextContent('courses and assignments')

      expect(getByTestId('rubric-title-1')).toHaveTextContent('Rubric 3')
      expect(getByTestId('rubric-points-1')).toHaveTextContent('15')
      expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent('3')
      expect(getByTestId('rubric-locations-1')).toHaveTextContent('courses and assignments')

      const archivedRubricsTab = getByText('Archived')
      archivedRubricsTab.click()

      expect(getByTestId('archived-rubrics-table').querySelectorAll('tr').length).toEqual(2)

      expect(getByTestId('rubric-title-0')).toHaveTextContent('Rubric 2')
      expect(getByTestId('rubric-points-0')).toHaveTextContent('10')
      expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent('2')
      expect(getByTestId('rubric-locations-0')).toHaveTextContent('-')
    })

    it('renders a popover menu with access to the rubric edit modal', () => {
      const mockNavigate = jest.fn()
      jest.spyOn(Router, 'useNavigate').mockReturnValue(mockNavigate)

      queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const editButton = getByTestId('edit-rubric-button')
      editButton.click()

      expect(Router.useNavigate).toHaveBeenCalledWith()
      expect(Router.useNavigate).toHaveReturnedWith(expect.any(Function))
    })

    it('renders a popover menu with access to the rubric duplicate modal', () => {
      queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const duplicateButton = getByTestId('duplicate-rubric-button')
      duplicateButton.click()

      expect(getByTestId('duplicate-rubric-modal')).toBeInTheDocument()
    })

    it('renders a popover menu with access to the rubric delete modal', () => {
      queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const deleteButton = getByTestId('delete-rubric-button')
      deleteButton.click()

      expect(getByTestId('delete-rubric-modal')).toBeInTheDocument()
    })

    it('disables the delete option in the popover menu if the rubric has rubric associations active', () => {
      queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      getByTestId('rubric-options-1-button').click()
      expect(getByTestId('delete-rubric-button')).not.toHaveAttribute('aria-disabled')
      getByTestId('rubric-options-1-button').click()

      getByTestId('rubric-options-3-button').click()
      expect(getByTestId('delete-rubric-button')).toHaveAttribute('aria-disabled', 'true')
    })

    describe('sorting', () => {
      it('sorts rubrics by Rubric Name in ascending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const rubricNameHeader = getByText('Rubric Name')
        fireEvent.click(rubricNameHeader)

        const sortedRubricNames = ['Rubric 1', 'Rubric 3']
        expect(getByTestId('rubric-title-0')).toHaveTextContent(sortedRubricNames[0])
        expect(getByTestId('rubric-title-1')).toHaveTextContent(sortedRubricNames[1])
      })

      it('sorts rubrics by Rubric Name in descending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const rubricNameHeader = getByText('Rubric Name')
        fireEvent.click(rubricNameHeader)
        fireEvent.click(rubricNameHeader)
        fireEvent.click(rubricNameHeader)

        const sortedRubricNames = ['Rubric 3', 'Rubric 1']
        expect(getByTestId('rubric-title-0')).toHaveTextContent(sortedRubricNames[1])
        expect(getByTestId('rubric-title-1')).toHaveTextContent(sortedRubricNames[0])
      })

      it('sorts rubrics by Total Points in ascending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const totalPointsHeader = getByText('Total Points')
        fireEvent.click(totalPointsHeader)

        const sortedTotalPoints = ['5', '15']
        expect(getByTestId('rubric-points-0')).toHaveTextContent(sortedTotalPoints[0])
        expect(getByTestId('rubric-points-1')).toHaveTextContent(sortedTotalPoints[1])
      })

      it('sorts rubrics by Total Points in descending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const totalPointsHeader = getByText('Total Points')
        fireEvent.click(totalPointsHeader)
        fireEvent.click(totalPointsHeader)

        const sortedTotalPoints = ['15', '5']
        expect(getByTestId('rubric-points-0')).toHaveTextContent(sortedTotalPoints[0])
        expect(getByTestId('rubric-points-1')).toHaveTextContent(sortedTotalPoints[1])
      })

      it('sorts rubrics by Criterion count in ascending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const criterionHeader = getByText('Criterion')
        fireEvent.click(criterionHeader)

        const sortedCriterion = ['1', '3']
        expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent(sortedCriterion[0])
        expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent(sortedCriterion[1])
      })

      it('sorts rubrics by Criterion count in descending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const criterionHeader = getByText('Criterion')
        fireEvent.click(criterionHeader)
        fireEvent.click(criterionHeader)
        fireEvent.click(criterionHeader)

        const sortedCriterion = ['3', '1']
        expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent(sortedCriterion[1])
        expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent(sortedCriterion[0])
      })

      it('sorts rubrics by Location Used in ascending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const locationUsedHeader = getByText('Location Used')
        fireEvent.click(locationUsedHeader)

        const sortedLocations = ['courses and assignments', '-']
        expect(getByTestId('rubric-locations-0')).toHaveTextContent(sortedLocations[0])
        expect(getByTestId('rubric-locations-1')).toHaveTextContent(sortedLocations[1])
      })

      it('sorts rubrics by Location Used in descending order', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const locationUsedHeader = getByText('Location Used')
        fireEvent.click(locationUsedHeader)
        fireEvent.click(locationUsedHeader)

        const sortedLocations = ['-', 'courses and assignments']
        expect(getByTestId('rubric-locations-0')).toHaveTextContent(sortedLocations[0])
        expect(getByTestId('rubric-locations-1')).toHaveTextContent(sortedLocations[1])
      })

      it('filters rubrics based on search query at account level', () => {
        queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, queryByText} = renderComponent()

        expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toBe(3)

        const searchInput = getByTestId('rubric-search-bar')
        fireEvent.change(searchInput, {target: {value: '1'}})

        expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toBe(2)
        expect(queryByText('Rubric 1')).not.toBeNull()
        expect(queryByText('Rubric 2')).toBeNull()
        expect(queryByText('Rubric 3')).toBeNull()
      })
    })
  })

  describe('course level rubrics', () => {
    beforeAll(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({courseId: '1'})
    })
    it('renders the ViewRubrics component with split rubrics by workflow state', () => {
      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId, getByText} = renderComponent()

      // total rubrics length per workflow state + header row
      expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toEqual(3)

      expect(getByTestId('rubric-title-0')).toHaveTextContent('Rubric 1')
      expect(getByTestId('rubric-points-0')).toHaveTextContent('5')
      expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent('1')
      expect(getByTestId('rubric-locations-0')).toHaveTextContent('-')

      expect(getByTestId('rubric-title-1')).toHaveTextContent('Rubric 3')
      expect(getByTestId('rubric-points-1')).toHaveTextContent('15')
      expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent('3')
      expect(getByTestId('rubric-locations-1')).toHaveTextContent('courses and assignments')

      expect(getByTestId('rubric-title-1')).toHaveTextContent('Rubric 3')
      expect(getByTestId('rubric-points-1')).toHaveTextContent('15')
      expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent('3')
      expect(getByTestId('rubric-locations-1')).toHaveTextContent('courses and assignments')

      const archivedRubricsTab = getByText('Archived')
      archivedRubricsTab.click()

      expect(getByTestId('archived-rubrics-table').querySelectorAll('tr').length).toEqual(2)

      expect(getByTestId('rubric-title-0')).toHaveTextContent('Rubric 2')
      expect(getByTestId('rubric-points-0')).toHaveTextContent('10')
      expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent('2')
      expect(getByTestId('rubric-locations-0')).toHaveTextContent('-')
    })

    it('renders a popover menu with access to the rubric edit modal', () => {
      const mockNavigate = jest.fn()
      jest.spyOn(Router, 'useNavigate').mockReturnValue(mockNavigate)

      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const editButton = getByTestId('edit-rubric-button')
      editButton.click()

      expect(Router.useNavigate).toHaveBeenCalledWith()
      expect(Router.useNavigate).toHaveReturnedWith(expect.any(Function))
    })

    it('renders a popover menu with access to the rubric duplicate modal', () => {
      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const duplicateButton = getByTestId('duplicate-rubric-button')
      duplicateButton.click()

      expect(getByTestId('duplicate-rubric-modal')).toBeInTheDocument()
    })

    it('renders a popover menu with access to the rubric delete modal', () => {
      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      const popover = getByTestId('rubric-options-1-button')
      popover.click()
      const deleteButton = getByTestId('delete-rubric-button')
      deleteButton.click()

      expect(getByTestId('delete-rubric-modal')).toBeInTheDocument()
    })

    it('disables the delete option in the popover menu if the rubric has rubric associations active', () => {
      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId} = renderComponent()

      getByTestId('rubric-options-1-button').click()
      expect(getByTestId('delete-rubric-button')).not.toHaveAttribute('aria-disabled')
      getByTestId('rubric-options-1-button').click()

      getByTestId('rubric-options-3-button').click()
      expect(getByTestId('delete-rubric-button')).toHaveAttribute('aria-disabled', 'true')
    })

    describe('sorting', () => {
      it('sorts rubrics by Rubric Name in ascending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const rubricNameHeader = getByText('Rubric Name')
        fireEvent.click(rubricNameHeader)

        const sortedRubricNames = ['Rubric 1', 'Rubric 3']
        expect(getByTestId('rubric-title-0')).toHaveTextContent(sortedRubricNames[0])
        expect(getByTestId('rubric-title-1')).toHaveTextContent(sortedRubricNames[1])
      })

      it('sorts rubrics by Rubric Name in descending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const rubricNameHeader = getByText('Rubric Name')
        fireEvent.click(rubricNameHeader)
        fireEvent.click(rubricNameHeader)
        fireEvent.click(rubricNameHeader)

        const sortedRubricNames = ['Rubric 3', 'Rubric 1']
        expect(getByTestId('rubric-title-0')).toHaveTextContent(sortedRubricNames[1])
        expect(getByTestId('rubric-title-1')).toHaveTextContent(sortedRubricNames[0])
      })

      it('sorts rubrics by Total Points in ascending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const totalPointsHeader = getByText('Total Points')
        fireEvent.click(totalPointsHeader)

        const sortedTotalPoints = ['5', '15']
        expect(getByTestId('rubric-points-0')).toHaveTextContent(sortedTotalPoints[0])
        expect(getByTestId('rubric-points-1')).toHaveTextContent(sortedTotalPoints[1])
      })

      it('sorts rubrics by Total Points in descending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const totalPointsHeader = getByText('Total Points')
        fireEvent.click(totalPointsHeader)
        fireEvent.click(totalPointsHeader)

        const sortedTotalPoints = ['15', '5']
        expect(getByTestId('rubric-points-0')).toHaveTextContent(sortedTotalPoints[0])
        expect(getByTestId('rubric-points-1')).toHaveTextContent(sortedTotalPoints[1])
      })

      it('sorts rubrics by Criterion count in ascending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const criterionHeader = getByText('Criterion')
        fireEvent.click(criterionHeader)

        const sortedCriterion = ['1', '3']
        expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent(sortedCriterion[0])
        expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent(sortedCriterion[1])
      })

      it('sorts rubrics by Criterion count in descending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const criterionHeader = getByText('Criterion')
        fireEvent.click(criterionHeader)
        fireEvent.click(criterionHeader)
        fireEvent.click(criterionHeader)

        const sortedCriterion = ['3', '1']
        expect(getByTestId('rubric-criterion-count-0')).toHaveTextContent(sortedCriterion[1])
        expect(getByTestId('rubric-criterion-count-1')).toHaveTextContent(sortedCriterion[0])
      })

      it('sorts rubrics by Location Used in ascending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const locationUsedHeader = getByText('Location Used')
        fireEvent.click(locationUsedHeader)

        const sortedLocations = ['courses and assignments', '-']
        expect(getByTestId('rubric-locations-0')).toHaveTextContent(sortedLocations[0])
        expect(getByTestId('rubric-locations-1')).toHaveTextContent(sortedLocations[1])
      })

      it('sorts rubrics by Location Used in descending order', () => {
        queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText} = renderComponent()

        const locationUsedHeader = getByText('Location Used')
        fireEvent.click(locationUsedHeader)
        fireEvent.click(locationUsedHeader)

        const sortedLocations = ['-', 'courses and assignments']
        expect(getByTestId('rubric-locations-0')).toHaveTextContent(sortedLocations[0])
        expect(getByTestId('rubric-locations-1')).toHaveTextContent(sortedLocations[1])
      })
    })
  })

  describe('preview tray', () => {
    beforeAll(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
    })

    const getPreviewTray = () => {
      return document.querySelector('[role="dialog"][aria-label="Rubric Assessment Tray"]')
    }

    queryClient.setQueryData(['accountRubrics-1'], RUBRICS_QUERY_RESPONSE)
    queryClient.setQueryData(['rubric-preview-1'], RUBRIC_PREVIEW_QUERY_RESPONSE)

    it('opens the preview tray when a rubric is clicked', () => {
      const {getByTestId} = renderComponent()

      const previewCell = getByTestId('rubric-title-preview-1')
      previewCell.click()

      expect(getPreviewTray()).toBeInTheDocument()
      expect(getByTestId('traditional-criterion-1-ratings-0')).toBeInTheDocument()
    })

    it('closes the preview tray when the same rubric is clicked again', async () => {
      const {getByTestId} = renderComponent()

      const previewCell = getByTestId('rubric-title-preview-1')
      previewCell.click()
      expect(getByTestId('traditional-criterion-1-ratings-0')).toBeInTheDocument()

      previewCell.click()
      await waitFor(() => expect(getPreviewTray()).not.toBeInTheDocument())
    })

    it('filters rubrics based on search query at course level', () => {
      queryClient.setQueryData(['courseRubrics-1'], RUBRICS_QUERY_RESPONSE)
      const {getByTestId, queryByText} = renderComponent()

      expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toBe(3)

      const searchInput = getByTestId('rubric-search-bar')
      fireEvent.change(searchInput, {target: {value: '1'}})

      expect(getByTestId('saved-rubrics-panel').querySelectorAll('tr').length).toBe(2)
      expect(queryByText('Rubric 1')).not.toBeNull()
      expect(queryByText('Rubric 2')).toBeNull()
      expect(queryByText('Rubric 3')).toBeNull()
    })
  })
})
