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

import type {GradingSchemeEditableData} from '../GradingSchemeInput'

export const VALID_FORM_INPUT: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.9},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 1,
  pointsBased: false,
}

export const VALID_FORM_INPUT_POINTS_BASED: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.75},
    {name: 'B', value: 0.5},
    {name: 'C', value: 0.25},
    {name: 'D', value: 0},
  ],
  title: 'A Points Grading Scheme',
  scalingFactor: 4,
  pointsBased: true,
}

export const SHORT_FORM_INPUT: GradingSchemeEditableData = {
  data: [
    {name: 'P', value: 0.5},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 1,
  pointsBased: false,
}

export const SHORT_FORM_INPUT_POINTS_BASED: GradingSchemeEditableData = {
  data: [
    {name: 'P', value: 0.5},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 4,
  pointsBased: true,
}

export const FORM_INPUT_MISSING_TITLE: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.9},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: '',
  scalingFactor: 1,
  pointsBased: false,
}

export const FORM_INPUT_OVERLAPPING_RANGES: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.8},
    {name: 'B', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 1,
  pointsBased: false,
}

export const FORM_INPUT_DUPLICATE_NAMED_RANGES: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.9},
    {name: 'A', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 1,
  pointsBased: false,
}

export const FORM_INPUT_MISSING_RANGE_NAME: GradingSchemeEditableData = {
  data: [
    {name: 'A', value: 0.9},
    {name: '', value: 0.8},
    {name: 'C', value: 0.7},
    {name: 'D', value: 0.6},
    {name: 'F', value: 0.0},
  ],
  title: 'A Grading Scheme',
  scalingFactor: 1,
  pointsBased: false,
}
