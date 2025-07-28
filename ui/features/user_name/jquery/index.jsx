/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import React from 'react'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit */
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'
import ready from '@instructure/ready'
import EditUserDetails from '../react/EditUserDetails'

import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'

const I18n = createI18nScope('user_name')

ready(function () {
  $('#name_and_email').on('click', '.edit_user_link', event => {
    event.preventDefault()

    const mountPoint = document.getElementById('edit_user_details_mount_point')

    if (!mountPoint) {
      // This case happens when the page/partial is read only. See _name.html.erb "@read_only".
      return
    }

    const root = createRoot(mountPoint)
    const userId = ENV.USER_ID
    const canManageUserDetails = ENV.PERMISSIONS.can_manage_user_details
    const timezones = ENV.TIMEZONES
    const defaultTimezoneName = ENV.DEFAULT_TIMEZONE_NAME
    const userDetails = $('#name_and_email .user_details').getTemplateData({
      textValues: ['name', 'email', 'short_name', 'sortable_name', 'time_zone'],
    })
    const closeModal = () => {
      root.unmount()
      event.target.focus()
    }

    root.render(
      <EditUserDetails
        userId={userId}
        userDetails={{
          ...userDetails,
          time_zone:
            userDetails.time_zone === I18n.t('None') ? defaultTimezoneName : userDetails.time_zone,
        }}
        timezones={timezones}
        canManageUserDetails={canManageUserDetails}
        onSubmit={data => {
          $('#name_and_email .user_details').fillTemplateData({data})

          closeModal()
        }}
        onClose={() => closeModal()}
      />,
    )
  })
  $('.remove_avatar_picture_link').on('click', async function (event) {
    event.preventDefault()
    const $link = $(this)
    const result = await showConfirmationDialog({
      label: I18n.t('Confirm Removal'),
      body: I18n.t(
        'confirms.remove_profile_picture',
        "Are you sure you want to remove this user's profile picture?",
      ),
    })
    if (!result) {
      return
    }
    $link.text(I18n.t('messages.removing_image', 'Removing image...'))
    $.ajaxJSON(
      $link.attr('href'),
      'PUT',
      {'avatar[state]': 'none'},
      _data => {
        $link.parents('tr').find('.avatar_image').remove()
        $link.remove()
      },
      _data => {
        $link.text(
          I18n.t('errors.failed_to_remove_image', 'Failed to remove the image, please try again'),
        )
      },
    )
  })
  $('.report_avatar_picture_link').on('click', function (event) {
    event.preventDefault()
    event.preventDefault()
    const $link = $(this)
    $link.text(I18n.t('messages.reporting_image', 'Reporting image...'))
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      _data => {
        $link.after(htmlEscape(I18n.t('notices.image_reported', 'This image has been reported')))
        $link.remove()
      },
      _data => {
        $link.text(
          I18n.t('errors.failed_to_report_image', 'Failed to report the image, please try again'),
        )
      },
    )
  })
  $('.clear_user_cache_link').on('click', function (event) {
    event.preventDefault()
    const $link = $(this)
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      _data => {
        $.flashMessage(I18n.t('Cache cleared successfully'))
      },
      _data => {
        $.flashMessage(I18n.t('Failed to clear cache'))
      },
    )
  })
  $('.destroy_user_link').on('click', async function (event) {
    event.preventDefault()
    const result = await showConfirmationDialog({
      label: I18n.t('Confirm Deletion'),
      body: I18n.t(
        'Are you sure you want to remove this user from ALL accounts? The user will not only be deleted, but will be marked for PERMANENT deletion.',
      ),
    })
    if (!result) {
      return
    }
    const $link = $(this)
    $.ajaxJSON(
      $link.attr('href'),
      'DELETE',
      {delete_me_frd: true},
      _data => {
        $.flashMessage(I18n.t('User removed successfully'))
      },
      _data => {
        $.flashMessage(I18n.t('Failed to remove user'))
      },
    )
  })
})
