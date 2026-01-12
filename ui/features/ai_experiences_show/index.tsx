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

import ready from '@instructure/ready'
import React from 'react'
import {render} from '@canvas/react'
import {AIExperiencesShow} from './react'

ready(() => {
  // Remove default Canvas content padding
  const contentMain = document.querySelector('#content') as HTMLElement | null
  if (contentMain) {
    contentMain.style.padding = '0'
  }

  const container = document.getElementById('ai_experiences_show')
  if (container) {
    // Get AI experience data from ENV
    const aiExperience = ENV.AI_EXPERIENCE
    const navbarHeight = ENV.NAVBAR_HEIGHT || 0

    if (aiExperience) {
      render(
        <AIExperiencesShow aiExperience={aiExperience} navbarHeight={navbarHeight} />,
        container,
      )
    }
  }
})
