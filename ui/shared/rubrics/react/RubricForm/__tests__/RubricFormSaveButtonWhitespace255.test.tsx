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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('../queries/RubricFormQueries', async () => ({
  ...(await vi.importActual('../queries/RubricFormQueries')),
  saveRubric: vi.fn(),
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

/**
 * Test for save button validation with 255 whitespace characters.
 * Split from RubricFormSaveButtonWithCriteria.test.tsx to avoid CI timeouts.
 */
describe('RubricForm Save Button - 255 Whitespace Validation', () => {
  beforeEach(() => {
    fakeEnv.setup({
      context_asset_string: 'user_1',
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

  const addCriterionToRubric = async (getByTestId: ReturnType<typeof render>['getByTestId']) => {
    fireEvent.click(getByTestId('add-criterion-button'))
    await waitFor(() => {
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
    })
    fireEvent.change(getByTestId('rubric-criterion-name-input'), {
      target: {value: 'New Criterion Test'},
    })
    fireEvent.click(getByTestId('rubric-criterion-save'))
  }

  it('save button is disabled when title is 255 whitespace even with criteria', async () => {
    const {getByTestId} = renderComponent()
    const titleInput = getByTestId('rubric-form-title')
    fireEvent.change(titleInput, {
      target: {
        value:
          '                                                                                                                                                                                                                                                               ',
      },
    })

    await addCriterionToRubric(getByTestId)

    await waitFor(() => {
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })
  })
})
