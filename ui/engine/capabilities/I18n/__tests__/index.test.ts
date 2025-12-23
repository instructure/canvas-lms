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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'
import {registerTranslations} from '@canvas/i18n'
import {captureException} from '@sentry/browser'
import {Translations} from '../index'

vi.mock('@canvas/i18n', () => ({
  registerTranslations: vi.fn(),
}))

vi.mock('@sentry/browser', () => ({
  captureException: vi.fn(),
}))

vi.mock('@instructure/updown', async () => {
  const actual = await vi.importActual<typeof import('@instructure/updown')>('@instructure/updown')
  return {
    ...actual,
    oncePerPage: (_key: string, fn: () => any) => fn,
  }
})

const server = setupServer()

beforeAll(() => {
  server.listen({onUnhandledRequest: 'error'})
})

afterEach(() => {
  server.resetHandlers()
  vi.clearAllMocks()
})

afterAll(() => {
  server.close()
})

describe('Translations capability', () => {
  beforeEach(async () => {
    fakeENV.setup({
      RAILS_ENVIRONMENT: 'production' as const,
      LOCALE: 'en',
      LOCALE_TRANSLATION_FILE: '/translations/en.json',
      LOCALES: ['en'],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })
  it('does not fetch translations for plain en locale', async () => {
    fakeENV.setup({
      RAILS_ENVIRONMENT: 'production' as const,
      LOCALE: 'en',
      LOCALE_TRANSLATION_FILE: '/translations/en.json',
      LOCALES: ['en'],
    })

    await Translations.up()

    expect(registerTranslations).toHaveBeenCalledWith('en', expect.any(Object))
  })

  it('fetches translations for en-US locale', async () => {
    fakeENV.setup({
      RAILS_ENVIRONMENT: 'production' as const,
      LOCALE: 'en-US',
      LOCALES: ['en-US'],
      LOCALE_TRANSLATION_FILE: '/translations/en-US.json',
    })
    const mockTranslations = {hello: 'Hello'}

    server.use(
      http.get('/translations/en-US.json', () => {
        return HttpResponse.json(mockTranslations)
      }),
    )

    await Translations.up()

    expect(registerTranslations).toHaveBeenCalledWith('en-US', mockTranslations)
  })

  it('fetches translations for non-english locales', async () => {
    fakeENV.setup({
      RAILS_ENVIRONMENT: 'production' as const,
      LOCALE: 'fr',
      LOCALES: ['fr', 'en'],
      LOCALE_TRANSLATION_FILE: '/translations/fr.json',
    })
    const mockTranslations = {hello: 'Bonjour'}

    server.use(
      http.get('/translations/fr.json', () => {
        return HttpResponse.json(mockTranslations)
      }),
    )

    await Translations.up()

    expect(registerTranslations).toHaveBeenCalledWith('fr', mockTranslations)
  })

  describe('fallback behavior', () => {
    it('falls back to English when fetch fails', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'production' as const,
        LOCALE: 'fr',
        LOCALES: ['fr', 'en'],
        LOCALE_TRANSLATION_FILE: '/translations/fr.json',
      })

      server.use(
        http.get('/translations/fr.json', () => {
          return HttpResponse.error()
        }),
      )

      await Translations.up()

      expect(registerTranslations).toHaveBeenCalledWith('fr', expect.any(Object))
      expect(captureException).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Could not load translations for "fr"',
        }),
      )
    })

    it('uses navigator.language when ENV.LOCALE is not set', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'production' as const,
        LOCALE_TRANSLATION_FILE: '/translations/it.json',
        LOCALES: ['en'],
      })
      Object.defineProperty(window.navigator, 'language', {
        value: 'it',
        configurable: true,
        writable: true,
      })
      const mockTranslations = {hello: 'Ciao'}

      server.use(
        http.get('/translations/it.json', () => {
          return HttpResponse.json(mockTranslations)
        }),
      )

      await Translations.up()

      expect(registerTranslations).toHaveBeenCalledWith('it', mockTranslations)
    })

    it('defaults to en when both ENV.LOCALE and navigator.language are unavailable', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'production' as const,
        LOCALES: ['en'],
      })
      Object.defineProperty(window.navigator, 'language', {
        value: undefined,
        configurable: true,
        writable: true,
      })

      await Translations.up()

      expect(registerTranslations).toHaveBeenCalledWith('en', expect.any(Object))
    })
  })

  describe('test environment behavior', () => {
    it('uses fallback translations in test environment', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'test' as const,
        LOCALE: 'fr',
        LOCALES: ['en'],
      })

      await Translations.up()

      expect(registerTranslations).toHaveBeenCalledWith('fr', expect.any(Object))
    })
  })

  describe('edge cases', () => {
    it('handles null JSON response from fetch', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'production' as const,
        LOCALE: 'ja',
        LOCALES: ['ja', 'en'],
        LOCALE_TRANSLATION_FILE: '/translations/ja.json',
      })

      server.use(
        http.get('/translations/ja.json', () => {
          return HttpResponse.json(null)
        }),
      )

      await Translations.up()

      expect(registerTranslations).not.toHaveBeenCalled()
    })

    it('handles non-object JSON response from fetch', async () => {
      fakeENV.setup({
        RAILS_ENVIRONMENT: 'production' as const,
        LOCALE: 'zh',
        LOCALES: ['zh', 'en'],
        LOCALE_TRANSLATION_FILE: '/translations/zh.json',
      })

      server.use(
        http.get('/translations/zh.json', () => {
          return HttpResponse.json('invalid')
        }),
      )

      await Translations.up()

      expect(registerTranslations).not.toHaveBeenCalled()
    })
  })
})
