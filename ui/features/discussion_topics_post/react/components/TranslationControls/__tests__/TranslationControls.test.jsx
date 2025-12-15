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
import {render, screen, act, waitFor} from '@testing-library/react'
import {TranslationControls} from '../TranslationControls'
import {DiscussionManagerUtilityContext} from '../../../utils/constants'
import userEvent from '@testing-library/user-event'

const mockSetActiveLanguage = vi.fn()

vi.mock('../../../hooks/useTranslationStore', () => ({
  useTranslationStore: selector => {
    const state = {
      activeLanguage: null,
      setActiveLanguage: mockSetActiveLanguage,
    }
    return selector(state)
  },
}))

const mockOnSetIsLanguageAlreadyActiveError = vi.fn()
const mockOnSetIsLanguageNotSelectedError = vi.fn()
const mockOnSetSelectedLanguage = vi.fn()

const mockTranslationLanguages = {
  current: [
    {id: 'en', name: 'English', translated_to_name: 'Translated to English'},
    {id: 'es', name: 'Spanish', translated_to_name: 'Translated to Spanish'},
    {id: 'hu', name: 'Hungarian', translated_to_name: 'Translated to Hungarian'},
  ],
}

const renderComponent = (props = {}) => {
  return render(
    <DiscussionManagerUtilityContext.Provider
      value={{translationLanguages: mockTranslationLanguages}}
    >
      <TranslationControls
        onSetIsLanguageAlreadyActiveError={mockOnSetIsLanguageAlreadyActiveError}
        onSetIsLanguageNotSelectedError={mockOnSetIsLanguageNotSelectedError}
        onSetSelectedLanguage={mockOnSetSelectedLanguage}
        {...props}
      />
    </DiscussionManagerUtilityContext.Provider>,
  )
}

describe('TranslationControls Component', () => {
  beforeAll(() => {
    const node = document.createElement('div')
    node.setAttribute('role', 'alert')
    node.setAttribute('id', 'flash_screenreader_holder')
    document.body.appendChild(node)

    ENV.ai_translation_improvements = true
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the component correctly', () => {
    renderComponent()
    expect(screen.getByPlaceholderText('Select a language...')).toBeInTheDocument()
  })

  it('selects a language and triggers callback', async () => {
    renderComponent()

    const input = screen.getByPlaceholderText('Select a language...')
    await userEvent.click(input)
    const spanishOption = await screen.findByText('Spanish')
    await userEvent.click(spanishOption)

    expect(mockOnSetSelectedLanguage).toHaveBeenCalledWith('es')
    expect(mockOnSetIsLanguageNotSelectedError).toHaveBeenCalledWith(false)
    expect(mockOnSetIsLanguageAlreadyActiveError).toHaveBeenCalledWith(false)
  })

  it('displays error message if no language is selected', () => {
    renderComponent({isLanguageNotSelectedError: true})
    expect(screen.getAllByText('Please select a language.').length).toBeGreaterThan(0)
  })

  it('displays error message if language is already active', () => {
    renderComponent({isLanguageAlreadyActiveError: true})
    expect(
      screen.getAllByText('Already translated into the selected language.').length,
    ).toBeGreaterThan(0)
  })

  it('resets input when reset() is called via ref', async () => {
    const ref = {current: null}
    render(
      <DiscussionManagerUtilityContext.Provider
        value={{translationLanguages: mockTranslationLanguages}}
      >
        <TranslationControls
          ref={ref}
          onSetIsLanguageAlreadyActiveError={mockOnSetIsLanguageAlreadyActiveError}
          onSetIsLanguageNotSelectedError={mockOnSetIsLanguageNotSelectedError}
          onSetSelectedLanguage={mockOnSetSelectedLanguage}
        />
      </DiscussionManagerUtilityContext.Provider>,
    )

    const input = screen.getByPlaceholderText('Select a language...')
    await userEvent.click(input)
    const spanishOption = await screen.findByText('Spanish')
    await userEvent.click(spanishOption)
    expect(input.value).toBe('Spanish')

    act(() => {
      ref.current.reset()
    })

    expect(mockOnSetSelectedLanguage).toHaveBeenCalledWith('')
  })
})
