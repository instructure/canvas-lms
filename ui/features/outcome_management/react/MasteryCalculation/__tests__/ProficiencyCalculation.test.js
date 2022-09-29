/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render as rtlRender, fireEvent, waitFor, within} from '@testing-library/react'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import ProficiencyCalculation from '../ProficiencyCalculation'

describe('ProficiencyCalculation', () => {
  let originalOnError
  beforeEach(() => {
    // working around a bug in instui's SimpleSelect
    originalOnError = global.onerror
    global.onerror = (message, file, _line, _col, error) => {
      if (
        error instanceof ReferenceError &&
        file.match(/SimpleSelect/) &&
        message.match(/event is not defined/)
      ) {
        return true
      }
      return false
    }
  })

  afterEach(() => {
    global.onerror = originalOnError
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '1', outcomeAllowAverageCalculationFF = false} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider
        value={{env: {contextType, contextId, outcomeAllowAverageCalculationFF}}}
      >
        {children}
      </OutcomesContext.Provider>
    )
  }

  const makeProps = (overrides = {}) => ({
    update: Function.prototype,
    canManage: true,
    masteryPoints: null,
    ...overrides,
    method: {
      calculationMethod: 'decaying_average',
      calculationInt: 75,
      ...(overrides.method || {}),
    },
  })

  describe('locked', () => {
    it('renders method and int', () => {
      const {getByText} = render(<ProficiencyCalculation {...makeProps({canManage: false})} />)
      expect(getByText('Decaying Average')).not.toBeNull()
      expect(getByText('75')).not.toBeNull()
    })

    it('renders method without int', () => {
      const {getByText, queryByText} = render(
        <ProficiencyCalculation
          {...makeProps({
            canManage: false,
            method: {calculationMethod: 'latest', calculationInt: null},
          })}
        />
      )
      expect(getByText('Most Recent Score')).not.toBeNull()
      expect(queryByText('Parameter')).toBeNull()
    })

    it('renders example', () => {
      const {getByText} = render(
        <ProficiencyCalculation
          {...makeProps({
            canManage: false,
          })}
        />
      )
      expect(getByText('Example')).not.toBeNull()
      expect(getByText(/Most recent result counts as/)).not.toBeNull()
      expect(getByText('Item Scores:')).toBeInTheDocument()
      expect(getByText('Final Score:')).toBeInTheDocument()
    })

    it('renders alternate example', () => {
      const {getByText} = render(
        <ProficiencyCalculation
          {...makeProps({
            canManage: false,
            method: {calculationMethod: 'latest', calculationInt: null},
          })}
        />
      )
      expect(getByText('Example')).not.toBeNull()
      expect(getByText(/most recent graded/)).not.toBeNull()
      expect(getByText('Item Scores:')).toBeInTheDocument()
      expect(getByText('Final Score:')).toBeInTheDocument()
    })

    it('does not render the save button', () => {
      const {queryByText} = render(<ProficiencyCalculation {...makeProps({canManage: false})} />)
      expect(queryByText(/Save Mastery Calculation/)).not.toBeInTheDocument()
    })
  })

  describe('unlocked', () => {
    it('renders method and int', () => {
      const {getByDisplayValue} = render(<ProficiencyCalculation {...makeProps()} />)
      expect(getByDisplayValue('Decaying Average')).not.toBeNull()
      expect(getByDisplayValue('75')).not.toBeNull()
    })

    it('renders method without int', () => {
      const {getByDisplayValue, queryByText} = render(
        <ProficiencyCalculation
          {...makeProps({
            method: {calculationMethod: 'latest', calculationInt: null},
          })}
        />
      )
      expect(getByDisplayValue('Most Recent Score')).not.toBeNull()
      expect(queryByText('Parameter')).toBeNull()
    })

    it('removes int when method changed', async () => {
      const {getByDisplayValue, getByText, queryByText} = render(
        <ProficiencyCalculation {...makeProps()} />
      )
      const method = getByDisplayValue('Decaying Average')
      fireEvent.click(method)
      const newMethod = getByText('Most Recent Score')
      fireEvent.click(newMethod)
      expect(getByDisplayValue('Most Recent Score')).not.toBeNull()
      expect(queryByText('Parameter')).toBeNull()
    })

    it('updates int when method changed', async () => {
      const {getByDisplayValue, getByText} = render(<ProficiencyCalculation {...makeProps()} />)
      const method = getByDisplayValue('Decaying Average')
      fireEvent.click(method)
      const newMethod = getByText('n Number of Times')
      fireEvent.click(newMethod)
      expect(getByDisplayValue('5')).not.toBeNull()
    })

    it('calls save when the button is clicked', () => {
      const update = jest.fn()
      const {getByText, getByLabelText} = render(
        <ProficiencyCalculation {...makeProps({update})} />
      )
      const parameter = getByLabelText('Parameter')
      fireEvent.input(parameter, {target: {value: '22'}})
      fireEvent.input(parameter, {target: {value: '40'}})
      fireEvent.input(parameter, {target: {value: '44'}})
      fireEvent.input(parameter, {target: {value: '41'}})
      fireEvent.click(getByText('Save Mastery Calculation'))
      fireEvent.click(getByText('Save'))
      expect(update).toHaveBeenCalledTimes(1)
      expect(update).toHaveBeenCalledWith('decaying_average', 41)
    })

    it('calls onNotifyPendingChanges when changes data', async () => {
      const onNotifyPendingChangesSpy = jest.fn()
      const {getByText, getByLabelText} = render(
        <ProficiencyCalculation
          {...makeProps({onNotifyPendingChanges: onNotifyPendingChangesSpy})}
        />
      )
      const parameter = getByLabelText('Parameter')
      fireEvent.input(parameter, {target: {value: '22'}})
      expect(onNotifyPendingChangesSpy).toHaveBeenCalledWith(true)
      onNotifyPendingChangesSpy.mockClear()
      fireEvent.click(getByText('Save Mastery Calculation'))
      fireEvent.click(getByText('Save'))
      expect(onNotifyPendingChangesSpy).toHaveBeenCalledWith(false)
    })

    it('save button is initially disabled', () => {
      const {getByText} = render(<ProficiencyCalculation {...makeProps()} />)
      expect(getByText('Save Mastery Calculation').closest('button').disabled).toEqual(true)
    })

    it('save button geos back to disabled if changes are reverted', () => {
      const {getByText, getByLabelText} = render(<ProficiencyCalculation {...makeProps()} />)
      const parameter = getByLabelText('Parameter')
      fireEvent.input(parameter, {target: {value: '22'}})
      expect(getByText('Save Mastery Calculation').closest('button').disabled).toEqual(false)
      fireEvent.input(parameter, {target: {value: '75'}})
      expect(getByText('Save Mastery Calculation').closest('button').disabled).toEqual(true)
    })

    describe('highest', () => {
      it('calls update with the correct arguments', () => {
        const update = jest.fn()
        const {getByDisplayValue, getByText} = render(
          <ProficiencyCalculation {...makeProps({update})} />
        )
        const method = getByDisplayValue('Decaying Average')
        fireEvent.click(method)
        const newMethod = getByText('Highest Score')
        fireEvent.click(newMethod)
        fireEvent.click(getByText('Save Mastery Calculation'))
        fireEvent.click(getByText('Save'))
        expect(update).toHaveBeenCalledWith('highest', null)
      })
    })

    describe('latest', () => {
      it('calls update with the correct arguments', () => {
        const update = jest.fn()
        const {getByDisplayValue, getByText} = render(
          <ProficiencyCalculation {...makeProps({update})} />
        )
        const method = getByDisplayValue('Decaying Average')
        fireEvent.click(method)
        const newMethod = getByText('Most Recent Score')
        fireEvent.click(newMethod)
        fireEvent.click(getByText('Save Mastery Calculation'))
        fireEvent.click(getByText('Save'))
        expect(update).toHaveBeenCalledWith('latest', null)
      })
    })

    describe('average', () => {
      it('calls update with the correct arguments', () => {
        window.ENV.OUTCOME_AVERAGE_CALCULATION = true
        const update = jest.fn()
        const {getByDisplayValue, getByText} = render(
          <ProficiencyCalculation {...makeProps({update})} />,
          {
            outcomeAllowAverageCalculationFF: true,
          }
        )
        const method = getByDisplayValue('Decaying Average')
        fireEvent.click(method)
        const newMethod = getByText('Average')
        fireEvent.click(newMethod)
        fireEvent.click(getByText('Save Mastery Calculation'))
        fireEvent.click(getByText('Save'))
        expect(update).toHaveBeenCalledWith('average', null)
      })
    })

    describe('decaying_average', () => {
      it('includes error when int invalid', () => {
        const {getByLabelText, getByText} = render(<ProficiencyCalculation {...makeProps()} />)
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: ''}})
        expect(getByText('Must be a number')).not.toBeNull()
      })

      it('includes error when int too high', () => {
        const {getByLabelText, getByText} = render(<ProficiencyCalculation {...makeProps()} />)
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '199'}})
        expect(getByText('Must be between 1 and 99')).not.toBeNull()
      })

      it('includes error when int too low', () => {
        const {getByLabelText, getByText} = render(<ProficiencyCalculation {...makeProps()} />)
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '0'}})
        expect(getByText('Must be between 1 and 99')).not.toBeNull()
      })

      it('renders the confirmation modal only when int is valid', async () => {
        const update = jest.fn()
        const {getByText, queryByText, getByLabelText} = render(
          <ProficiencyCalculation {...makeProps({update})} />
        )
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '0'}})
        fireEvent.click(getByText('Save Mastery Calculation'))
        expect(queryByText('Save')).not.toBeInTheDocument()
        fireEvent.input(parameter, {target: {value: '40'}})
        fireEvent.click(getByText('Save Mastery Calculation'))
        fireEvent.click(getByText('Save'))
        await waitFor(() => {
          expect(update).toHaveBeenCalledTimes(1)
          expect(update).toHaveBeenCalledWith('decaying_average', 40)
        })
      })
    })

    describe('n_mastery', () => {
      it('includes error when int invalid', () => {
        const {getByLabelText, getByText} = render(
          <ProficiencyCalculation
            {...makeProps({method: {calculationMethod: 'n_mastery', calculationInt: 5}})}
          />
        )
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: ''}})
        expect(getByText('Must be a number')).not.toBeNull()
      })

      it('includes error when int too high', () => {
        const {getByLabelText, getByText} = render(
          <ProficiencyCalculation
            {...makeProps({method: {calculationMethod: 'n_mastery', calculationInt: 5}})}
          />
        )
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '13'}})
        expect(getByText('Must be between 1 and 10')).not.toBeNull()
      })

      it('includes error when int too low', () => {
        const {getByLabelText, getByText} = render(
          <ProficiencyCalculation
            {...makeProps({method: {calculationMethod: 'n_mastery', calculationInt: 5}})}
          />
        )
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '0'}})
        expect(getByText('Must be between 1 and 10')).not.toBeNull()
      })

      it('renders the confirmation modal only when int is valid', async () => {
        const update = jest.fn()
        const {getByText, queryByText, getByLabelText} = render(
          <ProficiencyCalculation
            {...makeProps({update, method: {calculationMethod: 'n_mastery', calculationInt: 5}})}
          />
        )
        const parameter = getByLabelText('Parameter')
        fireEvent.input(parameter, {target: {value: '11'}})
        fireEvent.input(parameter, {target: {value: '16'}})
        fireEvent.click(getByText('Save Mastery Calculation'))
        expect(queryByText('Save')).not.toBeInTheDocument()
        fireEvent.input(parameter, {target: {value: '3'}})
        fireEvent.click(getByText('Save Mastery Calculation'))
        fireEvent.click(getByText('Save'))
        await waitFor(() => {
          expect(update).toHaveBeenCalledTimes(1)
          expect(update).toHaveBeenCalledWith('n_mastery', 3)
        })
      })
    })
  })

  describe('confirmation modal', () => {
    it('renders correct text for the Account context', () => {
      const {getByDisplayValue, getByText} = render(<ProficiencyCalculation {...makeProps()} />)
      const method = getByDisplayValue('Decaying Average')
      fireEvent.click(method)
      const newMethod = getByText('Most Recent Score')
      fireEvent.click(newMethod)
      fireEvent.click(getByText('Save Mastery Calculation'))
      expect(getByText(/Confirm Mastery Calculation/)).not.toBeNull()
      expect(
        getByText(/all student mastery results tied to the account level mastery calculation/)
      ).not.toBeNull()
    })

    it('renders correct text for the Course context', () => {
      const {getByDisplayValue, getByText} = render(<ProficiencyCalculation {...makeProps()} />, {
        contextType: 'Course',
      })
      const method = getByDisplayValue('Decaying Average')
      fireEvent.click(method)
      const newMethod = getByText('Most Recent Score')
      fireEvent.click(newMethod)
      fireEvent.click(getByText('Save Mastery Calculation'))
      expect(getByText(/Confirm Mastery Calculation/)).not.toBeNull()
      expect(getByText(/all student mastery results within this course/)).not.toBeNull()
    })
  })

  describe('when individualOutcome is "display" and canManage is false', () => {
    it('renders method and int', () => {
      const {getByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'display', canManage: false})} />
      )
      expect(getByText('Proficiency Calculation:')).toBeInTheDocument()
      expect(getByText('Decaying Average - 75%/25%')).toBeInTheDocument()
    })

    it('renders method without int', () => {
      const {getByText, queryByTestId} = render(
        <ProficiencyCalculation
          {...makeProps({
            individualOutcome: 'display',
            canManage: false,
            method: {calculationMethod: 'latest', calculationInt: null},
          })}
        />
      )
      expect(getByText('Most Recent Score')).toBeInTheDocument()
      expect(queryByTestId('calculation-int-input')).not.toBeInTheDocument()
    })

    it('does not render example', () => {
      const {queryByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'display', canManage: false})} />
      )
      expect(queryByText('Example')).not.toBeInTheDocument()
      expect(queryByText(/Most recent result counts as/)).not.toBeInTheDocument()
    })

    it('does not render the save button', () => {
      const {queryByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'display', canManage: false})} />
      )
      expect(queryByText(/Save Mastery Calculation/)).not.toBeInTheDocument()
    })
  })

  describe('when individualOutcome is "edit"', () => {
    it('renders method and int', () => {
      const {getByDisplayValue, queryByTestId, getByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit'})} />
      )

      expect(getByDisplayValue('Decaying Average')).toBeInTheDocument()
      expect(queryByTestId('calculation-int-input')).toBeInTheDocument()
      expect(getByText('% weighting for last item')).toBeInTheDocument()
      expect(getByText('must be between 1 and 99')).toBeInTheDocument()
    })

    it('renders method without int', () => {
      const {getByDisplayValue, queryByTestId} = render(
        <ProficiencyCalculation
          {...makeProps({
            individualOutcome: 'edit',
            method: {calculationMethod: 'latest', calculationInt: null},
          })}
        />
      )
      expect(getByDisplayValue('Most Recent Score')).toBeInTheDocument()
      expect(queryByTestId('calculation-int-input')).not.toBeInTheDocument()
    })

    it('clears int if changing from method with int to one without', () => {
      const update = jest.fn()
      const setError = jest.fn()
      const {getByText, getByDisplayValue} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit', update, setError})} />
      )
      fireEvent.click(getByDisplayValue('Decaying Average'))
      fireEvent.click(getByText('Most Recent Score'))
      expect(update).toHaveBeenCalledWith('latest', null)
    })

    describe('example', () => {
      it('renders example', () => {
        const {getByText, queryByText} = render(
          <ProficiencyCalculation {...makeProps({individualOutcome: 'edit'})} />
        )
        expect(queryByText('Example')).toBeInTheDocument()
        expect(getByText('Item Scores:')).toBeInTheDocument()
        expect(getByText('Final Score:')).toBeInTheDocument()
        expect(queryByText(/Most recent result counts as/)).toBeInTheDocument()
      })

      it('renders example with calculated final score when n_mastery method and mastery points provided', () => {
        const {getByTestId} = render(
          <ProficiencyCalculation
            {...makeProps({
              individualOutcome: 'edit',
              masteryPoints: 3,
              method: {
                calculationMethod: 'n_mastery',
                calculationInt: 5,
              },
            })}
          />
        )
        const exampleFinalScore = getByTestId('proficiency-calculation-example-final-score')
        expect(exampleFinalScore).toBeInTheDocument()
        expect(within(exampleFinalScore).getByText('4.2')).toBeInTheDocument()
      })

      it('renders example with N/A final score when n_mastery method and mastery points not provided', () => {
        const {getByTestId} = render(
          <ProficiencyCalculation
            {...makeProps({
              individualOutcome: 'edit',
              method: {
                calculationMethod: 'n_mastery',
                calculationInt: 5,
              },
            })}
          />
        )
        const exampleFinalScore = getByTestId('proficiency-calculation-example-final-score')
        expect(exampleFinalScore).toBeInTheDocument()
        expect(within(exampleFinalScore).getByText('N/A')).toBeInTheDocument()
      })

      it('renders example with a warning when average calculation method selected', () => {
        window.ENV.OUTCOME_AVERAGE_CALCULATION = true
        const update = jest.fn()
        const {getByDisplayValue, getByText} = render(
          <ProficiencyCalculation {...makeProps({update})} />,
          {
            outcomeAllowAverageCalculationFF: true,
          }
        )
        const method = getByDisplayValue('Decaying Average')
        fireEvent.click(method)
        const newMethod = getByText('Average')
        fireEvent.click(newMethod)
        expect(getByText('Warning')).toBeInTheDocument()
      })
    })

    it('does not render the save button', () => {
      const {queryByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit'})} />
      )
      expect(queryByText(/Save Mastery Calculation/)).not.toBeInTheDocument()
    })

    it('changes label of calculation method field', () => {
      const {getByText} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit'})} />
      )
      expect(getByText('Calculation Method')).toBeInTheDocument()
    })

    it('calls update with calculation method and int if method or int changes', () => {
      const update = jest.fn()
      const setError = jest.fn()
      const {getByText, getByDisplayValue, queryByTestId} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit', update, setError})} />
      )
      fireEvent.click(getByDisplayValue('Decaying Average'))
      fireEvent.click(getByText('n Number of Times'))
      expect(update).toHaveBeenCalledWith('n_mastery', 5)
      fireEvent.input(queryByTestId('calculation-int-input'), {target: {value: '4'}})
      expect(update).toHaveBeenCalledWith('n_mastery', 4)
      expect(update).toHaveBeenCalledTimes(2)
    })

    it('calls setError with true if calculation parameter changes to invalid value', () => {
      const update = jest.fn()
      const setError = jest.fn()
      const {queryByTestId} = render(
        <ProficiencyCalculation {...makeProps({individualOutcome: 'edit', update, setError})} />
      )
      fireEvent.input(queryByTestId('calculation-int-input'), {target: {value: '0'}})
      expect(setError).toHaveBeenCalledWith(true)
    })
  })
})
