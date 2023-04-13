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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ContextModulesPublishMenu from '@canvas/context-modules/react/ContextModulesPublishMenu'
import ready from '@instructure/ready'

ready(() => {
  const menuElement = document.getElementById('context-modules-publish-menu')
  if (menuElement) {
    const $menuElement = $(menuElement)
    ReactDOM.render(
      <ContextModulesPublishMenu
        courseId={$menuElement.data('courseId')}
        runningProgressId={$menuElement.data('progressId')}
        disabled={$menuElement.data('disabled')}
      />,
      menuElement
    )
  }
})
