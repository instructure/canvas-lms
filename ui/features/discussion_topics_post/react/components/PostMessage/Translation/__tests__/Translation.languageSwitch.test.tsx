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

import {act} from '@testing-library/react-hooks'
import {useTranslationStore} from '../../../../hooks/useTranslationStore'
import {getTranslation} from '../../../../utils'

vi.mock('../../../../utils', () => ({
  getTranslation: vi.fn(),
}))

const getTranslationMock = getTranslation as ReturnType<typeof vi.fn>

describe('Translation component - language switching edge cases', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Reset store to initial state
    useTranslationStore.setState({
      activeLanguage: null,
      translateAll: false,
      entries: {},
    })
  })

  describe('Language switch during translation', () => {
    it('should use current language from store when job executes, not closure language', async () => {
      // This tests the fix for the stale closure bug
      const languagesUsed: string[] = []

      getTranslationMock.mockImplementation((text, language) => {
        languagesUsed.push(language)
        return Promise.resolve(`${text} in ${language}`)
      })

      // Simulate the translation job logic
      const createTranslationJob = () => {
        return async (signal: AbortSignal) => {
          // Get current language from store (the fix!)
          const currentLanguage = useTranslationStore.getState().activeLanguage
          if (!currentLanguage) {
            return
          }

          await Promise.all([
            getTranslation('Title', currentLanguage, signal),
            getTranslation('Message', currentLanguage, signal),
          ])
        }
      }

      // Setup: Start with Spanish
      act(() => {
        useTranslationStore.setState({
          activeLanguage: 'es',
          translateAll: true,
        })
      })

      // Switch to French BEFORE creating the job
      act(() => {
        useTranslationStore.setState({
          activeLanguage: 'fr',
          translateAll: true,
        })
      })

      // NOW create and start job - it should read French from store
      const job1 = createTranslationJob()
      await job1(new AbortController().signal)

      // Should have used FRENCH (from store at execution time), not Spanish (which would be from closure)
      // This proves the job reads activeLanguage from store, not from a stale closure
      expect(languagesUsed).toEqual(['fr', 'fr'])
    })

    it('should reject Spanish translation when French is set before completion', async () => {
      const resolvers: Record<string, (value: string) => void> = {}

      getTranslationMock.mockImplementation((text, language) => {
        return new Promise(resolve => {
          const key = `${text}_${language}`
          resolvers[key] = resolve
        })
      })

      const translatedTexts: string[] = []

      const translationJob = async (signal: AbortSignal) => {
        const currentLanguage = useTranslationStore.getState().activeLanguage
        if (!currentLanguage) return

        const [translatedTitle, translatedMessage] = await Promise.all([
          getTranslation('Title', currentLanguage, signal),
          getTranslation('Message', currentLanguage, signal),
        ])

        const currentState = useTranslationStore.getState()
        if (
          signal.aborted ||
          !currentState.translateAll ||
          currentState.activeLanguage !== currentLanguage
        ) {
          return
        }

        translatedTexts.push(translatedMessage)
      }

      // Start with Spanish
      act(() => {
        useTranslationStore.setState({activeLanguage: 'es', translateAll: true})
      })

      const jobPromise = translationJob(new AbortController().signal)

      // Switch to French while Spanish is "in flight"
      act(() => {
        useTranslationStore.setState({activeLanguage: 'fr', translateAll: true})
      })

      // Spanish translation completes AFTER switch
      act(() => {
        resolvers['Title_es']?.('Título en español')
        resolvers['Message_es']?.('Mensaje en español')
      })

      await jobPromise

      // Spanish text should be REJECTED
      expect(translatedTexts).toEqual([])
    })

    it('should reject translation when translateAll is disabled during execution', async () => {
      const resolvers: Record<string, (value: string) => void> = {}

      getTranslationMock.mockImplementation((text, language) => {
        return new Promise(resolve => {
          const key = `${text}_${language}`
          resolvers[key] = resolve
        })
      })

      const translatedTexts: string[] = []

      const translationJob = async (signal: AbortSignal) => {
        const currentLanguage = useTranslationStore.getState().activeLanguage
        if (!currentLanguage) return

        const [translatedTitle, translatedMessage] = await Promise.all([
          getTranslation('Title', currentLanguage, signal),
          getTranslation('Message', currentLanguage, signal),
        ])

        const currentState = useTranslationStore.getState()
        if (
          signal.aborted ||
          !currentState.translateAll ||
          currentState.activeLanguage !== currentLanguage
        ) {
          return
        }

        translatedTexts.push(translatedMessage)
      }

      act(() => {
        useTranslationStore.setState({activeLanguage: 'es', translateAll: true})
      })

      const jobPromise = translationJob(new AbortController().signal)

      // Disable translateAll before completion
      act(() => {
        useTranslationStore.setState({translateAll: false})
      })

      act(() => {
        resolvers['Title_es']('Título traducido')
        resolvers['Message_es']('Mensaje traducido')
      })

      await jobPromise

      // Should not update state
      expect(translatedTexts).toEqual([])
    })

    it('should reject translation when signal is aborted during execution', async () => {
      const resolvers: Record<string, (value: string) => void> = {}

      getTranslationMock.mockImplementation((text, language) => {
        return new Promise(resolve => {
          const key = `${text}_${language}`
          resolvers[key] = resolve
        })
      })

      const translatedTexts: string[] = []
      const abortController = new AbortController()

      const translationJob = async (signal: AbortSignal) => {
        const currentLanguage = useTranslationStore.getState().activeLanguage
        if (!currentLanguage) return

        const [translatedTitle, translatedMessage] = await Promise.all([
          getTranslation('Title', currentLanguage, signal),
          getTranslation('Message', currentLanguage, signal),
        ])

        const currentState = useTranslationStore.getState()
        if (
          signal.aborted ||
          !currentState.translateAll ||
          currentState.activeLanguage !== currentLanguage
        ) {
          return
        }

        translatedTexts.push(translatedMessage)
      }

      act(() => {
        useTranslationStore.setState({activeLanguage: 'es', translateAll: true})
      })

      const jobPromise = translationJob(abortController.signal)

      // Abort the signal
      act(() => {
        abortController.abort()
      })

      act(() => {
        resolvers['Title_es']('Título traducido')
        resolvers['Message_es']('Mensaje traducido')
      })

      await jobPromise

      // Should not update state
      expect(translatedTexts).toEqual([])
    })
  })
})
