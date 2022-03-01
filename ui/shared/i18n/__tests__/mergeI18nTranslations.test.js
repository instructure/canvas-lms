/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import { setRootTranslations, setLazyTranslations } from '../mergeI18nTranslations'
import i18nObj from '../i18nObj'

describe('mergeI18nTranslations', () => {
  let originalTranslations

  beforeEach(() => {
    originalTranslations = i18nObj.translations
    i18nObj.translations = {en: {}}
  })

  afterEach(() => {
    i18nObj.translations = originalTranslations
    originalTranslations = null
  })

  it('merges onto i18n.translations', () => {
    const rootTranslations = { rootKeyA: 'rootKeyValueA' }

    setRootTranslations('en', () => rootTranslations)
    expect(i18nObj.translations.en).toBe(rootTranslations)
  })

  it('creates a getter that when accessed, creates new root translations', () => {
    const rootTranslations = { rootKeyA: 'rootKeyValueA' }
    const lazyRootTranslations = { lazyRootKeyA: 'lazyRootKeyValueA' }
    setRootTranslations('en', () => rootTranslations)
    setLazyTranslations('en', 'myScope', () => lazyRootTranslations)

    expect(i18nObj.translations.en.rootKeyA).toBeDefined()
    expect(i18nObj.translations.en.lazyRootKeyA).toBeUndefined()

    i18nObj.translations.en.myScope // SIDE EFFECT: Invoke Getter

    expect(i18nObj.translations.en.rootKeyA).toBeDefined()
    expect(i18nObj.translations.en.lazyRootKeyA).toBeDefined()
  })

  it('creates a getter that when accessed, memoizes the scoped translations', () => {
    const rootTranslations = { rootKeyA: 'rootKeyValueA' }
    const lazyScopedTranslations = { lazyScopedKeyA: 'lazyScopedKeyValueA' }
    setRootTranslations('en', () => rootTranslations)
    setLazyTranslations('en', 'myScope', null, () => lazyScopedTranslations)

    expect(Object.getOwnPropertyDescriptor(i18nObj.translations.en, 'myScope').value).toBeUndefined()

    i18nObj.translations.en.myScope // SIDE EFFECT: Invoke Getter

    expect(Object.getOwnPropertyDescriptor(i18nObj.translations.en, 'myScope').value).toBeDefined()
    expect(i18nObj.translations.en.myScope.lazyScopedKeyA).toBeDefined()
  })
})
