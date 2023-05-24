// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import ContextModulesPublishIcon from '@canvas/context-modules/react/ContextModulesPublishIcon'
import ready from '@instructure/ready'

ready(() => {
  const menuElements = document.getElementsByClassName(
    'module-publish-icon'
  ) as HTMLCollectionOf<HTMLElement> // eslint-disable-line no-undef
  Array.from(menuElements).forEach(el => {
    const courseId = el.getAttribute('data-course-id')
    const moduleId = el.getAttribute('data-module-id')
    const moduleName = el.closest('.context_module').querySelector('.ig-header-title').textContent
    const published = el.getAttribute('data-published') === 'true'
    ReactDOM.render(
      <ContextModulesPublishIcon
        courseId={courseId}
        moduleId={moduleId}
        moduleName={moduleName}
        published={published}
        isPublishing={false}
        disabled={false}
      />,
      el
    )
  })
})
