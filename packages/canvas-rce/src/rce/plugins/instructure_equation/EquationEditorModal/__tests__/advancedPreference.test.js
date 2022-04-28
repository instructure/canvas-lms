/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import advancedPreference, {STORE, KEY} from '../advancedPreference'

describe('advancedPreference', () => {
  beforeEach(() => {
    STORE.clear()
  })

  describe('isSet', () => {
    it('returns false if the default key is not set to true', () => {
      expect(advancedPreference.isSet()).toBe(false)
    })

    it('returns true if the default key is set to true', () => {
      STORE.setItem(KEY, 'true')
      expect(advancedPreference.isSet()).toBe(true)
    })
  })

  describe('set', () => {
    it('sets the default key value to true', () => {
      advancedPreference.set()
      expect(!!STORE.getItem(KEY)).toBe(true)
    })
  })

  describe('clear', () => {
    it('removes the default key from the store', () => {
      STORE.setItem(KEY, 'true')
      advancedPreference.clear()
      expect(!!STORE.getItem(KEY)).toBe(false)
    })
  })
})
