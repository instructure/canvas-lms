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
import React from 'react'

export const AUTO_MARK_AS_READ_DELAY = 3000
export const CURRENT_USER = 'current_user'
export const HIGHLIGHT_TIMEOUT = 6000
export const SEARCH_TERM_DEBOUNCE_DELAY = 500
export const DEFAULT_AVATAR_URL = 'http://canvas.instructure.com/images/messages/avatar-50.png'

const searchFilter = {
  searchTerm: '',
  setSearchTerm: () => {},
  filter: '',
  setFilter: () => {},
  sort: '',
  setSort: () => {},
  pageNumber: 0,
  setPageNumber: () => {},
}
export const SearchContext = React.createContext(searchFilter)

const discussionManagerUtilityContext = {
  replyFromId: '',
  setReplyFromId: () => {},
}

export const DiscussionManagerUtilityContext = React.createContext(discussionManagerUtilityContext)
