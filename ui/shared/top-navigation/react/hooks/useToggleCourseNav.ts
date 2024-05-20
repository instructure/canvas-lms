/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'

// import {setSetting} from 'features/navigation_header/react/queries/settingsQuery'

interface IUseToggleCourseNav {
  toggle: () => boolean
}

const useToggleCourseNav = (): IUseToggleCourseNav => {
  const body = document.querySelector('body')
  const leftSideElement = document.getElementById('left-side')
  const WIDE_BREAKPOINT = 1200

  const toggle = (): boolean => {
    const sectionTabLinks = document.querySelectorAll('#section-tabs li a')
    const stickyFrame = document.querySelector('#left-side #sticky-container')

    body?.classList.toggle('course-menu-expanded')

    const isCourseMenuExpanded = body?.classList.contains('course-menu-expanded')
    if (leftSideElement) {
      leftSideElement.style.display = isCourseMenuExpanded ? 'block' : 'none'
    }

    // could be moved to another function
    if (sectionTabLinks?.length) {
      const tabIndex = isCourseMenuExpanded || window.innerWidth >= WIDE_BREAKPOINT - 15 ? 0 : -1
      sectionTabLinks.forEach(link => {
        link.setAttribute('tabindex', tabIndex.toString())
      })
    }

    if (stickyFrame) {
      const menuPaddingBotton = parseInt(window.getComputedStyle(stickyFrame).paddingBottom, 10)
      const menuPaggingTop = parseInt(window.getComputedStyle(stickyFrame).paddingTop, 10)

      const menuHeight = stickyFrame.scrollHeight - menuPaddingBotton - menuPaggingTop

      if (menuHeight > stickyFrame.clientHeight) {
        stickyFrame.classList.add('has-scrollbar')
      } else {
        stickyFrame.classList.remove('has-scrollbar')
      }
    }

    return !!isCourseMenuExpanded
    // setSetting({setting: 'collapse_course_nav', newState: !isCourseMenuExpanded})

    // TO DO: Update aria-label for hamburger button (evaluate options)
  }

  return {
    toggle,
  }
}

export default useToggleCourseNav
