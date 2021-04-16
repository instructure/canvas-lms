/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

describe('closedCaptionLanguages', () => {
  it('has extended languages when expand_cc_languages feature is on', () => {
    global.ENV.FEATURES = {
      expand_cc_languages: true
    }
    return import('../closedCaptionLanguages').then(cclanguages => {
      // spot check expected changed
      expect(cclanguages.default.he).toEqual('Hebrew')
      expect(cclanguages.default['zh-Hant']).toEqual('Chinese Traditional')
      expect(cclanguages.default['en-GB']).toEqual('English (United Kingdom)')
    })
  })
})
