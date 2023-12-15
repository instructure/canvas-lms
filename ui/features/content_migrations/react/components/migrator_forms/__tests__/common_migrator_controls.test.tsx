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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CommonMigratorControls from '../common_migrator_controls'

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<CommonMigratorControls onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

describe('CommonMigratorControls', () => {
  afterEach(() => jest.clearAllMocks())
  beforeAll(() => {
    window.ENV.QUIZZES_NEXT_ENABLED = true
    window.ENV.NEW_QUIZZES_MIGRATION_DEFAULT = false
  })

  afterEach(() => jest.clearAllMocks())

  it('calls onSubmit with import_quizzes_next', () => {
    renderComponent({canImportAsNewQuizzes: true})

    userEvent.click(screen.getByRole('checkbox', {name: /Import existing quizzes as New Quizzes/}))
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({import_quizzes_next: true}),
      })
    )
  })

  it('calls onSubmit with overwrite_quizzes', () => {
    renderComponent({canOverwriteAssessmentContent: true})

    userEvent.click(
      screen.getByRole('checkbox', {name: /Overwrite assessment content with matching IDs/})
    )
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({overwrite_quizzes: true}),
      })
    )
  })

  it('calls onSubmit with date_shift_options', () => {
    renderComponent({canAdjustDates: true})

    userEvent.click(screen.getByRole('checkbox', {name: 'Adjust events and due dates'}))
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        date_shift_options: {
          day_substitutions: [],
          new_end_date: false,
          new_start_date: false,
          old_end_date: false,
          old_start_date: false,
          substitutions: {},
        },
      })
    )
  })

  it('calls onSubmit with selective_import', () => {
    renderComponent({canSelectContent: true})

    userEvent.click(screen.getByRole('radio', {name: 'Select specific content'}))
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

    expect(onSubmit).toHaveBeenCalledWith(expect.objectContaining({selective_import: true}))
  })

  it('calls onSubmit with all data', () => {
    renderComponent({
      canSelectContent: true,
      canImportAsNewQuizzes: true,
      canOverwriteAssessmentContent: true,
      canAdjustDates: true,
    })

    userEvent.click(screen.getByRole('radio', {name: 'Select specific content'}))
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

    expect(onSubmit).toHaveBeenCalledWith({
      adjust_dates: {
        enabled: false,
        operation: 'shift_dates',
      },
      selective_import: true,
      date_shift_options: {
        day_substitutions: [],
        new_end_date: false,
        new_start_date: false,
        old_end_date: false,
        old_start_date: false,
        substitutions: {},
      },
      errored: false,
      settings: {import_quizzes_next: false, overwrite_quizzes: false},
    })
  })

  it('calls onCancel', () => {
    renderComponent()
    userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })
})
