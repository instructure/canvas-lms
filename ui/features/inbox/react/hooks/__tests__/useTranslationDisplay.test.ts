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

import {renderHook, act} from '@testing-library/react-hooks'
import useTranslationDisplay from '../useTranslationDisplay'
import {useTranslationContext} from '../useTranslationContext'
import {translationSeparator} from '../../utils/constants'
import * as translationUtils from '../../utils/inbox_translator'

vi.mock('../useTranslationContext')
vi.mock('../../utils/inbox_translator')

const mockStripSignature = vi
  .spyOn(translationUtils, 'stripSignature')
  .mockImplementation((body: string) => {
    return body
  })

const mockUseTranslationContext = useTranslationContext as ReturnType<typeof vi.fn>

describe('useTranslationDisplay', () => {
  const setMessagePosition = vi.fn()
  const setBody = vi.fn()
  const mockContext = {
    translationTargetLanguage: '',
    setTranslationTargetLanguage: vi.fn(),
    translating: false,
    setTranslating: vi.fn(),
    translateBody: vi.fn(),
    translateBodyWith: vi.fn(),
    setMessagePosition,
    messagePosition: null,
    body: '',
    setBody,
    errorMessages: [],
    setErrorMessages: vi.fn(),
    textTooLongErrors: [],
  }

  beforeEach(() => {
    vi.clearAllMocks()
    mockUseTranslationContext.mockReturnValue({
      ...mockContext,
      setTranslationTargetLanguage: vi.fn(),
      translateBody: vi.fn(),
      translating: false,
    })
  })

  it('should return primary as null when messagePosition is null', () => {
    const {result} = renderHook(() =>
      useTranslationDisplay({
        signature: '',
        inboxSettingsFeature: false,
        includeTranslation: true,
      }),
    )

    expect(result.current.primary).toBeNull()
  })

  it('should only call the setBody and setMessagePosition when we do not include the translation anymore and translation is loaded', () => {
    const body = `part1${translationSeparator}part2`

    const mockReturnValue = {
      ...mockContext,
      messagePosition: 'primary',
      body,
    }

    mockUseTranslationContext.mockImplementation(() => mockReturnValue)

    const {result, rerender} = renderHook(props => useTranslationDisplay(props), {
      initialProps: {
        signature: 'my signature',
        inboxSettingsFeature: true,
        includeTranslation: true,
      },
    })

    expect(result.current.primary).toBe(true)

    act(() => {
      rerender({
        signature: 'my signature',
        inboxSettingsFeature: true,
        includeTranslation: false,
      })
    })

    expect(setMessagePosition).toHaveBeenCalledWith(null)
    expect(setBody).toHaveBeenCalledWith(expect.any(Function))

    const capturedFunction = setBody.mock.calls[0][0]

    // Just to ensure the inside of the function is correct
    // the signature will be after the part2
    expect(capturedFunction(body)).toMatch(/part2.*/)

    expect(mockStripSignature).toHaveBeenCalledWith(body)
  })

  it('should set message position and body correctly when handleIsPrimaryChange is called', () => {
    const part1 = 'part1'
    const part2 = 'part2'
    const body = `${part1}${translationSeparator}${part2}`

    const mockReturnValue = {
      ...mockContext,
      body,
      messagePosition: 'primary',
    }

    mockUseTranslationContext.mockImplementation(() => mockReturnValue)

    const {result} = renderHook(() =>
      useTranslationDisplay({
        signature: '',
        inboxSettingsFeature: false,
        includeTranslation: true,
      }),
    )

    act(() => {
      result.current.handleIsPrimaryChange(false)
    })

    expect(setMessagePosition).toHaveBeenCalledWith('secondary')
    expect(setBody).toHaveBeenCalledWith(expect.any(Function))

    const capturedFunction = setBody.mock.calls[0][0]

    expect(capturedFunction(body)).toBe(`${part2}${translationSeparator}${part1}`)

    setBody.mockClear()
    setMessagePosition.mockClear()

    act(() => {
      result.current.handleIsPrimaryChange(true)
    })

    expect(setMessagePosition).toHaveBeenCalledWith('primary')
    expect(setBody).toHaveBeenCalledWith(expect.any(Function))

    const capturedFunction2 = setBody.mock.calls[0][0]
    // The actual body is not updated so the part1 and part2 shouldn't be flipped
    // compared to the previous call
    expect(capturedFunction2(body)).toBe(`${part2}${translationSeparator}${part1}`)
  })

  it('should return the correct primary value', () => {
    ;[true, false, null].forEach(expectedPrimary => {
      let messagePosition = null

      if (expectedPrimary !== null) {
        messagePosition = expectedPrimary ? 'primary' : 'secondary'
      }

      const mockReturnValue = {
        ...mockContext,
        messagePosition,
      }

      mockUseTranslationContext.mockImplementation(() => mockReturnValue)

      const {result} = renderHook(() =>
        useTranslationDisplay({
          signature: '',
          inboxSettingsFeature: false,
          includeTranslation: true,
        }),
      )

      expect(result.current.primary).toBe(expectedPrimary)
    })
  })
})
