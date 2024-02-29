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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import SuspendedIcon from '../react/SuspendedIcon'
import $ from 'jquery'
import Pseudonym from '@canvas/pseudonyms/backbone/models/Pseudonym'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/util/templateData'
import '../react/externalIdFields'

const I18n = useI18nScope('user_logins')

const savedSSOIcons = {}

$(function () {
  const $form = $('#edit_pseudonym_form')
  $form.formSubmit({
    disableWhileLoading: true,
    formErrors: false,
    processData(data) {
      if (
        !$(this).hasClass('passwordable') ||
        (!data['pseudonym[password]'] && !data['pseudonym[password_confirmation]'])
      ) {
        delete data['pseudonym[password]']
        delete data['pseudonym[password_confirmation]']
      }
    },
    beforeSubmit() {
      const select = $(this).find('.account_id select')[0]
      const idx = select && select.selectedIndex
      $(this).data('account_name', null)
      $(this).data('account_name', select && select.options[idx] && select.options[idx].innerHTML)
    },
    success(data) {
      let $login
      $(this).dialog('close')
      if ($(this).data('unique_id_text')) {
        $login = $(this).data('unique_id_text').parents('.login')
      } else {
        $login = $('#login_information .login.blank').clone(true)
        $('#login_information .add_holder').before($login)
        $login.removeClass('blank')
        $login.show()
        data.account_name = $(this).data('account_name')
      }
      $login.fillTemplateData({
        data,
        hrefValues: ['id', 'account_id'],
      })
      const $logins = $('#login_information .login')
      $('.delete_pseudonym_link', $logins)[
        $logins.filter(':visible').length < 2 ? 'hide' : 'show'
      ]()
      $.flashMessage(I18n.t('save_succeeded', 'Save successful'))
    },
    error(errors, jqXHR, response) {
      if (response.status === 401)
        return $.flashError(
          I18n.t(
            'error.unauthorized',
            'You do not have sufficient privileges to make the change requested'
          )
        )
      const accountId = $(this).find('.account_id select').val()
      const policy =
        (ENV.PASSWORD_POLICIES && ENV.PASSWORD_POLICIES[accountId]) || ENV.PASSWORD_POLICY
      errors = Pseudonym.prototype.normalizeErrors(errors, policy)
      $(this).formErrors(errors)
    },
  })
  $('#edit_pseudonym_form .cancel_button').on('click', () => {
    $form.dialog('close')
  })
  $('#login_information')
    .on('click', '.login_details_link', function (event) {
      event.preventDefault()
      $(this).parents('tr').find('.login_details').show()
      $(this).hide()
    })
    .on('click', '.edit_pseudonym_link', function (event) {
      event.preventDefault()
      $form.attr('action', $(this).attr('rel')).attr('method', 'PUT')
      const data = $(this)
        .parents('.login')
        .getTemplateData({
          textValues: ['unique_id', 'sis_user_id', 'integration_id', 'can_edit_sis_user_id'],
        })
      data.password = ''
      data.password_confirmation = ''
      $form.fillFormData(
        {
          unique_id: data.unique_id,
        },
        {object_name: 'pseudonym'}
      )
      window.canvas_pseudonyms.jqInterface.onEdit({
        canEditSisUserId: data.can_edit_sis_user_id === 'true',
        integrationId: data.integration_id,
        sisUserId: data.sis_user_id,
      })
      const passwordable = $(this).parents('.links').hasClass('passwordable')
      const delegated = passwordable && $(this).parents('.links').hasClass('delegated-auth')
      $form.toggleClass('passwordable', passwordable)
      $form.find('tr.password').showIf(passwordable)
      $form.find('tr.delegated').showIf(delegated)
      $form.find('.account_id').hide()
      const $account_select = $form.find('.account_id select')
      const accountId = $(this).data('accountId')
      if ($account_select && accountId) {
        $account_select.val(accountId)
      }
      $form.dialog({
        width: 'auto',
        close() {
          if (
            $form.data('unique_id_text') &&
            $form.data('unique_id_text').parents('.login').hasClass('blank')
          ) {
            $form.data('unique_id_text').parents('.login').remove()
          }
          window.canvas_pseudonyms.jqInterface.onCancel()
        },
        modal: true,
        zIndex: 1000,
      })
      $form
        .dialog('option', 'title', I18n.t('titles.update_login', 'Update Login'))
        .find('.submit_button')
        .text(I18n.t('buttons.update_login', 'Update Login'))
      $form.dialog('option', 'beforeClose', () => {
        $('.error_box:visible').trigger('click')
      })
      const $unique_id = $(this).parents('.login').find('.unique_id')
      $form.data('unique_id_text', $unique_id)
      $form.find(':input:visible:first').trigger('focus').trigger('select')
    })
    .on('click', '.delete_pseudonym_link', function (event) {
      event.preventDefault()
      if ($('#login_information .login:visible').length < 2) {
        // eslint-disable-next-line no-alert
        alert(
          I18n.t('notices.cant_delete_last_login', "You can't delete the last login for a user")
        )
        return
      }
      const login = $(this).parents('.login').find('.unique_id').text()
      $(this)
        .parents('.login')
        .confirmDelete({
          message: I18n.t(
            'confirms.delete_login',
            'Are you sure you want to delete the login, "%{login}"?',
            {login}
          ),
          url: $(this).attr('rel'),
          success() {
            $(this).fadeOut(() => {
              // to get an accurate count, we must wait for this fade to complete
              const $logins = $('#login_information .login')
              if ($logins.filter(':visible').length < 2) {
                $('.delete_pseudonym_link', $logins).hide()
              }
            })
          },
        })
    })
    .on('click', '.add_pseudonym_link', function (event) {
      event.preventDefault()
      $('#login_information .login.blank .edit_pseudonym_link').click()
      window.canvas_pseudonyms.jqInterface.onAdd({canEditSisUserId: $(this).data('can-manage-sis')})
      $form.attr('action', $(this).attr('rel')).attr('method', 'POST')
      $form.fillFormData({'pseudonym[unique_id]': ''})
      $form
        .dialog('option', 'title', I18n.t('titles.add_login', 'Add Login'))
        .find('.submit_button')
        .text(I18n.t('buttons.add_login', 'Add Login'))
      $form.addClass('passwordable')
      $form.find('tr.password').show()
      $form.find('.account_id').show()
      $form.find('.account_id_select').change()
      $form.data('unique_id_text', null)
    })

  $('.reset_mfa_link').on('click', function (event) {
    event.preventDefault()
    const $disable_mfa_link = $(this)
    $.ajaxJSON($disable_mfa_link.attr('href'), 'DELETE', {}, () => {
      $.flashMessage(I18n.t('notices.mfa_reset', 'Multi-factor authentication reset'))
      $disable_mfa_link.parent().remove()
    })
  })

  // TODO: the user's pseudonyms are listed in this bundle (user_logins) but the
  // control of suspending/reactivating them is unfortunately in another bundle
  // (user_name), and the two bundles have no way of directly communicating with
  // each other. So for now we will just use a CustomEvent and use window as the
  // communication bus. For the other end of this communication channel, see
  // ui/features/user_name/react/UserSuspendLink.js
  //
  // Eventually both bundles should be rewritten into one larger tree of React
  // components, and then this can be redone in more standard ways.

  const pseuds = ENV.user_suspend_status?.pseudonyms

  function setSuspend(id) {
    const icon = document.querySelector(`.sso-icon[data-pseudonym-id="${id}"]`)
    const login = pseuds.find(p => p.id === id)?.unique_id
    if (typeof login === 'undefined') return
    if (typeof savedSSOIcons[id] === 'undefined') savedSSOIcons[id] = icon.cloneNode(true)
    const innerDiv = document.createElement('div')
    icon.replaceChildren(innerDiv)
    ReactDOM.render(<SuspendedIcon login={login} />, innerDiv)
  }

  function unsetSuspend(id) {
    const icon = document.querySelector(`.sso-icon[data-pseudonym-id="${id}"]`)
    if (typeof savedSSOIcons[id] === 'undefined') return
    icon.replaceWith(savedSSOIcons[id].cloneNode(true))
    delete savedSSOIcons[id]
  }

  if (pseuds) {
    // Replace the icon for any suspended pseudonym with the "suspended" component
    pseuds
      .filter(p => p.workflow_state === 'suspended')
      .map(p => p.id)
      .forEach(id => setSuspend(id))

    // I don't THINK this ever has to be removed in this configuration
    window.addEventListener('username:pseudonymstatuschange', function (event) {
      const icons = document.querySelectorAll('.sso-icon[data-pseudonym-id]')
      const iconIdOf = elt => elt.attributes.getNamedItem('data-pseudonym-id').value
      const action = event.detail.action === 'suspend' ? setSuspend : unsetSuspend
      for (const icon of icons) {
        action(iconIdOf(icon))
      }
    })
  }
})
