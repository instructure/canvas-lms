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

import confirmationMessage from '@canvas/rubrics/jquery/rubric_delete_confirmation'
import '@canvas/outcomes/find_outcome'
import '@canvas/jquery/jquery.instructure_misc_plugins'

$(document).ready(() =>
  $('#rubrics ul .delete_rubric_link').click(function (event) {
    event.preventDefault()
    const $rubric = $(this).parents('li')
    return $rubric.confirmDelete({
      url: $(this).attr('href'),
      message: confirmationMessage(),
      success() {
        $(this).slideUp(function () {
          $(this).remove()
        })
      },
    })
  })
)
