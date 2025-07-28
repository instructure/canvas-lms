/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const RESOURCE_TYPES = [
  'assignment',
  'audio',
  'discussion_topic',
  'document',
  'image',
  'module',
  'quiz',
  'page',
  'video',
]
const RESOURCE_TYPES_WITH_QUIZZESNEXT = [...RESOURCE_TYPES, 'quizzesnext']

const QUIZ_TYPES = ['quiz']
const QUIZ_TYPES_WITH_QUIZZESNEXT = [...QUIZ_TYPES, 'quizzesnext']

const isNewQuizzesMediaTypeEnabled = () => ENV.FEATURES?.new_quizzes_media_type

export const getResourceTypes = () => {
  return isNewQuizzesMediaTypeEnabled() ? RESOURCE_TYPES_WITH_QUIZZESNEXT : RESOURCE_TYPES
}

export const getQuizTypes = () => {
  return isNewQuizzesMediaTypeEnabled() ? QUIZ_TYPES_WITH_QUIZZESNEXT : QUIZ_TYPES
}
