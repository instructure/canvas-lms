/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {generateActionTemplates} from '../generateActionTemplates'
import {COURSE, ACCOUNT} from '@canvas/permissions/react/propTypes'

const accountDetails = 'account details'
const accountConsiderations = 'account considerations'
const courseDetails = 'course details'
const courseConsiderations = 'course considerations'

const result = generateActionTemplates(
  accountDetails,
  accountConsiderations,
  courseDetails,
  courseConsiderations
)

describe('permissions::generateActionTemplates::', () => {
  it('returns the correct data structure', () => {
    expect(Object.keys(result)).toHaveLength(2)
    expect(result).toEqual(
      expect.objectContaining({
        [ACCOUNT]: expect.anything(),
        [COURSE]: expect.anything(),
      })
    )
  })

  it('puts the right arguments in the right places', () => {
    expect(result[ACCOUNT].what_it_does).toBe(accountDetails)
    expect(result[ACCOUNT].additional_considerations).toBe(accountConsiderations)
    expect(result[COURSE].what_it_does).toBe(courseDetails)
    expect(result[COURSE].additional_considerations).toBe(courseConsiderations)
  })
})
