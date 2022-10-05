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

import {useScope as useI18nScope} from '@canvas/i18n'
import initLastAttended from './react/index'
import React from 'react'
import ReactDOM from 'react-dom'
import GeneratePairingCode from '@canvas/generate-pairing-code'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/link-enrollment'

const I18n = useI18nScope('context.roster_user')

$(document).ready(() => {
  $('.show_user_services_checkbox').change(function () {
    $.ajaxJSON(
      $('.profile_url').attr('href'),
      'PUT',
      {'user[show_user_services]': $(this).prop('checked')},
      _data => {},
      _data => {}
    )
  })

  $('.unconclude_enrollment_link').click(function (event) {
    event.preventDefault()
    const $enrollment = $(this).parents('.enrollment')
    $.ajaxJSON($(this).attr('href'), 'POST', {}, _data => {
      $enrollment.find('.conclude_enrollment_link_holder').show()
      $enrollment.find('.unconclude_enrollment_link_holder').hide()
      $enrollment.find('.completed_at_holder').hide()
    })
  })

  $('.conclude_enrollment_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.enrollment')
      .confirmDelete({
        message: I18n.t('confirm.conclude', 'Are you sure you want to conclude this enrollment?'),
        url: $(this).attr('href'),
        success(data) {
          const comp_at = $.datetimeString(data.enrollment.completed_at)
          const $enrollment = $(this)
          $enrollment.undim()
          $enrollment.find('.conclude_enrollment_link_holder').hide()
          $enrollment.find('.unconclude_enrollment_link_holder').show()
          $enrollment.find('.completed_at_holder .completed_at').text(comp_at)
          $enrollment.find('.completed_at_holder').show()
        },
      })
  })

  $('.elevate_enrollment_link,.restrict_enrollment_link').click(function (event) {
    const limit = $(this).hasClass('restrict_enrollment_link') ? '1' : '0'
    const $user = $(this).parents('.tr')
    $user.loadingImage()
    $.ajaxJSON(
      $(this).attr('href'),
      'POST',
      {limit},
      _data => {
        $user.loadingImage('remove')
        $('.elevate_enrollment_link_holder,.restrict_enrollment_link_holder').slideToggle()
      },
      _data => {
        $.flashError(
          I18n.t('enrollment_change_failed', 'Enrollment privilege change failed, please try again')
        )
        $user.loadingImage('remove')
      }
    )
    event.preventDefault()
  })

  $('.delete_enrollment_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.enrollment')
      .confirmDelete({
        message: I18n.t(
          'confirm.delete_enrollment',
          'Are you sure you want to delete this enrollment?'
        ),
        url: $(this).attr('href'),
        success(_data) {
          $(this).closest('.enrollment').hide()
        },
      })
  })

  $('.more_user_information_link').click(function (event) {
    event.preventDefault()
    $('.more_user_information').slideDown()
    $(this).hide()
  })

  const lastAttendedContainer = document.getElementById('student_last_attended__component')
  if (lastAttendedContainer != null) {
    initLastAttended(lastAttendedContainer, ENV.COURSE_ID, ENV.USER_ID, ENV.LAST_ATTENDED_DATE)
  }

  const container = document.querySelector('#pairing-code')
  if (container != null) {
    ReactDOM.render(
      <GeneratePairingCode userId={ENV.USER_ID} name={ENV.CONTEXT_USER_DISPLAY_NAME} />,
      container
    )
  }
})
