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

import moment from 'moment'

describe('moment module', () => {
  describe('locales', () => {
    it('includes the mi-nz locale', () => {
      // webpack does not load up all locales by default.
      // we have to ask for it specifically
      require('../../../ext/custom_moment_locales/mi_nz')

      expect(moment.localeData('mi-nz')).not.toBeNull()
    })
  })
})
