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
import useTranslateEntry from '../useTranslateEntry'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import * as translationUtils from '../../utils'

jest.mock('../../utils', () => ({
  ...jest.requireActual('../../utils'),
  getTranslation: jest.fn(),
}))

const mockSetTranslatedTitle = jest.fn()
const mockSetTranslatedMessage = jest.fn()
const mockSetTranslationError = jest.fn()
const mockSetEntryTranslating = jest.fn()
const mockEnqueueTranslation = jest.fn()

const wrapper = ({children, translateTargetLanguage = 'es'}) => (
  <DiscussionManagerUtilityContext.Provider
    value={{
      translateTargetLanguage,
      setEntryTranslating: mockSetEntryTranslating,
      enqueueTranslation: mockEnqueueTranslation,
    }}
  >
    {children}
  </DiscussionManagerUtilityContext.Provider>
)

beforeEach(() => {
  jest.clearAllMocks()
})

test('skips translation if translateTargetLanguage is null', () => {
  renderHook(
    () =>
      useTranslateEntry(
        'entry1',
        'Hello',
        'World',
        mockSetTranslatedTitle,
        mockSetTranslatedMessage,
        mockSetTranslationError,
      ),
    {
      wrapper: ({children}) => wrapper({children, translateTargetLanguage: null}),
    },
  )

  expect(mockSetTranslatedTitle).toHaveBeenCalledWith(null)
  expect(mockSetTranslatedMessage).toHaveBeenCalledWith(null)
  expect(mockSetTranslationError).not.toHaveBeenCalled()
  expect(mockSetEntryTranslating).not.toHaveBeenCalled()
  expect(mockEnqueueTranslation).not.toHaveBeenCalled()
})

test('enqueues translation job and handles success', async () => {
  translationUtils.getTranslation.mockResolvedValueOnce('Hola')
  translationUtils.getTranslation.mockResolvedValueOnce('Mundo')

  let jobFn
  mockEnqueueTranslation.mockImplementation(fn => {
    jobFn = fn
  })

  renderHook(
    () =>
      useTranslateEntry(
        'entry2',
        'Hello',
        'World',
        mockSetTranslatedTitle,
        mockSetTranslatedMessage,
        mockSetTranslationError,
      ),
    {wrapper},
  )

  expect(mockSetEntryTranslating).toHaveBeenCalledWith('entry2', true)
  expect(mockSetTranslationError).toHaveBeenCalledWith(null)
  expect(mockEnqueueTranslation).toHaveBeenCalled()

  await act(async () => {
    await jobFn()
  })

  expect(translationUtils.getTranslation).toHaveBeenCalledWith('Hello', 'es')
  expect(translationUtils.getTranslation).toHaveBeenCalledWith('World', 'es')
  expect(mockSetTranslatedTitle).toHaveBeenCalledWith('Hola')
  expect(mockSetTranslatedMessage).toHaveBeenCalledWith('Mundo')
  expect(mockSetEntryTranslating).toHaveBeenCalledWith('entry2', false)
})

test('handles translation error with translationError in error', async () => {
  const error = {translationError: {type: 'quota', message: 'Limit reached'}}
  translationUtils.getTranslation.mockRejectedValue(error)

  let jobFn
  mockEnqueueTranslation.mockImplementation(fn => {
    jobFn = fn
  })

  renderHook(
    () =>
      useTranslateEntry(
        'entry3',
        'Foo',
        'Bar',
        mockSetTranslatedTitle,
        mockSetTranslatedMessage,
        mockSetTranslationError,
      ),
    {wrapper},
  )

  await act(async () => {
    await jobFn()
  })

  expect(mockSetTranslatedTitle).toHaveBeenCalledWith(null)
  expect(mockSetTranslatedMessage).toHaveBeenCalledWith(null)
  expect(mockSetTranslationError).toHaveBeenCalledWith(error.translationError)
  expect(mockSetEntryTranslating).toHaveBeenCalledWith('entry3', false)
})

test('handles translation error without translationError in error', async () => {
  translationUtils.getTranslation.mockRejectedValue(new Error('Unexpected'))

  let jobFn
  mockEnqueueTranslation.mockImplementation(fn => {
    jobFn = fn
  })

  renderHook(
    () =>
      useTranslateEntry(
        'entry4',
        'A',
        'B',
        mockSetTranslatedTitle,
        mockSetTranslatedMessage,
        mockSetTranslationError,
      ),
    {wrapper},
  )

  await act(async () => {
    await jobFn()
  })

  expect(mockSetTranslationError).toHaveBeenCalledWith({
    type: 'newError',
    message: 'There was an unexpected error during translation.',
  })
})
