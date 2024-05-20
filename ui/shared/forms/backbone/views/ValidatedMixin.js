/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import $ from 'jquery'
import {without} from 'lodash'
import htmlEscape, {raw} from '@instructure/html-escape'
import '@canvas/jquery/jquery.toJSON'
import '@canvas/jquery/jquery.disableWhileLoading'
import '../../jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.instructure_misc_helpers'

export default {
  // Errors are displayed relative to the field to which they belong. If
  // the key of the error in the response doesn't match the name attribute
  // of the form input element, configure a selector here.
  //
  // For example, given a form field like this:
  //
  //   <input name="user[first_name]">
  //
  // and an error response like this:
  //
  //   {errors: { first_name: {...} }}
  //
  // you would do this:
  //
  //   fieldSelectors:
  //     first_name: '[name=user[first_name]]'
  fieldSelectors: null,
  // For a given dom element, retrieve the sibling tinymce wrapper.
  //
  // @param {jQuery Object} the textarea for whom we wish to get the
  //   related tinymce editor area
  // @return {jQuery Object} the relevant div that wraps the tinymce
  //   iframe related to this textarea
  findSiblingTinymce($el) {
    return $el.siblings('.tox-tinymce').find('.tox-edit-area')
  },
  findField(field, useGlobalSelector) {
    let $el, ref
    if (useGlobalSelector == null) {
      useGlobalSelector = false
    }
    const selector =
      ((ref = this.fieldSelectors) != null ? ref[field] : void 0) || "[name='" + field + "']"
    if (useGlobalSelector) {
      $el = $(selector)
    } else {
      $el = this.$(selector)
    }
    if ($el.data('rich_text')) {
      $el = this.findSiblingTinymce($el)
    }
    return $el
  },
  // Needs an errors object that looks like this:
  //
  //   {
  //     <field1>: [errors],
  //     <field2>: [errors]
  //   }
  //
  // For example:
  //
  //   {
  //     first_name: [
  //       {
  //         type: 'required'
  //         message: 'First name is required'
  //       },
  //       {
  //         type: 'no_numbers',
  //         message: "First name can't contain numbers"
  //       }
  //     ]
  //   }
  //
  // If globalSelector is true, it will look for this element everywhere
  // in the DOM instead of only `this` children elements. This is particularly
  // useful for some modals
  showErrors(errors, useGlobalSelector) {
    let $input, field, fieldName, html, message, ref, ref1
    if (useGlobalSelector == null) {
      useGlobalSelector = false
    }
    const results = []
    for (fieldName in errors) {
      field = errors[fieldName]
      $input = field.element || this.findField(fieldName, useGlobalSelector)
      html =
        field.message ||
        // eslint-disable-next-line no-loop-func
        function () {
          let i, len, ref_
          const results1 = []
          for (i = 0, len = field.length; i < len; i++) {
            message = field[i].message
            results1.push(
              htmlEscape(((ref_ = this.translations) != null ? ref_[message] : void 0) || message)
            )
          }
          return results1
        }
          .call(this)
          .join('</p><p>')
      if ((ref = $input.errorBox(raw('' + html))) != null) {
        if ((ref1 = ref.css('z-index', '1100')) != null) {
          ref1.attr('role', 'alert')
        }
      }
      this.attachErrorDescription($input, html)
      field.$input = $input
      results.push((field.$errorBox = $input.data('associated_error_box')))
    }
    return results
  },
  attachErrorDescription($input, message) {
    const errorDescriptionField = this.findOrCreateDescriptionField($input)
    errorDescriptionField.description.text(raw('' + message))
    return $input.attr(
      'aria-describedby',
      errorDescriptionField.description.attr('id') +
        ' ' +
        errorDescriptionField.originalDescriptionIds
    )
  },
  findOrCreateDescriptionField($input) {
    const id = $input.attr('id')
    if (!($('#' + id + '_sr_description').length > 0)) {
      $('<div>')
        .attr({
          id: id + '_sr_description',
          class: 'screenreader-only',
        })
        .insertBefore($input)
    }
    const description = $('#' + id + '_sr_description')
    const originalDescriptionIds = this.getExistingDescriptionIds($input, id)
    return {
      description,
      originalDescriptionIds,
    }
  },
  getExistingDescriptionIds($input, id) {
    const descriptionIds = $input.attr('aria-describedby')
    const idArray = descriptionIds ? descriptionIds.split(' ') : []
    return without(idArray, id + '_sr_description')
  },
}
