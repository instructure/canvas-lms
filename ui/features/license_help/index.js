/* eslint-disable @typescript-eslint/no-shadow */
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
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/loading-image'

const I18n = useI18nScope('license_help')

const licenceTypes = ['by', 'nc', 'nd', 'sa']
const toggleButton = (el, check) =>
  $(el).toggleClass('selected', !!check).attr('aria-checked', !!check)
const checkButton = el => toggleButton(el, true)
const uncheckButton = el => toggleButton(el, false)

$(document).on('click', '.license_help_link', function (event) {
  event.preventDefault()
  let $dialog = $('#license_help_dialog')
  const $select = $(this).prev('select')
  if (!$dialog.length) {
    $dialog = $('<div/>')
    $dialog.attr('id', 'license_help_dialog').hide().loadingImage().appendTo('body')

    $dialog.on('click', '.option', function (event) {
      event.preventDefault()
      const select = !$(this).is('.selected')
      toggleButton(this, select)
      if (select) {
        checkButton($dialog.find('.option.by'))
        if ($(this).hasClass('sa')) {
          uncheckButton($dialog.find('.option.nd'))
        } else if ($(this).hasClass('nd')) {
          uncheckButton($dialog.find('.option.sa'))
        }
      } else if ($(this).hasClass('by')) {
        uncheckButton($dialog.find('.option'))
      }
      $dialog.triggerHandler('option_change')
    })

    $dialog.on('click', '.select_license', () => {
      if ($dialog.data('select')) {
        $dialog.data('select').val($dialog.data('current_license') || 'private')
      }
      return $dialog.dialog('close')
    })

    $dialog.bind('license_change', (event, license) => {
      $dialog.find('.license').removeClass('active').filter(`.${license}`).addClass('active')
      uncheckButton($dialog.find('.option'))
      if ($dialog.find('.license.active').length === 0) {
        license = 'private'
        $dialog.find('.license.private').addClass('active')
      }
      $dialog.data('current_license', license)
      if (license.match(/^cc/)) {
        licenceTypes.forEach(type => {
          if (type === 'by' || license.match(`_${type}`)) {
            checkButton($dialog.find(`.option.${type}`))
          }
        })
      }
    })

    $dialog.bind('option_change', () => {
      const args = ['cc']
      licenceTypes.forEach(type => {
        if ($dialog.find(`.option.${type}`).is('.selected')) {
          args.push(type)
        }
      })

      const license = args.length === 1 ? 'private' : args.join('_')
      return $dialog.triggerHandler('license_change', license)
    })

    $dialog.dialog({
      autoOpen: false,
      title: I18n.t('content_license_help', 'Content Licensing Help'),
      width: Math.min(window.innerWidth, 620),
      modal: true,
      zIndex: 1000,
    })
    $.get('/partials/_license_help.html', html =>
      $dialog
        .loadingImage('remove')
        .html(html)
        .triggerHandler('license_change', $select.val() || 'private')
    )
  }

  $dialog.find('.select_license').showIf($select.length)
  $dialog.data('select', $select)
  $dialog.triggerHandler('license_change', $select.val() || 'private')
  $dialog.dialog('open')
})
