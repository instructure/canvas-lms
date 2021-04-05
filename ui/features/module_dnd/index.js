/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import ModuleFileDrop from '@canvas/context-module-file-drop'
import ready from '@instructure/ready'

ready(() => {
  const contextModules = document.getElementById('context_modules')
  const zones = document.querySelectorAll(
    '.editable_context_module:not(#context_module_blank) .module_dnd'
  )
  zones.forEach(zone => {
    ReactDOM.render(
      <ModuleFileDrop
        courseId={ENV.course_id}
        moduleId={zone.getAttribute('data-context-module-id')}
        contextModules={contextModules}
      />,
      zone
    )
  })
})
