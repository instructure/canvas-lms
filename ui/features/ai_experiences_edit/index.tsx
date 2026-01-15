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

import {AIExperiencesEdit} from './react/index'
import ready from '@instructure/ready'
import React from 'react'
import {render} from '@canvas/react'
import {Portal} from '@instructure/ui-portal'
import {AIExperience} from './types'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

declare const ENV: GlobalEnv & {
  AI_EXPERIENCE?: AIExperience
}

function AIExperiencePageLayout({navbarHeight}: {navbarHeight: number}) {
  const aiExperience = ENV.AI_EXPERIENCE

  return (
    <Portal open={true} mountNode={document.getElementById('content')}>
      <div id="ai-experience-edit-layout" className="ai-experience-edit-layout">
        <AIExperiencesEdit aiExperience={aiExperience} navbarHeight={navbarHeight} />
      </div>
    </Portal>
  )
}

ready(() => {
  document.querySelector('body')?.classList.add('full-width')
  document.querySelector('div.ic-Layout-contentMain')?.classList.remove('ic-Layout-contentMain')
  const navbar = document.querySelector('.ic-app-nav-toggle-and-crumbs.no-print')
  navbar?.setAttribute('style', 'margin: 0 0 0 24px')
  const navbarHeight = navbar?.getBoundingClientRect().height ?? 72

  setTimeout(() => {
    const container = document.getElementById('content')
    if (container) {
      render(<AIExperiencePageLayout navbarHeight={navbarHeight} />, container)
    }
  })
})
