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

import '@canvas/jquery/jquery.instructure_misc_plugins'

$(document).ready(() => {
  $('.sections_list_hover').on('mouseover focus', () =>
    $('#section_list .section:first').indicate()
  )

  $('.pages_list_hover').on('mouseover focus', () => $('#section_pages').indicate())

  $('.organize_sections_hover').on('mouseover focus', () => $('.manage_sections_link').indicate())

  $('.organize_pages_hover').on('mouseover focus', () => $('.manage_pages_link').indicate())

  $('.eportfolio_settings_hover').on('mouseover focus', () =>
    $('.portfolio_settings_link').indicate()
  )

  $('.edit_content_hover').on('mouseover focus', () => $('.edit_content_link').indicate())

  $('.page_settings_hover').on('mouseover focus', () =>
    $('#edit_page_form .form_content').indicate()
  )

  $('.page_buttons_hover').on('mouseover focus', () =>
    $('#edit_page_sidebar .form_content:last').indicate()
  )

  $('.page_add_subsection_hover').on('mouseover focus', () => $('#edit_page_sidebar ul').indicate())

  $('#wizard_box').bind('wizard_opened', function () {
    $(this).find('.option.information_step').click()
  })

  $(document).bind('submission_dialog_opened', () => {
    if ($('.wizard_options .option.adding_submissions').hasClass('selected')) {
      $('.wizard_options .option.adding_submissions_dialog').click()
    }
  })

  $(document).bind('editing_page', () => {
    if ($('.wizard_options .option.edit_step').hasClass('selected')) {
      $('.wizard_options .option.editing_mode').click()
    }
  })
})
