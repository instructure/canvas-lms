/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradingPeriod from '../gradingPeriod'
import DateHelper from '@canvas/datetime/dateHelper'
import $ from 'jquery'

jest.mock('jquery', () => {
  const jQueryMock = jest.fn(selector => ({
    datepicker: jest.fn(),
    data: jest.fn(key => {
      if (key === 'unfudged-date') {
        return new Date('2015-04-01T00:00:00Z')
      }
      if (key === 'invalid') {
        return false
      }
      if (key === 'blank') {
        return false
      }
      return null
    }),
    val: jest.fn(),
    on: jest.fn((event, callback) => {
      // Store the callback to simulate event triggers
      if (event === 'change') {
        jQueryMock.changeCallback = callback
      }
    }),
    trigger: jest.fn(event => {
      // Call stored callback when event is triggered
      if (event === 'change' && jQueryMock.changeCallback) {
        jQueryMock.changeCallback({
          target: {
            name: 'startDate',
            id: 'period_start_date_1',
          },
        })
      }
    }),
    find: jest.fn().mockReturnThis(),
  }))

  jQueryMock.flashMessage = jest.fn()
  jQueryMock.flashError = jest.fn()

  return jQueryMock
})

jest.mock('@canvas/datetime/jquery/DatetimeField', () => ({
  renderDatetimeField: jest.fn(),
}))

describe('GradingPeriod', () => {
  let defaultProps

  beforeEach(() => {
    defaultProps = {
      id: '1',
      title: 'Spring',
      startDate: new Date('2015-03-01T00:00:00Z'),
      endDate: new Date('2015-05-31T00:00:00Z'),
      closeDate: new Date('2015-06-07T00:00:00Z'),
      weight: 50,
      weighted: true,
      disabled: false,
      readOnly: false,
      permissions: {
        read: true,
        update: true,
        create: true,
        delete: true,
      },
      onDeleteGradingPeriod: jest.fn(),
      updateGradingPeriodCollection: jest.fn(),
    }

    window.ENV = {
      GRADING_PERIODS_URL: 'api/v1/courses/1/grading_periods',
    }

    jest.spyOn(DateHelper, 'formatDatetimeForDisplay').mockImplementation(date => {
      if (!date) return ''
      return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
    delete window.ENV
  })

  const renderGradingPeriod = (props = {}) => {
    return render(<GradingPeriod {...defaultProps} {...props} />)
  }

  it('sets initial state properly', () => {
    renderGradingPeriod()

    expect(screen.getByRole('textbox', {name: /grading period name/i})).toHaveValue('Spring')
    expect(screen.getByRole('textbox', {name: /start date/i})).toHaveValue('Mar 1, 2015')
    expect(screen.getByRole('textbox', {name: /end date/i})).toHaveValue('May 31, 2015')
    expect(screen.getByText('50%')).toBeInTheDocument()
  })

  it('onDateChange calls replaceInputWithDate', async () => {
    renderGradingPeriod()
    const startDateInput = screen.getByRole('textbox', {name: /start date/i})

    // Mock jQuery data return and trigger change
    const jQueryInstance = $(startDateInput)
    jQueryInstance.data.mockImplementation(key => {
      if (key === 'unfudged-date') {
        return new Date('2015-04-01T00:00:00Z')
      }
      return false
    })

    await userEvent.clear(startDateInput)
    await userEvent.type(startDateInput, '2015-04-01')
    jQueryInstance.trigger('change')

    await waitFor(() => {
      expect(DateHelper.formatDatetimeForDisplay).toHaveBeenCalled()
    })
  })

  it('onDateChange calls updateGradingPeriodCollection', async () => {
    renderGradingPeriod()
    const startDateInput = screen.getByRole('textbox', {name: /start date/i})

    // Mock jQuery data return and trigger change
    const jQueryInstance = $(startDateInput)
    jQueryInstance.data.mockImplementation(key => {
      if (key === 'unfudged-date') {
        return new Date('2015-04-01T00:00:00Z')
      }
      return false
    })

    await userEvent.clear(startDateInput)
    await userEvent.type(startDateInput, '2015-04-01')
    jQueryInstance.trigger('change')

    await waitFor(() => {
      expect(defaultProps.updateGradingPeriodCollection).toHaveBeenCalled()
    })
  })

  it('onTitleChange changes the title state', async () => {
    const {rerender} = renderGradingPeriod()
    const titleInput = screen.getByRole('textbox', {name: /grading period name/i})

    await userEvent.clear(titleInput)
    await userEvent.type(titleInput, 'MXP: Most Xtreme Primate')
    fireEvent.blur(titleInput)

    // Force a re-render with updated props
    rerender(<GradingPeriod {...defaultProps} title="MXP: Most Xtreme Primate" />)

    await waitFor(() => {
      expect(screen.getByRole('textbox', {name: /grading period name/i})).toHaveValue(
        'MXP: Most Xtreme Primate',
      )
    })
  })

  it('onTitleChange calls updateGradingPeriodCollection', () => {
    renderGradingPeriod()
    const titleInput = screen.getByRole('textbox', {name: /grading period name/i})

    fireEvent.change(titleInput, {target: {value: 'MXP: Most Xtreme Primate'}})

    expect(defaultProps.updateGradingPeriodCollection).toHaveBeenCalled()
  })

  it('replaceInputWithDate calls formatDatetimeForDisplay', async () => {
    const formatDatetime = jest.spyOn(DateHelper, 'formatDatetimeForDisplay')
    renderGradingPeriod()
    const startDateInput = screen.getByRole('textbox', {name: /start date/i})

    // Mock jQuery data return and trigger change
    const jQueryInstance = $(startDateInput)
    jQueryInstance.data.mockImplementation(key => {
      if (key === 'unfudged-date') {
        return new Date('2015-04-01T00:00:00Z')
      }
      return false
    })

    await userEvent.clear(startDateInput)
    await userEvent.type(startDateInput, '2015-04-01')
    jQueryInstance.trigger('change')

    await waitFor(() => {
      expect(formatDatetime).toHaveBeenCalledWith(new Date('2015-04-01T00:00:00Z'))
    })
  })

  it('assigns the readOnly property correctly when false', () => {
    renderGradingPeriod()

    expect(screen.getByRole('textbox', {name: /grading period name/i})).not.toHaveAttribute(
      'readonly',
    )
    expect(screen.getByRole('textbox', {name: /start date/i})).not.toHaveAttribute('readonly')
    expect(screen.getByRole('textbox', {name: /end date/i})).not.toHaveAttribute('readonly')
  })

  it('assigns the readOnly property correctly when true', () => {
    renderGradingPeriod({readOnly: true})

    expect(screen.queryByRole('textbox', {name: /grading period name/i})).not.toBeInTheDocument()
    expect(screen.queryByRole('textbox', {name: /start date/i})).not.toBeInTheDocument()
    expect(screen.queryByRole('textbox', {name: /end date/i})).not.toBeInTheDocument()
  })

  it('assigns the weight and weighted properties', () => {
    renderGradingPeriod()

    expect(screen.getByText('50%')).toBeInTheDocument()
  })

  it('assigns the weight and weighted properties when weighted is false', () => {
    renderGradingPeriod({weighted: false})

    expect(screen.queryByText('50%')).not.toBeInTheDocument()
  })

  it('assigns the closeDate property', () => {
    // When the component is editable (permissions.update=true and readOnly=false),
    // it shows the endDate instead of closeDate
    renderGradingPeriod()

    // Find the close date label by its id
    const closeDateLabel = screen.getByText('Close Date', {
      selector: 'label.ic-Label',
    })
    expect(closeDateLabel).toBeInTheDocument()

    // Find the close date value within the GradingPeriod__Action span
    // Note: When editable, it shows the endDate (May 31) instead of closeDate (Jun 7)
    const closeDateValue = screen.getByText('May 31, 2015', {
      selector: 'span.GradingPeriod__Action',
    })
    expect(closeDateValue).toBeInTheDocument()
  })

  it('assigns endDate as closeDate when closeDate is not defined', () => {
    renderGradingPeriod({closeDate: defaultProps.endDate})

    expect(screen.getByText('May 31, 2015')).toBeInTheDocument()
  })
})
