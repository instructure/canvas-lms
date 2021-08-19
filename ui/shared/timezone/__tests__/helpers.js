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

import 'translations/_core_en'
import I18nStubber from '../../../../spec/coffeescripts/helpers/I18nStubber'
import tz from 'timezone/index'
import { configure } from '../'

export function setup() {
  beforeEach(() => {
    configure({ tz, tzData: {} })
    I18nStubber.pushFrame()
  })

  afterEach(() => {
    I18nStubber.popFrame()
    configure({})
  })
}

export const moonwalk = new Date(Date.UTC(1969, 6, 21, 2, 56))
export const epoch = new Date(Date.UTC(1970, 0, 1, 0, 0))
export const equal = (a, b) => expect(a).toEqual(b)
export const ok = a => expect(a).toBeTruthy()
export { I18nStubber }
