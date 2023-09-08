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

import PronounInput from '../PronounsInput'
import {render, fireEvent} from '@testing-library/react'
import React from 'react'

describe('render available pronouns input', () => {
  let originalEnv

  beforeEach(() => {
    originalEnv = JSON.parse(JSON.stringify(window.ENV))
    window.ENV.PRONOUNS_LIST = ['She/Her', 'He/Him', 'They/Them']
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  it('renders tooltip when focused', () => {
    const {getAllByText, getByTestId} = render(<PronounInput />)
    const icon = getByTestId('pronoun_info')
    fireEvent.focus(icon)
    expect(
      getAllByText(
        'These pronouns will be available to Canvas users in your account to choose from.'
      )[0]
    ).toBeVisible()
  })

  it('with defaults in view', () => {
    const {getByText} = render(<PronounInput />)
    expect(getByText('She/Her')).toBeVisible()
    expect(getByText('He/Him')).toBeVisible()
    expect(getByText('They/Them')).toBeVisible()
  })

  it('removes pronoun "They/Them"', async () => {
    const {findByText, queryByText} = render(<PronounInput />)
    expect(await findByText('They/Them')).toBeVisible()
    fireEvent.click(await findByText('They/Them'))
    expect(await queryByText('They/Them')).toEqual(null)
  })

  it('trims pronouns before adding them', async () => {
    const {findByText, getByTestId} = render(<PronounInput />)
    const input = getByTestId('test_pronoun_input')
    fireEvent.change(input, {target: {value: ' It/That '}})
    fireEvent.keyDown(input, {key: 'Enter', code: 13, charCode: 13})
    expect(await findByText('It/That')).toBeVisible()
  })
})
