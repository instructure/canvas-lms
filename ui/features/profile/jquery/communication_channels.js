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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import 'jqueryui/tabs'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('profile')

$(document).ready(function () {
  $('#communication_channels')
    .tabs()
    .on('tabsactivate', function (_event, ui) {
      // check if the tabs are visible
      if ($(this).css('display') !== 'none') {
        // pass id of the active tab panel
        formatTabs(ui.newPanel.attr('id'))
      }
    })

  $('.channel_list tr').hover(
    function () {
      if ($(this).hasClass('unconfirmed')) {
        let title = I18n.t(
          'titles.contact_not_confirmed',
          'This contact has not been confirmed.  Click the address for more details'
        )
        if ($(this).closest('.email_channels').length > 0) {
          title = I18n.t(
            'titles.email_not_confirmed',
            'This email has not been confirmed.  Click the address for more details'
          )
        }
        $(this).attr('title', title)
        $(this).find('a.path').parent().attr('title', title)
      }
    },
    function () {
      $(this).attr('title', '')
      $(this).find('a.path').parent().attr('title', $(this).find('a.path').text())
    }
  )

  $('.add_email_link, .add_contact_link').on('click', function (event) {
    const $communicationChannels = $('#communication_channels')
    const $registerSmsNumber = $('#register_sms_number')
    event.preventDefault()
    $communicationChannels.show().dialog({
      title: I18n.t('titles.register_communication', 'Register Communication'),
      width: 600,
      resizable: false,
      modal: true,
      zIndex: 1000,
    })

    // if user clicked add contact link and sms number tab exists, show it (otherwise show email tab)
    const tabIndex =
      $(this).hasClass('add_contact_link') && $registerSmsNumber.length > 0
        ? $communicationChannels.find('a[href="#register_sms_number"]').parent().index()
        : 0

    $communicationChannels.tabs('option', 'active', tabIndex)
    $communicationChannels.find('ul.ui-tabs-nav > li').eq(tabIndex).find('a').trigger('focus')
  })

  const formatTabs = function (id) {
    const $form = $('#' + id)
    if (!$form.length) return
    if (id === 'register_sms_number') {
      // convert number from 555-555-5555 to 5555555555
      const sms_number = $form.find('.sms_number').val().replace(/\D/g, '')
      // update the form input with only digits
      $form.find('.sms_number').val(sms_number)
      // display an error message if the number is not 10 digits
      $form.find('.should_be_10_digits').showIf(sms_number && sms_number.length !== 10)
    }
  }

  const $smsNumber = $('#register_sms_number .user_selected')
  if ($smsNumber.length > 0) {
    $smsNumber.on('change blur keyup focus', function () {
      formatTabs('register_sms_number')
    })
  }

  $('#register_sms_number,#register_email_address,#register_slack_handle').formSubmit({
    object_name: 'communication_channel',
    processData(data) {
      let address
      let type
      if (data['communication_channel[type]'] === 'email') {
        type = 'email'
        address = data.communication_channel_email
      } else if (data['communication_channel[type]'] === 'slack') {
        type = 'slack'
        address = data.communication_channel_slack
      } else {
        // sms channel using a phone number in the USA
        type = 'sms_number'
        address = data.communication_channel_sms_number
      }

      if (type === 'email' || type === 'slack') {
        // Make sure it's a valid email address
        const match = address.match(
          /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
        )
        if (!match) {
          // Not a valid email address. Show a message on the relevant field, then bail.
          const errorMessage =
            address === '' ? I18n.t('Email is required') : I18n.t('Email is invalid!')
          if (type === 'email') {
            $(this).formErrors({communication_channel_email: errorMessage})
          }
          return false
        }
      } else {
        // Make sure it's a valid phone number. Validate the phone number they typed instead of the address because
        // the address will already have the country code prepended, and this will result in our regex failing always
        // because it's not expecting the leading plus sign (and it can't just be added to the regex because then
        // we can't detect when they entered a blank phone number). libphonenumber plz
        const match = data.communication_channel_sms_number.match(/^[0-9]+$/)
        if (!match) {
          const errorMessage =
            address === '' ? I18n.t('Cell Number is required') : I18n.t('Cell Number is invalid!')
          $(this).formErrors({communication_channel_sms_number: errorMessage})
          return false
        }
      }

      // Don't need these anymore
      delete data.communication_channel_sms_number
      delete data.communication_channel_slack

      data['communication_channel[address]'] = address
    },
    beforeSubmit(data) {
      let $list = $('.email_channels')
      if (
        $(this).attr('id') === 'register_sms_number' ||
        $(this).attr('id') === 'register_slack_handle'
      ) {
        $list = $('.other_channels')
      }
      let path = data['communication_channel[address]']
      $(this).data('email', path)
      $list.find('.channel .path').each(function () {
        if ($(this).text() === path) {
          path = ''
        }
      })
      $list.removeClass('single')
      let $channel = null
      if (path) {
        $channel = $list.find('.channel.blank').clone(true).removeClass('blank')
        if (data['communication_channel[type]'] === 'slack') {
          $channel.find('#communication_text_type').text('slack')
        }
        $channel
          .find('.path')
          .attr(
            'title',
            I18n.t('titles.unconfirmed_click_to_confirm', 'Unconfirmed.  Click to confirm')
          )
        $channel.fillTemplateData({
          data: {path},
        })
        $list.find('.channel.blank').before($channel.show())
      }
      if (!path) {
        return false
      }
      $('#communication_channels').dialog('close')
      $('#communication_channels').hide()
      $channel.loadingImage({image_size: 'small'})
      return $channel
    },
    success(channel, $channel) {
      $('#communication_channels').dialog('close')
      $('#communication_channels').hide()
      $channel.loadingImage('remove')

      channel.channel_id = channel.id
      let select_type = 'email_select'
      if ($(this).attr('id') === 'register_sms_number') {
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
    error(data, $channel) {
      $channel.loadingImage('remove')
      $channel.remove()
    },
  })
  $(document).on('click', 'a.email_address_taken_learn_more', event => {
    event.preventDefault()
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
  $('#confirm_communication_channel .cancel_button').click(_event => {
    $('#confirm_communication_channel').dialog('close')
  })
  $('.email_channels .channel .path,.other_channels .channel .path').click(function (event) {
    event.preventDefault()
    const $channel = $(this).parents('.channel')
    if ($channel.hasClass('unconfirmed')) {
      let type = 'email address',
        confirm_title = I18n.t('titles.confirm_email_address', 'Confirm Email Address')
      if ($(this).parents('.channel_list').hasClass('other_channels')) {
        type = 'sms number'
        confirm_title = I18n.t('Confirm Communication Channel')
      }
      let $box = $('#confirm_communication_channel')

      if ($channel.parents('.email_channels').length > 0) {
        $box = $('#confirm_email_channel')
      }
      const data = $channel.getTemplateData({textValues: ['user_id', 'pseudonym_id', 'channel_id']})
      let path = $(this).text()

      $.ajaxJSON(
        `/confirmations/${data.user_id}/limit_reached/${data.channel_id}`,
        'GET',
        {},
        data_ => {
          if (data_.confirmation_limit_reached) {
            $box.find('.re_send_confirmation_link').css('visibility', 'hidden')
          } else {
            $box.find('.re_send_confirmation_link').css('visibility', 'visible')
          }
        },
        _ => {}
      )

      if (type === 'sms number') {
        path = path.split('@')[0]
      }
      data.code = ''

      $box.fillTemplateData({
        data: {
          path,
          path_type: type,
          user_id: data.user_id,
          channel_id: data.channel_id,
        },
      })
      $box.find('.status_message').css('visibility', 'hidden')
      let url = $('.re_send_confirmation_url').attr('href')
      url = replaceTags(url, 'id', data.channel_id)
      url = replaceTags(url, 'pseudonym_id', data.pseudonym_id)
      url = replaceTags(url, 'user_id', data.user_id)

      $box
        .find('.re_send_confirmation_link')
        .attr('href', url)
        .text(I18n.t('links.resend_confirmation', 'Re-Send Confirmation'))
      $box.fillFormData(data)
      $box.show().dialog({
        title: confirm_title,
        width: 350,
        open() {
          $(this).closest('.ui-dialog').focus()
        },
      })
    }
  })
  $('#confirm_communication_channel').formSubmit({
    formErrors: false,
    processData(data) {
      let url = $(this).find('.register_channel_link').attr('href')
      url = replaceTags(url, 'id', data.channel_id)
      url = replaceTags(url, 'code', data.code)
      $(this).attr('action', url)
    },
    beforeSubmit(_data) {
      $(this)
        .find('.status_message')
        .text(I18n.t('confirming_contact', 'Confirming...'))
        .css('visibility', 'visible')
    },
    success(data) {
      $(this).find('.status_message').css('visibility', 'hidden')
      const pseudonym_id = data.communication_channel.pseudonym_id
      $('#channel_' + data.communication_channel.id).removeClass('unconfirmed')
      $('.channel.pseudonym_' + pseudonym_id).removeClass('unconfirmed')
      $('#confirm_communication_channel').dialog('close')
      $.flashMessage(I18n.t('notices.contact_confirmed', 'Contact successfully confirmed!'))
    },
    error(_data) {
      $(this).find('.status_message').css('visibility', 'hidden')
      $.flashError(I18n.t('Confirmation failed. Please try again.'))
    },
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
          $('<span class="screenreader-only" />').text(I18n.t('This is the default email address'))
        )
      $('.default_email.display_data').text(data.user.communication_channel.path)
    })
  })
  $('.dialog .re_send_confirmation_link').click(function (event) {
    event.preventDefault()
    const $link = $(this)
    $link.text(I18n.t('links.resending_confirmation', 'Re-Sending...'))
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      _data => {
        $link.text(I18n.t('links.resent_confirmation', 'Done! Message may take a few minutes.'))
      },
      _data => {
        $link.text(I18n.t('links.resend_confirmation_failed', 'Request failed. Try again.'))
      }
    )
  })
  $('#communication_channels .cancel_button').click(_event => {
    $('#communication_channels').dialog('close')
  })
  $('#confirm_email_channel .cancel_button').click(() => {
    $('#confirm_email_channel').dialog('close')
  })
})
