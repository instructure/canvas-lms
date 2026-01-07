/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import {OutcomeManagementWithoutGraphql as OutcomeManagement} from '../OutcomeManagement'
import {outcomeGroupsMocks} from '@canvas/outcomes/mocks/Outcomes'
import {createCache} from '@canvas/apollo-v3'
import {
  showOutcomesImporter,
  showOutcomesImporterIfInProgress,
} from '@canvas/outcomes/react/OutcomesImporter'

vi.mock('@canvas/outcomes/react/OutcomesImporter', () => ({
  showOutcomesImporter: vi.fn(() => vi.fn(() => {})),
  showOutcomesImporterIfInProgress: vi.fn(() => vi.fn(() => {})),
}))

describe('OutcomeManagement', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
  })

  const sharedExamples = () => {
    beforeEach(() => {
      window.ENV.ACCOUNT_LEVEL_MASTERY_SCALES = true
      window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = true
    })

    it('renders the OutcomeManagement and shows the "outcomes" div', () => {
      delete window.ENV.IMPROVED_OUTCOMES_MANAGEMENT
      document.body.innerHTML = '<div id="outcomes" style="display:none">Outcomes Tab</div>'
      render(<OutcomeManagement />)
      expect(document.getElementById('outcomes').style.display).toBe('block')
    })

    it('does not render ManagementHeader', () => {
      delete window.ENV.IMPROVED_OUTCOMES_MANAGEMENT
      const {queryByTestId} = render(<OutcomeManagement />)
      expect(queryByTestId('managementHeader')).not.toBeInTheDocument()
    })

    it('renders ManagementHeader when improved outcomes enabled', async () => {
      const {getByText, getByTestId} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>,
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => vi.runAllTimers())
      expect(getByTestId('managementHeader')).toBeInTheDocument()
    })

    it('calls showImportOutcomesModal after a file is uploaded', async () => {
      window.ENV.PERMISSIONS.manage_outcomes = true
      window.ENV.PERMISSIONS.import_outcomes = true
      const file = new File(['1,2,3'], 'file.csv', {type: 'text/csv'})
      const {getByText, getByLabelText} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>,
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => vi.runAllTimers())
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Import'))
      const fileDrop = getByLabelText(/Upload your Outcomes!/i)
      // Source: https://github.com/testing-library/react-testing-library/issues/93#issuecomment-403887769
      Object.defineProperty(fileDrop, 'files', {
        value: [file],
      })
      fireEvent.change(fileDrop)
      expect(showOutcomesImporter).toHaveBeenCalled()
    })

    it('checks for existing outcome imports when the user switches to the manage tab and renders the OutcomeManagementPanel', async () => {
      const {getByText, getByTestId} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks, ...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>,
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => vi.runAllTimers())
      expect(showOutcomesImporterIfInProgress).toHaveBeenCalledTimes(1)
      expect(showOutcomesImporterIfInProgress).toHaveBeenCalledWith(
        {
          disableOutcomeViews: expect.any(Function),
          resetOutcomeViews: expect.any(Function),
          mount: expect.any(Element),
          contextUrlRoot: ENV.CONTEXT_URL_ROOT,
          learningOutcomeGroupId: null,
          onSuccessfulCreateOutcome: expect.any(Function),
        },
        '1',
      )
      fireEvent.click(getByText('Calculation'))
      fireEvent.click(getByText('Manage'))
      expect(showOutcomesImporterIfInProgress).toHaveBeenCalledTimes(2)
      await act(async () => vi.runAllTimers())
      expect(getByTestId('outcomeManagementPanel')).toBeInTheDocument()
    })

    it('does not render OutcomeManagementPanel', () => {
      delete window.ENV.IMPROVED_OUTCOMES_MANAGEMENT
      const {queryByTestId} = render(<OutcomeManagement />)
      expect(queryByTestId('outcomeManagementPanel')).not.toBeInTheDocument()
    })

    it('renders Manage, Mastery and Calculation tabs when Account Level Mastery Scales FF is enabled', async () => {
      const {getByText} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>,
      )
      await act(async () => vi.runAllTimers())
      expect(getByText('Manage')).toBeInTheDocument()
      expect(getByText('Mastery')).toBeInTheDocument()
      expect(getByText('Calculation')).toBeInTheDocument()
    })

    it('renders only Manage tab when Account Level Mastery Scales FF is disabled', async () => {
      window.ENV.ACCOUNT_LEVEL_MASTERY_SCALES = false
      const {getByText, queryByText} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>,
      )
      await act(async () => vi.runAllTimers())
      expect(getByText('Manage')).toBeInTheDocument()
      expect(queryByText('Mastery')).not.toBeInTheDocument()
      expect(queryByText('Calculation')).not.toBeInTheDocument()
    })
  }

  const courseOnlyTests = () => {
    beforeEach(() => {
      window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = true
      window.ENV.PERMISSIONS.manage_outcomes = true
    })

    describe('Outcome Alignment Summary Tab', () => {
      describe('when Improved Outcomes Management FF is enabled', () => {
        it('renders Aligments tab if Alignment Summary FF is enabled and user has permissions', async () => {
          const {getByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>,
          )
          await act(async () => vi.runAllTimers())
          expect(getByText('Alignments')).toBeInTheDocument()
        })

        it('does not render Aligments tab if Alignment Summary FF is enabled but user does not have permissions', async () => {
          window.ENV.PERMISSIONS.manage_outcomes = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>,
          )
          await act(async () => vi.runAllTimers())
          expect(queryByText('Alignments')).not.toBeInTheDocument()
        })

        it('does not render Alignments tab if Improved Outcomes Management FF is disabled even if user has permissions', async () => {
          window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>,
          )
          await act(async () => vi.runAllTimers())
          expect(queryByText('Alignments')).not.toBeInTheDocument()
        })
      })

      describe('when Improved Outcomes Management FF is disabled', () => {
        it('does not render Aligments tab', async () => {
          window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>,
          )
          await act(async () => vi.runAllTimers())
          expect(queryByText('Alignments')).not.toBeInTheDocument()
        })
      })
    })
  }

  const accountOnlyTests = () => {
    describe('Outcome Alignment Summary', () => {
      it('does not render Aligments Summary tab in account context', async () => {
        window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = true
        window.ENV.PERMISSIONS.manage_outcomes = true
        const {queryByText} = render(
          <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
            <OutcomeManagement />
          </MockedProvider>,
        )
        await act(async () => vi.runAllTimers())
        expect(queryByText('Alignments')).not.toBeInTheDocument()
      })
    })
  }

  describe('account', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'account_11',
        CONTEXT_URL_ROOT: '/account/11',
        PERMISSIONS: {
          manage_proficiency_calculations: true,
        },
        current_user: {id: '1'},
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()
    accountOnlyTests()
  })

  describe('course', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'course_12',
        CONTEXT_URL_ROOT: '/course/12',
        PERMISSIONS: {
          manage_proficiency_calculations: true,
        },
        current_user: {id: '1'},
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()
    courseOnlyTests()
  })
})
