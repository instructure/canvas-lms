#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'jquery.toJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
], (Backbone, $, _, preventDefault, htmlEscape) ->

  ValidatedMixin =

    ##
    # Errors are displayed relative to the field to which they belong. If
    # the key of the error in the response doesn't match the name attribute
    # of the form input element, configure a selector here.
    #
    # For example, given a form field like this:
    #
    #   <input name="user[first_name]">
    #
    # and an error response like this:
    #
    #   {errors: { first_name: {...} }}
    #
    # you would do this:
    #
    #   fieldSelectors:
    #     first_name: '[name=user[first_name]]'
    fieldSelectors: null

    ##
    # For a given dom element, retrieve the sibling tinymce wrapper.
    #
    # @param {jQuery Object} the textarea for whom we wish to get the
    #   related tinymce editor area
    # @return {jQuery Object} the relevant div that wraps the tinymce
    #   iframe related to this textarea
    findSiblingTinymce: ($el)->
      $el.siblings('.mce-tinymce').find(".mce-edit-area")

    findField: (field) ->
      selector = @fieldSelectors?[field] or "[name='#{field}']"
      $el = @$(selector)
      if $el.data('rich_text')
        $el = @findSiblingTinymce($el)
      $el

    ##
    # Needs an errors object that looks like this:
    #
    #   {
    #     <field1>: [errors],
    #     <field2>: [errors]
    #   }
    #
    # For example:
    #
    #   {
    #     first_name: [
    #       {
    #         type: 'required'
    #         message: 'First name is required'
    #       },
    #       {
    #         type: 'no_numbers',
    #         message: "First name can't contain numbers"
    #       }
    #     ]
    #   }
    showErrors: (errors) ->
      for fieldName, field of errors
        $input = @findField fieldName
        # check for a translations option first, fall back to just displaying otherwise
        html = (htmlEscape(@translations?[message] or message) for {message} in field).join('</p><p>')
        errorDescription = @findOrCreateDescription($input)
        errorDescription.text($.raw("#{html}"))
        $input.attr('aria-describedby', errorDescription.attr('id'))
        $input.errorBox $.raw("<div>#{html}</div>")
        field.$input = $input
        field.$errorBox = $input.data 'associated_error_box'

    findOrCreateDescription: ($input) ->
      id = $input.attr('id')
      existingDescription = $("##{id}_sr_description")
      if existingDescription.length > 0
        return existingDescription
      else
        newDescripton = $('<div>').attr({
          id: "##{id}_sr_description"
          class: "screenreader-only"
        })
        newDescripton.insertBefore($input)
        newDescripton
