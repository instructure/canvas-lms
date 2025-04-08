/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Portal} from '@instructure/ui-portal'
import {useParams} from 'react-router-dom'
import SearchApp from './SearchApp'
import EnhancedSmartSearch from './enhanced_ui/EnhancedSmartSearch'

export function Component(): JSX.Element | null {
  const {courseId} = useParams()
  const mountPoint = document.getElementById('search_app')
  if (mountPoint === null) {
    console.error('Cannot render SearchRoute, container is missing')
    return null
  }

  if (ENV.enhanced_ui_enabled) {
    return (
      <Portal open={true} mountNode={mountPoint}>
        <EnhancedSmartSearch courseId={courseId ?? ''} />
      </Portal>
    )
  }
  return (
    <Portal open={true} mountNode={mountPoint}>
      <SearchApp courseId={courseId} />
    </Portal>
  )
}
