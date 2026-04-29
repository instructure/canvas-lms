/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'

vi.mock('../queries/RubricFormQueries', async importOriginal => {
  const actual = await importOriginal<typeof import('../queries/RubricFormQueries')>()
  return {
    ...actual,
    saveRubric: vi.fn(),
  }
})

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

describe('RubricForm canUseForGrading integration', () => {
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
          assignmentId="1"
          {...props}
        />
      </MockedQueryProvider>,
    )
  }

  it('renders "Use this rubric for assignment grading" checkbox by default when showAdditionalOptions is true and assignmentId is provided', () => {
    renderComponent()

    expect(screen.getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
  })

  it('renders "Use this rubric for assignment grading" checkbox when canUseForGrading is explicitly set to true', () => {
    renderComponent({canUseForGrading: true})

    expect(screen.getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
  })

  it('does not render "Use this rubric for assignment grading" checkbox when canUseForGrading is false', () => {
    renderComponent({canUseForGrading: false})

    expect(screen.queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
  })

  it('still renders "Hide rubric score total from students" checkbox when canUseForGrading is false', () => {
    renderComponent({canUseForGrading: false})

    expect(screen.getByTestId('hide-score-total-checkbox')).toBeInTheDocument()
  })

  it('does not render RubricAssignmentSettings component when showAdditionalOptions is false', () => {
    renderComponent({showAdditionalOptions: false})

    expect(screen.queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hide-outcome-results-checkbox')).not.toBeInTheDocument()
  })

  it('does not render RubricAssignmentSettings component when assignmentId is not provided', () => {
    renderComponent({assignmentId: undefined, showAdditionalOptions: true})

    expect(screen.queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hide-outcome-results-checkbox')).not.toBeInTheDocument()
  })

  it('renders all checkboxes when canUseForGrading is true and all conditions are met', () => {
    renderComponent({
      canUseForGrading: true,
      showAdditionalOptions: true,
      assignmentId: '1',
    })

    expect(screen.getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
    expect(screen.getByTestId('hide-score-total-checkbox')).toBeInTheDocument()
    expect(screen.getByTestId('hide-outcome-results-checkbox')).toBeInTheDocument()
  })
})
