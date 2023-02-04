//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import '@canvas/jquery/jquery.disableWhileLoading'

export default function newCourseForm() {
  const changeEvents = 'change keyup input'
  function showCourseCodeIfNeeded() {
    if ($nameInput.val().trim().length > 20) {
      $nameInput.unbind(changeEvents, showCourseCodeIfNeeded)
      $('#course_code_wrapper').slideDown('fast')
    }
  }

  const $nameInput = $('#new_course_form [name="course[name]"]')
  $nameInput.bind(changeEvents, showCourseCodeIfNeeded)
  $('#new_course_form').submit(function (e) {
    e.preventDefault()
    this.submit() // Manually submit form before disabling it
    $(this).disableWhileLoading($.Deferred())
  })
}
