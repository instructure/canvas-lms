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
import {render, fireEvent, act, within} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {
  OutcomePanel,
  OutcomeManagementWithoutGraphql as OutcomeManagement,
} from '../OutcomeManagement'
import {
  masteryCalculationGraphqlMocks,
  masteryScalesGraphqlMocks,
  outcomeGroupsMocks,
} from '@canvas/outcomes/mocks/Outcomes'
import {createCache} from '@canvas/apollo'
import {showOutcomesImporter, showOutcomesImporterIfInProgress} from '@canvas/outcomes/react/OutcomesImporter'
import {courseMocks, groupDetailMocks, groupMocks} from '@canvas/outcomes/mocks/Management'

jest.mock('@canvas/outcomes/react/OutcomesImporter', () => ({
  showOutcomesImporter: jest.fn(() => jest.fn(() => {})),
  showOutcomesImporterIfInProgress: jest.fn(() => jest.fn(() => {})),
}))

describe('OutcomeManagement', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.useRealTimers()
  })

  /*
    This test takes an average of 5.5 seconds to run.
    For now, we are increaseing the timeout interval to 7.5 seconds
  */
  it('renders ManagementHeader with lhsGroupId if selected a group in lhs', async () => {
    const rceEnv = {
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      RICH_CONTENT_APP_HOST: 'rce-host',
      JWT: 'test-jwt',
      current_user_id: '1',
    }
    window.ENV = {
      context_asset_string: 'course_2',
      CONTEXT_URL_ROOT: '/course/2',
      IMPROVED_OUTCOMES_MANAGEMENT: true,
      PERMISSIONS: {
        manage_proficiency_calculations: true,
        manage_outcomes: true,
      },
      current_user: {id: '1'},
      ...rceEnv,
    }
    const mocks = [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({
        title: 'Course folder 0',
        groupId: '200',
        parentOutcomeGroupTitle: 'Root course folder',
        parentOutcomeGroupId: '2',
      }),
      ...groupDetailMocks({
        title: 'Course folder 0',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
      ...groupMocks({
        groupId: '300',
        childGroupOffset: 400,
        parentOutcomeGroupTitle: 'Course folder 0',
        parentOutcomeGroupId: '200',
      }),
      ...groupDetailMocks({
        groupId: '300',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]
    const {findByText, findByTestId, getByTestId} = render(
      <MockedProvider cache={cache} mocks={mocks}>
        <OutcomeManagement breakpoints={{tablet: true}} />
      </MockedProvider>
    )
    jest.runAllTimers()

    // Select a group in the lsh
    const cf0 = await findByText('Course folder 0')
    fireEvent.click(cf0)
    jest.runAllTimers()

    // The easy way to determine if lsh is passing to ManagementHeader is
    // to open the create outcome modal and check if the lhs group was loaded
    // by checking if the child of the lhs group is there
    fireEvent.click(within(getByTestId('managementHeader')).getByText('Create'))
    jest.runAllTimers()
    // there's something weird going on in the test here that while we find the modal
    // .toBeInTheDocument() fails, even though a findBy for it fails before ^that click.
    // We can test that the elements expected to be within it exist.
    const modal = await findByTestId('createOutcomeModal')
    expect(within(modal).getByText('Course folder 0')).not.toBeNull()
    expect(within(modal).getByText('Group 200 folder 0')).not.toBeNull()
  }, 7500)  // Increase time to 7.5 seconds

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
        </MockedProvider>
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => jest.runAllTimers())
      expect(getByTestId('managementHeader')).toBeInTheDocument()
    })

    it('calls showImportOutcomesModal after a file is uploaded', async () => {
      window.ENV.PERMISSIONS.manage_outcomes = true
      window.ENV.PERMISSIONS.import_outcomes = true
      const file = new File(['1,2,3'], 'file.csv', {type: 'text/csv'})
      const {getByText, getByLabelText} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => jest.runAllTimers())
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
        </MockedProvider>
      )
      expect(getByText(/^Loading$/)).toBeInTheDocument() // spinner
      await act(async () => jest.runAllTimers())
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
        '1'
      )
      fireEvent.click(getByText('Calculation'))
      fireEvent.click(getByText('Manage'))
      expect(showOutcomesImporterIfInProgress).toHaveBeenCalledTimes(2)
      await act(async () => jest.runAllTimers())
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
        </MockedProvider>
      )
      await act(async () => jest.runAllTimers())
      expect(getByText('Manage')).toBeInTheDocument()
      expect(getByText('Mastery')).toBeInTheDocument()
      expect(getByText('Calculation')).toBeInTheDocument()
    })

    it('renders only Manage tab when Account Level Mastery Scales FF is disabled', async () => {
      window.ENV.ACCOUNT_LEVEL_MASTERY_SCALES = false
      const {getByText, queryByText} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>
      )
      await act(async () => jest.runAllTimers())
      expect(getByText('Manage')).toBeInTheDocument()
      expect(queryByText('Mastery')).not.toBeInTheDocument()
      expect(queryByText('Calculation')).not.toBeInTheDocument()
    })

    describe('Changes confirmation', () => {
      let originalConfirm, originalAddEventListener, unloadEventListener

      beforeAll(() => {
        originalConfirm = window.confirm
        originalAddEventListener = window.addEventListener
        window.confirm = jest.fn(() => true)
        window.addEventListener = (eventName, callback) => {
          if (eventName === 'beforeunload') {
            unloadEventListener = callback
          }
        }
      })

      afterAll(() => {
        window.confirm = originalConfirm
        window.addEventListener = originalAddEventListener
        unloadEventListener = null
      })

      it("Doesn't ask to confirm tab change when there is not change", () => {
        const {getByText} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Mastery'))
        fireEvent.click(getByText('Calculation'))

        expect(window.confirm).not.toHaveBeenCalled()
      })

      it('Asks to confirm tab change when there is changes', async () => {
        const {getByText, getByLabelText, getByTestId} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Calculation'))
        await act(async () => jest.runAllTimers())
        fireEvent.input(getByLabelText('Parameter'), {target: {value: ''}})
        fireEvent.click(getByText('Mastery'))
        await act(async () => jest.runAllTimers())
        expect(window.confirm).toHaveBeenCalled()
        expect(getByTestId('masteryScales')).toBeInTheDocument()
      })

      it("Doesn't change tabs when doesn't confirm", async () => {
        // mock decline from user
        window.confirm = () => false

        const {getByText, getByLabelText, queryByTestId} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Calculation'))
        await act(async () => jest.runAllTimers())
        fireEvent.input(getByLabelText('Parameter'), {target: {value: ''}})
        fireEvent.click(getByText('Mastery'))
        expect(queryByTestId('masteryScales')).not.toBeInTheDocument()
      })

      it("Allows to leave page when doesn't have changes", async () => {
        const {getByText} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        const calculationButton = getByText('Calculation')
        fireEvent.click(calculationButton)

        await act(async () => jest.runAllTimers())

        const e = jest.mock()
        e.preventDefault = jest.fn()
        unloadEventListener(e)
        expect(e.preventDefault).not.toHaveBeenCalled()
      })

      it("Doesn't Allow to leave page when has changes", async () => {
        const {getByText, getByLabelText} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        const calculationButton = getByText('Calculation')
        fireEvent.click(calculationButton)

        await act(async () => jest.runAllTimers())

        const parameter = getByLabelText(/Parameter/)
        fireEvent.input(parameter, {target: {value: '88'}})

        const e = jest.mock()
        e.preventDefault = jest.fn()
        unloadEventListener(e)
        expect(e.preventDefault).toHaveBeenCalled()
      })
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
            </MockedProvider>
          )
          await act(async () => jest.runAllTimers())
          expect(getByText('Alignments')).toBeInTheDocument()
        })

        it('does not render Aligments tab if Alignment Summary FF is enabled but user does not have permissions', async () => {
          window.ENV.PERMISSIONS.manage_outcomes = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>
          )
          await act(async () => jest.runAllTimers())
          expect(queryByText('Alignments')).not.toBeInTheDocument()
        })

        it('does not render Alignments tab if Improved Outcomes Management FF is disabled even if user has permissions', async () => {
          window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>
          )
          await act(async () => jest.runAllTimers())
          expect(queryByText('Alignments')).not.toBeInTheDocument()
        })
      })

      describe('when Improved Outcomes Management FF is disabled', () => {
        it('does not render Aligments tab', async () => {
          window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = false
          const {queryByText} = render(
            <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
              <OutcomeManagement />
            </MockedProvider>
          )
          await act(async () => jest.runAllTimers())
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
          </MockedProvider>
        )
        await act(async () => jest.runAllTimers())
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

describe('OutcomePanel', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="outcomes" style="display:none">Outcomes Tab</div>'
    jest.useFakeTimers()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('sets style on mount', () => {
    render(<OutcomePanel />)
    jest.runAllTimers()
    expect(document.getElementById('outcomes').style.display).toEqual('block')
  })

  it('sets style on unmount', () => {
    const {unmount} = render(<OutcomePanel />)
    unmount()
    jest.runAllTimers()
    expect(document.getElementById('outcomes').style.display).toEqual('none')
  })
})
