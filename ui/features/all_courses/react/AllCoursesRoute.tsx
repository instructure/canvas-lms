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

import $ from 'jquery'
import React, {useEffect, useState} from 'react'
import {Portal} from '@instructure/ui-portal'
import AllCoursesDialog from './AllCoursesDialog'

const startupHost = window.location.host

function fetchCourses() {
  // Defense-in-depth... it's hard to see how this could happen given
  // the places in which this function is given control, but let's just
  // make absolutely sure that we never load off-application HTML into
  // the #catalog_content div.
  if (window.location.host !== startupHost) return
  $('#catalog_content').load(window.location.href)
}

function handleNav(this: HTMLElement, e: JQuery.Event) {
  let url: string
  if (!window.history.pushState) {
    return
  }
  if (this instanceof HTMLAnchorElement && this.href) {
    url = this.href
  } else if (this instanceof HTMLFormElement && this.action) {
    url = `${this.action}?${$(this).serialize()}`
  } else {
    return
  }
  window.history.pushState(null, '', url)
  fetchCourses()
  e.preventDefault()
}

function AllCoursesRoute() {
  const [isOpen, setIsOpen] = useState<boolean>(false)
  const [embeddedLink, setEmbeddedLink] = useState<string>('')

  useEffect(() => {
    $('#course_filter').submit(handleNav)
    $('#catalog_content').on('click', '#previous-link', handleNav)
    $('#catalog_content').on('click', '#next-link', handleNav)
    $('#catalog_content').on('click', '#course_summaries', handleCourseClick)
    window.addEventListener('popstate', fetchCourses)
  }, [])

  function handleCourseClick(e: JQuery.ClickEvent) {
    const link = $(e.target).closest('.course_enrollment_link')[0] as HTMLElement | undefined
    if (!link) {
      const $course = $(e.target).closest('.course_summary')
      if ($course.length && !$(e.target).is('a')) {
        const courseLink = $course.find('h3 a')[0] as HTMLElement | undefined
        if (courseLink) {
          courseLink.click()
        }
      }
      return
    } else {
      const href = (link as HTMLElement).dataset.href
      if (href) {
        setEmbeddedLink(`${href}?embedded=1&no_headers=1`)
        setIsOpen(true)
      }
    }
    e.preventDefault()
  }

  return (
    <AllCoursesDialog
      embeddedLink={embeddedLink}
      onClose={() => setIsOpen(false)}
      isOpen={isOpen}
    />
  )
}

export function Component() {
  const mountNode = document.getElementById('all_courses_dialog_mount')
  return (
    <Portal mountNode={mountNode} open={true}>
      <AllCoursesRoute />
    </Portal>
  )
}
