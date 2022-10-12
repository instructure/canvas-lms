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

import {arrayOf, instanceOf, shape, string} from 'prop-types'

import GradeEntry from '@canvas/grading/GradeEntry/index'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import GradeOverride from '@canvas/grading/GradeOverride'

export const gradingScheme = shape({
  data: instanceOf(Array),
})

export const messages = arrayOf(
  shape({
    text: string.isRequired,
    type: string.isRequired,
  })
)

export const grade = instanceOf(GradeOverride)
export const gradeInfo = instanceOf(GradeOverrideInfo)
export const gradeEntry = instanceOf(GradeEntry)
