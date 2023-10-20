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
import {useLocation} from 'react-router-dom'

// A custom hook that builds on useLocation to parse
// the query string for you.
function useQuery() {
  const params = new URLSearchParams(useLocation().search)
  const query = {}

  for (const key of params.keys()) {
    query[key] = params.get(key)
  }

  return query
}

export default function Query(props) {
  const query = useQuery()

  return React.cloneElement(props.children, {query})
}
