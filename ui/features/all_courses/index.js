/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import ready from '@instructure/ready'
import 'jqueryui/dialog'

const I18n = useI18nScope('catalog')

const startupHost = window.location.host

function fetchCourses() {
  // Defense-in-depth... it's hard to see how this could happen given
  // the places in which this function is given control, but let's just
  // make absolutely sure that we never load off-application HTML into
  // the #catalog_content div.
  if (window.location.host !== startupHost) return
  $('#catalog_content').load(window.location.href)
}

function handleNav(e) {
  let url
  if (!window.history.pushState) {
    return
  }
  if (this.href) {
    url = this.href
  } else {
    url = `${this.action}?${$(this).serialize()}`
  }
  window.history.pushState(null, '', url)
  fetchCourses()
  e.preventDefault()
}

function handleCourseClick(e) {
  const link = $(e.target).closest('.course_enrollment_link')[0]
  if (!link) {
    const $course = $(e.target).closest('.course_summary')
    if ($course.length && !$(e.target).is('a')) {
      $course.find('h3 a')[0].click()
    }
    return
  }
  const $dialog = $('<div>')
  const $iframe = $('<iframe>', {
    style: 'position:absolute;top:0;left:0;width:100%;height:100%;border:none',
    src: `${link.href}?embedded=1&no_headers=1`,
    title: I18n.t('Course Catalog'),
  })
  $dialog.append($iframe)
  $dialog.dialog({
    width: 550,
    height: 500,
    resizable: false,
    modal: true,
    zIndex: 1000,
  })
  e.preventDefault()
}

ready(() => {
  $('#course_filter').submit(handleNav)
  $('#catalog_content').on('click', '#previous-link', handleNav)
  $('#catalog_content').on('click', '#next-link', handleNav)
  $('#catalog_content').on('click', '#course_summaries', handleCourseClick)
  window.addEventListener('popstate', fetchCourses)
})
