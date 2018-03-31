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
  '../fn/preventDefault'
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

    findField: (field, useGlobalSelector=false) ->
      selector = @fieldSelectors?[field] or "[name='#{field}']"
      if useGlobalSelector
        $el = $(selector)
      else
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
    #
    # If globalSelector is true, it will look for this element everywhere
    # in the DOM instead of only `this` children elements. This is particularly
    # useful for some modals
    showErrors: (errors, useGlobalSelector=false) ->
      for fieldName, field of errors
        $input = field.element || @findField(fieldName, useGlobalSelector)
        html = field.message || (htmlEscape(@translations?[message] or message) for {message} in field).join('</p><p>')
        $input.errorBox($.raw("#{html}"))?.css("z-index", "1100")?.attr('role', 'alert')
        @attachErrorDescription($input, html)
        field.$input = $input
        field.$errorBox = $input.data 'associated_error_box'

    attachErrorDescription: ($input, message) ->
      errorDescriptionField = @findOrCreateDescriptionField($input)
      errorDescriptionField["description"].text($.raw("#{message}"))
      $input.attr('aria-describedby',
        errorDescriptionField["description"].attr('id') + " " +
        errorDescriptionField["originalDescriptionIds"]
      )

    findOrCreateDescriptionField: ($input) ->
      id = $input.attr('id')
      unless $("##{id}_sr_description").length > 0
        $('<div>').attr({
          id: "#{id}_sr_description"
          class: "screenreader-only"
        }).insertBefore($input)
      description = $("##{id}_sr_description")
      originalDescriptionIds = @getExistingDescriptionIds($input, id)
      {description: description, originalDescriptionIds: originalDescriptionIds}

    getExistingDescriptionIds: ($input, id) ->
      descriptionIds = $input.attr('aria-describedby')
      idArray = if descriptionIds then descriptionIds.split(" ") else []
      _.without(idArray,"#{id}_sr_description")
