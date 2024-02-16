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
import QuestionBankSelector from '../question_bank_selector'

const onChange = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<QuestionBankSelector onChange={onChange} {...overrideProps} />)

describe('QuestionBankSelector', () => {
  it('calls onChange with question bank', async () => {
    window.ENV.QUESTION_BANKS = [{assessment_question_bank: {id: 1, title: 'My Question Bank'}}]

    renderComponent()

    await userEvent.click(screen.getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(screen.getByRole('option', {name: 'My Question Bank'}))

    expect(onChange).toHaveBeenCalledWith({question_bank_id: 1})
  })

  it('calls onChange with new question bank name', async () => {
    window.ENV.QUESTION_BANKS = [{assessment_question_bank: {id: 1, title: 'My Question Bank'}}]

    renderComponent()

    await userEvent.click(screen.getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(screen.getByRole('option', {name: 'Create new question bank...'}))

    expect(onChange).toHaveBeenCalledWith({question_bank_name: ''})
  })

  it('calls onChange with new question bank name when input changes', async () => {
    window.ENV.QUESTION_BANKS = [{assessment_question_bank: {id: 1, title: 'My Question Bank'}}]

    renderComponent()

    await userEvent.click(screen.getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(screen.getByRole('option', {name: 'Create new question bank...'}))
    await userEvent.type(
      screen.getByPlaceholderText('New question bank'),
      'This is a new question bank!'
    )

    expect(onChange).toHaveBeenCalledWith({question_bank_name: 'This is a new question bank!'})
  })

  it('calls onChange with null', async () => {
    window.ENV.QUESTION_BANKS = [{assessment_question_bank: {id: 1, title: 'My Question Bank'}}]

    renderComponent()

    await userEvent.click(screen.getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(screen.getByRole('option', {name: 'Select question bank'}))

    expect(onChange).toHaveBeenCalledWith(null)
  })
})
