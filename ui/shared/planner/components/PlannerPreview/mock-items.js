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

import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('planner')

const COMMON_PROPS = {
  date: moment().hour(23).minute(59),
  dateStyle: 'due',
  points: 100,
  status: {},
  readOnly: true,
}

const MATH_CONTEXT = {
  id: 'Math',
  type: 'Course',
  title: I18n.t('Math'),
  color: '#BF32A4',
}

export const SINGLE_COURSE_ITEMS = [
  {
    ...COMMON_PROPS,
    id: '1',
    uniqueId: 'assignment-1',
    context: MATH_CONTEXT,
    title: I18n.t('A wonderful assignment'),
    type: 'Assignment',
  },
  {
    ...COMMON_PROPS,
    id: '2',
    uniqueId: 'assignment-2',
    context: MATH_CONTEXT,
    title: I18n.t('The best assignment'),
    type: 'Assignment',
  },
  {
    ...COMMON_PROPS,
    id: '3',
    uniqueId: 'discussion-3',
    context: MATH_CONTEXT,
    title: I18n.t('A great discussion'),
    type: 'Discussion',
  },
]

export const MULTI_COURSE_ITEMS = [
  ...SINGLE_COURSE_ITEMS,
  {
    ...COMMON_PROPS,
    id: '3',
    uniqueId: 'discussion-3',
    context: {
      id: 'Science',
      type: 'Course',
      title: I18n.t('Science'),
      color: '#69B8DE',
    },
    title: I18n.t('An amazing discussion assignment'),
    type: 'Discussion',
  },
  {
    ...COMMON_PROPS,
    id: '4',
    uniqueId: 'quiz-4',
    context: {
      id: 'Lang Arts',
      type: 'Course',
      title: I18n.t('Language Arts'),
      color: '#E1AF52',
    },
    title: I18n.t('Fun quiz'),
    type: 'Quiz',
  },
  {
    ...COMMON_PROPS,
    id: '5',
    uniqueId: 'discussion-5',
    context: {
      id: 'Soc Studies',
      type: 'Course',
      title: I18n.t('Social Studies'),
      color: '#0081D3',
    },
    title: I18n.t('Exciting discussion'),
    type: 'Discussion',
  },
]
