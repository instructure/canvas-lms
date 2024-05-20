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
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' // validateForm, formErrors, errorBox
import replaceTags from '@canvas/util/replaceTags'
import 'jquery-tinypubsub' // /\.publish/
import 'jqueryui/button'

const I18n = useI18nScope('alerts')

$(function () {
  const $list = $('.alerts_list')

  const getAlertData = function ($alert) {
    const criteria = []
    $alert.find('ul.criteria li').each(function () {
      criteria.push({
        id: $(this).find('input[name="alert[criteria][][id]"]').prop('value'),
        criterion_type: $(this).data('value'),
        threshold: $(this).find('span').text(),
      })
    })
    const recipients = []
    $alert.find('ul.recipients li').each(function () {
      recipients.push($(this).data('value'))
    })
    let repetition = $alert.find('input[name="repetition"]:checked').prop('value')
    if (repetition === 'value') {
      repetition = $alert.find('input[name="alert[repetition]"]').prop('value')
    } else {
      repetition = null
    }
    return {criteria, recipients, repetition}
  }

  const addRecipientInOrder = function ($node, $item) {
    $node.append($item)
    return $item
  }

  const createElement = function (key, element, value, lookup) {
    // xsslint safeString.identifier element
    const $element = $('<' + element + ' />')
    $element.data('value', key)
    let contentHtml = htmlEscape(lookup[key][value]).toString()
    // see placeholder in _alerts.html.erb
    contentHtml = contentHtml.replace(
      '%{count}',
      "<span class='displaying'></span><input type='text' name='alert[criteria][][threshold]' class='editing' size='2'></input>"
    )
    $element.html(contentHtml)
    if (element === 'li') {
      $element.append(' ')
      $element.append($list.find('>.delete_item_link').clone().toggle())
    } else {
      $element.prop('value', key)
    }
    return $element
  }

  // xsslint jqueryObject.function createRecipient createCriterion
  const createRecipient = function (recipient, element) {
    const $element = createElement(recipient, element, 'label', ENV.ALERTS.POSSIBLE_RECIPIENTS)
    if (element === 'li') {
      $element.prepend(
        $("<input type='hidden' name='alert[recipients][]' />").prop('value', recipient)
      )
    }
    return $element
  }

  const createCriterion = function (criterion, element) {
    let criterion_type = criterion,
      threshold,
      id
    if (typeof criterion === 'object') {
      criterion_type = criterion.criterion_type
      threshold = criterion.threshold
      id = criterion.id
    }
    const $element = createElement(
      criterion_type,
      element,
      element === 'li' ? 'label' : 'option',
      ENV.ALERTS.POSSIBLE_CRITERIA
    )
    if (element === 'li') {
      if (!threshold) {
        threshold = ENV.ALERTS.POSSIBLE_CRITERIA[criterion_type].default_threshold
      }
      $element.find('span').text(threshold)
      $element
        .find('input')
        .prop('value', threshold)
        .attr('title', ENV.ALERTS.POSSIBLE_CRITERIA[criterion_type].title)
      $element.prepend(
        $("<input type='hidden' name='alert[criteria][][criterion_type]' />").prop(
          'value',
          criterion_type
        )
      )
      if (id) {
        $element.prepend(
          $("<input type='hidden' name='alert[criteria][][id]' />").prop('value', id)
        )
      }
    }
    return $element
  }

  const restoreAlert = function ($alert, data) {
    const $criteria = $alert.find('.criteria')
    $criteria.empty()
    for (const idx in data.criteria) {
      $criteria.append(createCriterion(data.criteria[idx], 'li'))
    }
    const $recipients = $alert.find('.recipients')
    $recipients.empty()
    for (const idx in data.recipients) {
      if (ENV.ALERTS.POSSIBLE_RECIPIENTS[data.recipients[idx]]) {
        $recipients.append(createRecipient(data.recipients[idx], 'li'))
      }
    }
    if (data.repetition) {
      $alert.find('input[name="repetition"][value="value"]').prop('checked', true)
      $alert.find('input[name="alert[repetition]"]').prop('value', data.repetition)
      $alert.find('.repetition_group .no_repetition').toggle(false)
      $alert.find('.repetition_group .repetition').toggle(true).find('span').text(data.repetition)
    } else {
      $alert.find('input[name="repetition"][value="none"]').prop('checked', true)
      $alert.find('.repetition_group .no_repetition').toggle(true)
      $alert.find('.repetition_group .repetition').toggle(false)
    }
  }

  for (const idx in ENV.ALERTS.DATA) {
    const alert = ENV.ALERTS.DATA[idx]
    restoreAlert($('#edit_alert_' + alert.id), alert)
  }

  $('.add_alert_link').click(function (event) {
    event.preventDefault()
    const $blank = $('.alert.blank')
    const $alert = $blank.clone()
    $alert.removeClass('blank')
    $alert.addClass('new')
    if ($list.find('.alert:visible').length != 0) {
      $('<div class="alert_separator"></div>').insertBefore($blank)
    }
    const rand = Math.floor(Math.random() * 100000000)
    $alert.find('input').each(function () {
      $(this).attr('id', replaceTags($(this).attr('id'), 'id', rand))
    })
    $alert.find('label').each(function () {
      $(this).attr('for', replaceTags($(this).attr('for'), 'id', rand))
    })
    $alert.insertBefore($blank)
    $alert.find('.edit_link').trigger('click')
    $alert.toggle(false)
    $alert.slideDown()
  })

  $list
    .on('click', '.edit_link', function () {
      const $alert = $(this).parents('.alert')
      const data = getAlertData($alert)
      $alert.data('data', data)

      const $criteria_select = $alert.find('.add_criterion_link').prev()
      $criteria_select.empty()
      let count = 0
      for (const idx in ENV.ALERTS.POSSIBLE_CRITERIA_ORDER) {
        const criterion = ENV.ALERTS.POSSIBLE_CRITERIA_ORDER[idx]
        let found = -1
        for (const jdx in data.criteria) {
          if (data.criteria[jdx].criterion_type == criterion) {
            found = jdx
            break
          }
        }
        if (found == -1) {
          $criteria_select.append(createCriterion(criterion, 'option'))
          count += 1
        }
      }
      if (count == 0) {
        $alert.find('.add_criteria_line').toggle(false)
      }

      const $recipients_select = $alert.find('.add_recipient_link').prev()
      $recipients_select.empty()
      count = 0
      for (const idx_ in ENV.ALERTS.POSSIBLE_RECIPIENTS_ORDER) {
        const recipient = ENV.ALERTS.POSSIBLE_RECIPIENTS_ORDER[idx_]
        if ($.inArray(recipient, data.recipients) == -1) {
          $recipients_select.append(createRecipient(recipient, 'option'))
          count += 1
        }
      }
      if (count == 0) {
        $alert.find('.add_recipients_line').toggle(false)
      }

      $alert.find('.repetition_group label').toggle(true)
      $alert.toggleClass('editing')
      $alert.toggleClass('displaying')
      return false
    })
    .on('click', '.delete_link', function () {
      const $alert = $(this).parents('.alert')
      if (!$alert.hasClass('new')) {
        $alert.find('input[name="_method"]').prop('value', 'DELETE')
        $.ajaxJSON($alert.attr('action'), 'POST', $alert.serialize(), _data => {
          $alert.slideUp(() => {
            $alert.remove()
            $list.find('.alert:first').prev('.alert_separator').remove()
            $list.find('.alert_separator + .alert_separator').remove()
            $list.find('.alert:visible:last').next('.alert_separator').remove()
          })
        })
      } else {
        $alert.slideUp(() => {
          $alert.remove()
          $list.find('.alert:first').prev('.alert_separator').remove()
          $list.find('.alert_separator + .alert_separator').remove()
          $list.find('.alert:visible:last').next('.alert_separator').remove()
        })
      }
      return false
    })
    .on('click', '.cancel_button', function () {
      $(this).parent().hideErrors()
      const $alert = $(this).parents('.alert')
      if ($alert.hasClass('new')) {
        $alert.slideUp(() => {
          $alert.remove()
          $list.find('.alert:first').prev('.alert_separator').remove()
          $list.find('.alert_separator + .alert_separator').remove()
          $list.find('.alert:visible:last').next('.alert_separator').remove()
        })
      } else {
        const data = $alert.data('data')
        restoreAlert($alert, data)

        $alert.toggleClass('editing', false)
        $alert.toggleClass('displaying', true)
      }
      return false
    })
    .on('submit', '.alert', function () {
      const $alert = $(this)

      // Validation (validateForm doesn't support arrays, and formErrors
      // wouldn't be able to locate the correct elements)
      const errors = []
      if ($alert.find('.criteria li').length === 0) {
        errors.push([
          $alert.find('.add_criterion_link').prev(),
          I18n.t('errors.criteria_required', 'At least one trigger is required'),
        ])
      }
      $alert.find('.criteria input.editing').each(function () {
        const val = $(this).prop('value')
        if (!val || Number.isNaN(Number(val)) || parseFloat(val) < 0) {
          errors.push([
            $(this),
            I18n.t('errors.threshold_should_be_numeric', 'This should be a positive number'),
          ])
        }
      })
      if ($alert.find('.recipients li').length === 0) {
        errors.push([
          $alert.find('.add_recipient_link').prev(),
          I18n.t('errors.recipients_required', 'At least one recipient is required'),
        ])
      }
      if ($alert.find('input[name="repetition"]:checked').prop('value') === 'none') {
        $alert.find('input[name="alert[repetition]"]').prop('value', '')
      } else {
        const $repetition = $alert.find('input[name="alert[repetition]"]')
        const val = $repetition.prop('value')
        if (!val || Number.isNaN(Number(val)) || parseFloat(val) < 0) {
          errors.push([
            $repetition,
            I18n.t('errors.threshold_should_be_numeric', 'This should be a positive number'),
          ])
        }
      }
      if (errors.length != 0) {
        $alert.formErrors(errors)
        return false
      }

      $.ajaxJSON(
        $alert.attr('action'),
        'POST',
        $alert.serialize(),
        (data, xhr) => {
          $alert.removeClass('new')
          $alert.attr('action', xhr.getResponseHeader('Location'))
          const $method = $alert.find('input[name="_method"]')
          if ($method.length === 0) {
            $alert.append($('<input type="hidden" name="_method" value="put" />'))
          }
          $alert.toggleClass('editing', false)
          $alert.toggleClass('displaying', true)
          restoreAlert($alert, data)
        },
        data => {
          $alert.formErrors(data)
        }
      )
      return false
    })
    .on('click', '.recipients .delete_item_link', function () {
      const $li = $(this).parents('li')
      const $add_link = $(this).parents('.alert').find('.add_recipient_link')
      addRecipientInOrder($add_link.prev(), createRecipient($li.data('value'), 'option'))

      $li.slideUp(() => {
        $li.remove()
      })
      $add_link.parent().slideDown(() => {
        $add_link.parent().css('display', '')
      })
      return false
    })
    .on('click', '.add_recipient_link', function () {
      const $recipients = $(this).parents('.alert').find('.recipients')
      const $select = $(this).prev()
      const recipient = $select.prop('value')
      addRecipientInOrder($recipients, createRecipient(recipient, 'li')).toggle().slideDown()
      const $errorBox = $select.data('associated_error_box')
      if ($errorBox) {
        $errorBox.fadeOut('slow', () => {
          $errorBox.remove()
        })
      }

      $select.find('option[value="' + recipient + '"]').remove()

      if ($select.find('*').length === 0) {
        $(this).parent().slideUp()
      }
      return false
    })
    .on('click', '.criteria .delete_item_link', function () {
      const $li = $(this).parents('li')
      const $add_link = $(this).parents('.alert').find('.add_criterion_link')
      addRecipientInOrder($add_link.prev(), createCriterion($li.data('value'), 'option'))

      $li.slideUp(() => {
        $li.remove()
      })
      $add_link.parent().slideDown(() => {
        $add_link.parent().css('display', '')
      })
      return false
    })
    .on('click', '.add_criterion_link', function () {
      const $criteria = $(this).parents('.alert').find('.criteria')
      const $select = $(this).prev()
      const criterion = $select.prop('value')
      addRecipientInOrder($criteria, createCriterion(criterion, 'li')).toggle().slideDown()
      const $errorBox = $select.data('associated_error_box')
      if ($errorBox) {
        $errorBox.fadeOut('slow', () => {
          $errorBox.remove()
        })
      }

      $select.find('option[value="' + criterion + '"]').remove()

      if ($select.find('*').length === 0) {
        $(this).parent().slideUp()
      }
      return false
    })
    .on('click', 'input[name="repetition"]', function () {
      const $error_box = $(this)
        .parents('.alert')
        .find('input[name="alert[repetition]"]')
        .data('associated_error_box')
      if ($error_box) {
        $error_box.fadeOut('slow', () => {
          $error_box.remove()
        })
      }
    })
    .on('click', 'label.repetition', function (event) {
      event.preventDefault()
      $(this).parents('.alert').find('input[name="repetition"]').prop('checked', true)
    })
})
