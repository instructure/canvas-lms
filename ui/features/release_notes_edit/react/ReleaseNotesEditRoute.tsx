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

import React from 'react'
import {Portal} from '@instructure/ui-portal'
import ReleaseNotesEdit from '.'

export function Component(): JSX.Element | null {
  const mountPoint = document.getElementById('content')
  if (mountPoint === null) {
    console.error('Cannot render release notes editor, container is missing')
    return null
  }
  return (
    <Portal open={true} mountNode={mountPoint}>
      <ReleaseNotesEdit
        envs={window.ENV.release_notes_envs ?? ['development']}
        langs={window.ENV.release_notes_langs ?? ['en']}
      />
    </Portal>
  )
}
