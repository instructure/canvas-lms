/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {GradingSchemeFormInput} from '../GradingSchemeInput'

export const VALID_FORM_INPUT: GradingSchemeFormInput = {
  data: [
    {name: 'A', value: 0.9},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
}

export const SHORT_FORM_INPUT: GradingSchemeFormInput = {
  data: [
    {name: 'P', value: 0.5},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
}

export const FORM_INPUT_MISSING_TITLE: GradingSchemeFormInput = {
  data: [
    {name: 'A', value: 0.9},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: '',
}

export const FORM_INPUT_OVERLAPPING_RANGES: GradingSchemeFormInput = {
  data: [
    {name: 'A', value: 0.8},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
}
