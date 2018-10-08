//
// Copyright (C) 2014 - present Instructure, Inc.
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

import confirmationMessage from 'rubric_delete_confirmation'
import 'jquery.instructure_misc_plugins'

$(document).ready(() => {
  $('#right-side .edit_rubric_link').click(event => {
    event.preventDefault()
    $('.rubric:visible:first .edit_rubric_link').click()
  })

  $('#right-side .delete_rubric_link').click(event => {
    event.preventDefault()
    const callback = () => (location.href = $('.rubrics_url').attr('href'))

    callback.confirmationMessage = confirmationMessage()

    $('.rubric:visible:first .delete_rubric_link').triggerHandler('click', callback)
  })

  $(document).fragmentChange((event, hash) => {
    if (hash === '#edit') {
      $('#right-side .edit_rubric_link').click()
    }
  })
})
