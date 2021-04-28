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

import mergeI18nTranslations from '../mergeI18nTranslations'
import i18nObj from '../i18nObj'

describe('mergeI18nTranslations', () => {
  it('merges onto i18n.translations', () => {
    const newStrings = {
      ar: {someKey: 'arabic value'},
      en: {someKey: 'english value'}
    }
    mergeI18nTranslations(newStrings)
    expect(i18nObj.translations).toEqual(newStrings)
  })

  it('overwrites the key that is there', () => {
    i18nObj.translations.en.anotherKey = 'original value'
    mergeI18nTranslations({
      en: {anotherKey: 'new value'}
    })
    expect(i18nObj.translations.en.anotherKey).toEqual('new value')
  })
})
