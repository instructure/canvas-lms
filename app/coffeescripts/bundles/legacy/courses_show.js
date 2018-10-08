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

import I18n from 'i18n!courses.show'
import htmlEscape from 'str/htmlEscape'
import 'jsx/courses/show'
import 'jquery.ajaxJSON'
import 'jqueryui/dialog'
import '../../jquery/fixDialogButtons'
import 'jquery.loadingImg'
import 'vendor/jquery.scrollTo'
import '../../behaviors/openAsDialog'

$(document).ready(() => {
  const $selfUnenrollmentDialog = $('#self_unenrollment_dialog')
  $('.self_unenrollment_link').click(event =>
    $selfUnenrollmentDialog
      .dialog({title: I18n.t('titles.drop_course', 'Drop this Course')})
      .fixDialogButtons()
  )

  $selfUnenrollmentDialog.on('click', '.action', function() {
    $selfUnenrollmentDialog.disableWhileLoading($.Deferred())
    $.ajaxJSON($(this).attr('href'), 'POST', {}, () => window.location.reload())
  })

  $('.re_send_confirmation_link').click(function(event) {
    event.preventDefault()
    const $link = $(this)
    $link.text(I18n.t('re_sending', 'Re-Sending...'))
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      data => $link.text(I18n.t('send_done', 'Done! Message may take a few minutes.')),
      data => $link.text(I18n.t('send_failed', 'Request failed. Try again.'))
    )
  })

  $('.home_page_link').click(function(event) {
    event.preventDefault()
    const $link = $(this)
    $('.floating_links').hide()
    $('#course_messages').slideUp(() => $('.floating_links').show())

    $('#home_page')
      .slideDown()
      .loadingImage()
    $link.hide()
    $.ajaxJSON($(this).attr('href'), 'GET', {}, data => {
      $('#home_page').loadingImage('remove')
      let bodyHtml = htmlEscape($.trim(data.wiki_page.body))
      if (bodyHtml.length === 0) {
        bodyHtml = htmlEscape(I18n.t('empty_body', 'No Content'))
      }
      $('#home_page_content').html(bodyHtml)
      $('html,body').scrollTo($('#home_page'))
    })
  })

  $('.dashboard_view_link').click(event => {
    event.preventDefault()
    $('.floating_links').hide()
    $('#course_messages').slideDown(() => $('.floating_links').show())

    $('#home_page').slideUp()
    $('.home_page_link').show()
  })

  $('.publish_course_in_wizard_link').click(event => {
    event.preventDefault()
    if ($('#wizard_box:visible').length > 0) {
      $('#wizard_box .option.publish_step').click()
    } else {
      $('#wizard_box').slideDown('slow', function() {
        $(this)
          .find('.option.publish_step')
          .click()
      })
    }
  })
})
