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
import {fireEvent, render} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'

jest.mock('../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../queries/RubricFormQueries'),
  saveRubric: jest.fn(),
  generateCriteria: jest.fn(),
}))

jest.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: jest.fn(),
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
          },
        }),
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
      expect(getSRAlert()).toContain('Rubric saved successfully')
    })
  })
})
