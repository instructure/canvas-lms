/* eslint-disable no-alert */
/* eslint-disable eqeqeq */
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
import $ from 'jquery'
import ready from '@instructure/ready'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData */
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('sub_accounts')

ready(() => {
  $('.add_sub_account_link').click(function () {
    $("<li class='sub_account'/>")
      .append($('#account_blank').clone(true).attr('id', 'account_new').show())
      .appendTo($(this).parents('.account:first').children('.sub_accounts'))
      .find('.edit_account_link')
      .click()
    return false
  })

  $('.account .header').hover(
    function () {
      $(this).addClass('header_hover')
    },
    function () {
      $(this).removeClass('header_hover')
    }
  )

  $('.edit_account_link').click(function () {
    $(this)
      .parents('.account:first')
      .addClass('editing_account')
      .find(':text:visible:first')
      .focus()
      .select()
    return false
  })

  $('.account_name')
    .blur(function () {
      if (!$(this).parents('form').hasClass('saving')) {
        if (
          $(this).parents('.account:first').removeClass('editing_account').attr('id') ==
          'account_new'
        ) {
          $(this).parents('.sub_account:first').remove()
        }
      }
    })
    .keycodes('esc', function () {
      $(this).triggerHandler('blur')
    })

  $('.edit_sub_account_form').formSubmit({
    processData(data) {
      data['account[parent_account_id]'] = $(this)
        .parents('.account:first')
        .parents('.account:first')
        .children('.header')
        .getTemplateData({textValues: ['id']}).id
      return data
    },
    beforeSubmit(_data) {
      $(this).loadingImage({image_size: 'small'}).addClass('saving')
    },
    success(data) {
      const account = data
      $(this).loadingImage('remove').removeClass('saving')
      $(this)
        .parents('.header')
        .fillTemplateData({
          data: account,
          hrefValues: ['id'],
        })
        .fillFormData(account, {object_name: 'account'})
        .parents('.account:first')
        .removeClass('editing_account')

      const url = replaceTags(
        $('#sub_account_urls .sub_account_url').attr('href'),
        'id',
        account.id
      )
      $(this).attr({action: url, method: 'PUT'})
      $(this)
        .parents('.account:first')
        .attr('id', 'account_' + account.id)

      const expand_link = $('#account_' + account.id + ' .expand_sub_accounts_link')
      expand_link.attr({
        'data-link': replaceTags(expand_link.attr('data-link'), 'id', account.id),
      })

      $('#account_' + account.id + ' > .header .name').focus()
    },
  })

  $('.cant_delete_account_link').click(() => {
    alert(
      I18n.t(
        'alerts.subaccount_has_courses',
        "You can't delete a sub-account that has courses in it"
      )
    )
    return false
  })

  $('.delete_account_link').click(function () {
    if ($(this).parents('.account:first').children('.sub_account > li').length) {
      alert(
        I18n.t(
          'alerts.subaccount_has_subaccounts',
          "You can't delete a sub-account that has sub-accounts"
        )
      )
    } else {
      $(this)
        .parents('li:first')
        .confirmDelete({
          url: $(this).parents('.header').find('form').attr('action'),
          message: I18n.t(
            'confirms.delete_subaccount',
            'Are you sure you want to delete this sub-account?'
          ),
          success() {
            const $list_entry = $(this).closest('.sub_account')
            const $prev_entry = $list_entry.prev()
            const $focusTo = $prev_entry.length
              ? $('> .account > .header .name', $prev_entry)
              : $('> .header .name', $list_entry.closest('.account'))
            $(this).slideUp(function () {
              $(this).remove()
              $focusTo.focus()
            })
          },
          error(data) {
            this.undim()
            if (data.hasOwnProperty('message')) {
              alert(data.message)
            }
          },
        })
    }
    return false
  })

  $('.collapse_sub_accounts_link').click(function () {
    const $header = $(this).parents('.header:first')
    $header.closest('.account').children('ul').slideUp()
    $header.find('.expand_sub_accounts_link').show().focus()
    $header.find('.collapse_sub_accounts_link, .add_sub_account_link').hide()
    return false
  })

  $('.expand_sub_accounts_link').click(function () {
    const $header = $(this).parents('.header:first')
    if ($header.parent('.account').children('ul').children('.sub_account').length) {
      $header.parent('.account').children('ul').slideDown()
      $header.find('.expand_sub_accounts_link').hide()
      $header.find('.collapse_sub_accounts_link, .add_sub_account_link').show()
      $header.find('.collapse_sub_accounts_link').focus()
    } else {
      $header.loadingImage({image_size: 'small'})
      $.ajaxJSON(
        $(this).data('link'),
        'GET',
        {},
        data => {
          $header.loadingImage('remove').find('.expand_sub_accounts_link').hide()
          $header.find('.collapse_sub_accounts_link, .add_sub_account_link').show()
          $header.parent('.account').children('ul').empty().hide()
          let account = null
          for (const idx in data) {
            account = data[idx]
          }
          for (const idx in account.sub_accounts) {
            let sub_account = null
            for (const jdx in account.sub_accounts[idx]) {
              if (typeof account.sub_accounts[idx][jdx] === 'object') {
                sub_account = account.sub_accounts[idx][jdx]
              }
            }
            sub_account.courses_count = I18n.t(
              'courses_count',
              {one: '1 Course', other: '%{count} Courses'},
              {count: sub_account.course_count}
            )
            sub_account.sub_accounts_count = I18n.t(
              'sub_accounts_count',
              {one: '1 Sub-Account', other: '%{count} Sub-Accounts'},
              {count: sub_account.sub_account_count}
            )
            const sub_account_node = $("<li class='sub_account'/>")
            sub_account_node
              .append(
                $('#account_blank')
                  .clone(true)
                  .attr('id', 'account_new')
                  .show()
                  .attr('id', 'account_' + sub_account.id)
                  .fillFormData(sub_account, {object_name: 'account'})
              )
              .fillTemplateData({
                data: sub_account,
                hrefValues: ['id'],
              })
              .appendTo($header.parent('.account').children('ul'))
              .find('.sub_accounts_count')
              .showIf(sub_account.sub_account_count)
              .end()
              .find('.courses_count')
              .showIf(sub_account.course_count)
              .end()
              .find('.collapse_sub_accounts_link')
              .hide()
              .end()
              .find('.expand_sub_accounts_link')
              .showIf(sub_account.sub_account_count > 0)
              .attr({
                'data-link': replaceTags(
                  sub_account_node.find('.expand_sub_accounts_link').attr('data-link'),
                  'id',
                  sub_account.id
                ),
              })
              .end()
              .find('.add_sub_account_link')
              .showIf(sub_account.sub_account_count == 0)
              .end()
              .find('.edit_sub_account_form')
              .attr({
                action: replaceTags(
                  $('#sub_account_urls .sub_account_url').attr('href'),
                  'id',
                  sub_account.id
                ),
                method: 'PUT',
              })
          }
          $header.parent('.account').children('ul').slideDown()
          $header.find('.collapse_sub_accounts_link').focus()
        },
        _data => {}
      )
    }
    return false
  })
})
