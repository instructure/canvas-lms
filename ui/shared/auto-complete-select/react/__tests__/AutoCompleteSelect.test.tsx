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
import {fireEvent, render, screen} from '@testing-library/react'
import AutoCompleteSelect, {type AutoCompleteSelectProps} from '../AutoCompleteSelect'
import fetchMock from 'fetch-mock'

describe('AutoCompleteSelect', () => {
  const props = {
    url: '/api/v1/courses',
    renderOptionLabel: option => option.id,
    renderLabel: 'Select an option',
  } satisfies AutoCompleteSelectProps<{id: string}>

  afterEach(() => fetchMock.restore())

  const enhanceUrl = (searchTerm: string) => encodeURI(`${props.url}?search_term=${searchTerm}`)

  it('should show "Type to search" when the input is focused', () => {
    render(<AutoCompleteSelect {...props} />)
    const input = screen.getByLabelText(props.renderLabel)

    fireEvent.click(input)

    const option = screen.getByText('Type to search')
    expect(option).toBeInTheDocument()
  })

  it('should not autocomplete until 3 character is entered', () => {
    render(<AutoCompleteSelect {...props} />)
    const input = screen.getByLabelText(props.renderLabel)

    fireEvent.input(input, {target: {value: '12'}})
    fireEvent.click(input)

    const option = screen.getByText('Type to search')
    expect(option).toBeInTheDocument()
  })

  describe('when autocomplete', () => {
    describe('and the response has result', () => {
      const options = [{id: 'AAA'}, {id: 'AAAA'}, {id: 'AAAAA'}]

      beforeEach(() => {
        const inputValue = 'AAA'
        fetchMock.get(enhanceUrl(inputValue), options, {overwriteRoutes: true})
        render(<AutoCompleteSelect {...props} />)
        const input = screen.getByLabelText(props.renderLabel)

        fireEvent.input(input, {target: {value: inputValue}})
      })

      it('should show the options', async () => {
        const expects = options.map(async currentOption => {
          const option = await screen.findByText(currentOption.id)

          expect(option).toBeInTheDocument()
        })
        await Promise.all(expects)
      })

      it('should show the selected option in the input', async () => {
        const firstOptionValue = options[0].id
        const firstOption = await screen.findByText(firstOptionValue)

        fireEvent.click(firstOption)

        const input = await screen.findByLabelText(props.renderLabel)
        expect(input).toHaveValue(firstOptionValue)
      })
    })

    describe('and the response has no result', () => {
      it('should show "No results"', async () => {
        const options: {id: string}[] = []
        const inputValue = 'AAA'
        fetchMock.get(enhanceUrl(inputValue), options, {overwriteRoutes: true})
        render(<AutoCompleteSelect {...props} />)

        const input = screen.getByLabelText(props.renderLabel)
        fireEvent.input(input, {target: {value: inputValue}})

        const option = await screen.findByText('No results')
        expect(option).toBeInTheDocument()
      })
    })
  })
})
