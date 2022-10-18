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
import {arrayOf, bool, object, oneOf, shape, string} from 'prop-types'

export const linkShape = shape({
  href: string.isRequired,
  title: string.isRequired,
  published: bool,
  date: string,
  date_type: string,
  has_overrides: bool,
})

export const linksShape = shape({
  hasMore: bool,
  isLoading: bool,
  lastError: object,
  links: arrayOf(linkShape).isRequired,
})

export const linkType = oneOf([
  'assignments',
  'discussions',
  'modules',
  'quizzes',
  'announcements',
  'wikiPages',
  'navigation',
])

export const collectionsShape = shape({
  announcements: linksShape,
  assignments: linksShape,
  discussions: linksShape,
  modules: linksShape,
  quizzes: linksShape,
  wikiPages: linksShape,
})
