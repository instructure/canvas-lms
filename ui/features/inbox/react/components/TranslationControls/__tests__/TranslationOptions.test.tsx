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
import {render, screen, fireEvent} from '@testing-library/react'
import TranslationOptions from '../TranslationOptions'
import {useTranslationContext} from '../../../hooks/useTranslationContext'

vi.mock('../../../hooks/useTranslationContext')

const mockUseTranslationContext = useTranslationContext as ReturnType<typeof vi.fn>

const translateBody = vi.fn()

describe('TranslationOptions', () => {
  beforeAll(() => {
    // @ts-expect-error
    global.ENV = {
      inbox_translation_languages: [
        {id: 'en', name: 'English'},
        {id: 'es', name: 'Spanish'},
        {id: 'fr', name: 'French'},
        {id: 'de', name: 'German'},
        {id: 'it', name: 'Italian'},
      ],
    }
  })

  beforeEach(() => {
    translateBody.mockClear()
    mockUseTranslationContext.mockReturnValue({
      setTranslationTargetLanguage: vi.fn(),
      translateBody,
      translating: false,
      setErrorMessages: vi.fn(),
    })
  })

  it('renders without crashing', () => {
    render(<TranslationOptions asPrimary={null} onSetPrimary={vi.fn()} />)
    expect(screen.getByText(/Translate to/i)).toBeInTheDocument()
  })

  it('initial state is correct', () => {
    render(<TranslationOptions asPrimary={null} onSetPrimary={vi.fn()} />)
    expect(screen.getByPlaceholderText(/Select a language.../i)).toHaveValue('')
    expect(screen.getByText(/^Translate$/i).closest('button')).toBeEnabled()
  })

  it('calls translateBody on clicking on translate button', () => {
    const {translateBody} = mockUseTranslationContext()
    const setPrimaryMock = vi.fn()
    render(
      <div id="flash_screenreader_holder" role="alert">
        <TranslationOptions asPrimary={null} onSetPrimary={setPrimaryMock} />
      </div>,
    )

    const input = screen.getByPlaceholderText(/Select a language.../i)
    fireEvent.click(input)
    const option = screen.getByText(/Spanish/i)
    option.click()

    const translateButton = screen.getByText(/^Translate$/i).closest('button')
    fireEvent.click(translateButton!)
    expect(translateBody).toHaveBeenCalledWith(false)
    expect(setPrimaryMock).toHaveBeenCalledWith(false)
  })

  it('calls translateBody but not onSetPrimary if the asPrimary is non null', () => {
    mockUseTranslationContext()

    const valuesArr = [true, false]

    const setPrimaryMock = vi.fn()
    const {rerender} = render(<TranslationOptions asPrimary={null} onSetPrimary={setPrimaryMock} />)

    valuesArr.forEach(asPrimary => {
      translateBody.mockClear()
      setPrimaryMock.mockClear()

      rerender(<TranslationOptions asPrimary={asPrimary} onSetPrimary={setPrimaryMock} />)

      const input = screen.getByPlaceholderText(/Select a language.../i)
      fireEvent.click(input)
      const option = screen.getByText(/Spanish/i)
      fireEvent.click(option)
      const translateButton = screen.getByText(/^Translate$/i).closest('button')
      fireEvent.click(translateButton!)

      expect(translateBody).toHaveBeenCalledWith(asPrimary)
      expect(setPrimaryMock).not.toHaveBeenCalled()
    })
  })

  it('updates asPrimary state on radio input change', () => {
    const onSetPrimary = vi.fn()
    render(<TranslationOptions asPrimary={null} onSetPrimary={onSetPrimary} />)
    fireEvent.click(screen.getByLabelText(/Show translation first/i))
    expect(onSetPrimary).toHaveBeenCalledWith(true)
  })

  it('calls setTranslationTargetLanguage on selecting multiple languages', () => {
    const {setTranslationTargetLanguage} = mockUseTranslationContext()
    render(
      <div id="flash_screenreader_holder" role="alert">
        <TranslationOptions asPrimary={null} onSetPrimary={vi.fn()} />
      </div>,
    )

    const input = screen.getByPlaceholderText(/Select a language.../i)
    fireEvent.click(input)
    const option = screen.getByText(/Spanish/i)
    option.click()

    expect(setTranslationTargetLanguage).toHaveBeenCalledWith('es')

    fireEvent.change(input, {target: {value: ''}})
    fireEvent.click(input)
    const option2 = screen.getByText(/French/i)
    option2.click()
    expect(setTranslationTargetLanguage).toHaveBeenCalledWith('fr')
  })
})
