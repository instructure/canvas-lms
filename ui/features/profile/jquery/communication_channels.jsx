/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import 'jqueryui/tabs'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import RegisterCommunication from '../react/RegisterCommunication'
import ConfirmCommunicationChannel from '../react/ConfirmCommunicationChannel'
import ConfirmEmailAddress from '../react/ConfirmEmailAddress'
import ResendConfirmation from '../react/ResendConfirmation'

const I18n = createI18nScope('profile')

$(document).ready(function () {
  $('.channel_list tr').hover(
    function () {
      if ($(this).hasClass('unconfirmed')) {
        let title = I18n.t(
          'titles.contact_not_confirmed',
          'This contact has not been confirmed.  Click the address for more details',
        )
        if ($(this).closest('.email_channels').length > 0) {
          title = I18n.t(
            'titles.email_not_confirmed',
            'This email has not been confirmed.  Click the address for more details',
          )
        }
        $(this).attr('title', title)
        $(this).find('a.path').parent().attr('title', title)
      }
    },
    function () {
      $(this).attr('title', '')
      $(this).find('a.path').parent().attr('title', $(this).find('a.path').text())
    },
  )

  const registerCommunicationForm = {
    beforeSubmit: (address, type) => {
      let $list = $('.email_channels')
      if (['sms', 'slack'].includes(type)) {
        $list = $('.other_channels')
      }
      let path = address
      $list.find('.channel .path').each(function () {
        if ($(this).text() === path) {
          path = ''
        }
      })
      $list.removeClass('single')
      let $channel = null
      if (path) {
        $channel = $list.find('.channel.blank').clone(true).removeClass('blank')
        if (type === 'slack') {
          $channel.find('#communication_text_type').text('slack')
        }
        $channel
          .find('.path')
          .attr(
            'title',
            I18n.t('titles.unconfirmed_click_to_confirm', 'Unconfirmed.  Click to confirm'),
          )
        $channel.fillTemplateData({
          data: {path},
        })
        $list.find('.channel.blank').before($channel.show())
      } else {
        throw new Error(I18n.t('This contact information is already registered.'))
      }
      $channel.loadingImage({image_size: 'small'})
      return $channel
    },
    sendRequest: async (address, type, enableEmailLogin) => {
      const body = {
        communication_channel: {address, type},
      }

      if (enableEmailLogin) {
        body.build_pseudonym = enableEmailLogin
      }

      const {json} = await doFetchApi({
        path: `/communication_channels`,
        method: 'POST',
        body,
      })

      return json
    },
    success: (channel, $channel) => {
      $channel.loadingImage('remove')

      channel.channel_id = channel.id
      let select_type = 'email_select'
      if (channel.type === 'sms') {
        select_type = 'sms_select'
      }
      const $select = $('#select_templates .' + select_type)
      const $option = $(document.createElement('option'))
      $option.val(channel.id).text(channel.address)
      $select.find('option:last').before($option)
      $select.find('option.blank_option').remove()
      $('.' + select_type).each(function () {
        let val = $(this).val()
        if (val === 'new') {
          val = channel.id
        }
        $(this).after($select.clone(true).val(val)).remove()
      })
      $channel.fillTemplateData({
        data: channel,
        id: 'channel_' + channel.id,
        hrefValues: ['user_id', 'pseudonym_id', 'channel_id'],
      })
      $channel.find('.path').triggerHandler('click')
    },
  }

  $('.add_email_link, .add_contact_link').on('click', function (event) {
    event.preventDefault()

    const mountPoint = document.getElementById('register_communication_mount_point')
    const target = event.target
    const addContactLinkClicked = target.classList.contains('add_contact_link')
    const availableTabs = ENV.register_cc_tabs ?? ['email']
    const isDefaultAccount = ENV.is_default_account ?? false
    const initiallySelectedTab =
      availableTabs.includes('sms') && addContactLinkClicked ? 'sms' : 'email'
    const root = createRoot(mountPoint)

    root.render(
      <RegisterCommunication
        initiallySelectedTab={initiallySelectedTab}
        availableTabs={availableTabs}
        isDefaultAccount={isDefaultAccount}
        onSubmit={async (address, type, enableEmailLogin) => {
          let channelElement
          try {
            channelElement = registerCommunicationForm.beforeSubmit(address, type)
            root.unmount()
          } catch (error) {
            showFlashError(error.message)()
            throw error
          }
          try {
            const channel = await registerCommunicationForm.sendRequest(
              address,
              type,
              enableEmailLogin,
            )
            registerCommunicationForm.success(channel, channelElement)
          } catch {
            channelElement?.loadingImage('remove')
            channelElement?.remove()
            showFlashError()()
          }
        }}
        onClose={() => {
          root.unmount()
          target.focus()
        }}
      />,
    )
  })

  const manageAfterDeletingAnEmailFocus = function (currentElement) {
    // There may be a better way to do this but I'm not aware of another way. I'm trying to
    // find the closest prev() or next() sibling
    let $elementToFocusOn = $(currentElement).next('.channel:not(.blank)').last()
    if (!$elementToFocusOn.length) {
      $elementToFocusOn = $(currentElement).prev('.channel:not(.blank)').last()
    }

    if ($elementToFocusOn.length) {
      $elementToFocusOn.find('.email_channel').first().focus()
    } else {
      $(this).parents('.channel_list .email_channel').first().focus()
    }
  }

  $('.channel_list .channel .delete_channel_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.channel')
      .confirmDelete({
        url: $(this).attr('href'),
        success(_data) {
          const $list = $(this).parents('.channel_list')
          manageAfterDeletingAnEmailFocus(this)
          $(this).remove()
          $list.toggleClass('single', $list.find('.channel:visible').length <= 1)
        },
      })
  })
  $('.channel_list .channel .reset_bounce_count_link').click(function (event) {
    event.preventDefault()
    $.ajaxJSON($(this).attr('href'), 'POST', {}, _data => {
      $(this).parents('.channel').find('.bouncing-channel').remove()
      $(this).remove()
      $.flashMessage(I18n.t('Bounce count reset!'))
    })
  })

  const confirmCommunicationChannelForm = {
    success: data => {
      const channelElement = $('#channel_' + data.communication_channel.id)
      channelElement.removeClass('unconfirmed')
      channelElement.find('.confirm_channel_link').remove()

      const pseudonym_id = data.communication_channel.pseudonym_id
      $('.channel.pseudonym_' + pseudonym_id).removeClass('unconfirmed')

      showFlashSuccess(I18n.t('notices.contact_confirmed', 'Contact successfully confirmed!'))()
    },
    error: () => {
      showFlashError(I18n.t('Confirmation failed. Please try again.'))()
    },
  }

  $('.email_channels .channel .path,.other_channels .channel .path').click(function (event) {
    event.preventDefault()
    const $channel = $(this).parents('.channel')
    if ($channel.hasClass('unconfirmed')) {
      const {user_id, channel_id, pseudonym_id} = $channel.getTemplateData({
        textValues: ['user_id', 'pseudonym_id', 'channel_id'],
      })
      const isCommunicationListItemClicked = $(this)
        .parents('.channel_list')
        .hasClass('other_channels')
      const resendConfirmation = <ResendConfirmation userId={user_id} channelId={channel_id} />

      if (isCommunicationListItemClicked) {
        const mountPoint = document.getElementById('confirm_communication_channel_mount_point')
        const root = createRoot(mountPoint)
        const smsOrEmail = event.target.innerText

        root.render(
          <ConfirmCommunicationChannel
            communicationChannel={{user_id, pseudonym_id, channel_id}}
            phoneNumberOrEmail={smsOrEmail}
            onSubmit={data => {
              confirmCommunicationChannelForm.success(data)

              root.unmount()
            }}
            onClose={() => root.unmount()}
            onError={() => confirmCommunicationChannelForm.error()}
          >
            {resendConfirmation}
          </ConfirmCommunicationChannel>,
        )
      } else {
        const mountPoint = document.getElementById('confirm_email_address_mount_point')
        const root = createRoot(mountPoint)
        const email = event.target.innerText

        root.render(
          <ConfirmEmailAddress
            email={email}
            onClose={() => {
              root.unmount()
            }}
          >
            {resendConfirmation}
          </ConfirmEmailAddress>,
        )
      }
    }
  })

  $('.channel_list .channel .default_link').click(function (event) {
    event.preventDefault()
    const channel_id = $(this)
      .parents('.channel')
      .getTemplateData({textValues: ['channel_id']}).channel_id
    const formData = {
      default_email_id: channel_id,
    }
    $.ajaxJSON($(this).attr('href'), 'PUT', formData, data => {
      const channel_id_ = data.user.communication_channel.id
      $('.channel.default')
        .removeClass('default')
        .find('a.default_link span.screenreader-only.default_label')
        .remove()
      $('.channel#channel_' + channel_id_)
        .addClass('default')
        .find('a.default_link')
        .append(
          $('<span class="screenreader-only" />').text(I18n.t('This is the default email address')),
        )
      $('.default_email.display_data').text(data.user.communication_channel.path)
    })
  })
})
