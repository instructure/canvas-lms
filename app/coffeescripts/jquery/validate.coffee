#
# Copyright (C) 2012 - present Instructure, Inc.
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

##
# Validates a form, returns true or false, stores errors on element data.
#
# Markup supported:
#
# - Required
#   <input type="text" name="whatev" required>
#
# ex:
#   if $form.validates()
#     doStuff()
#   else
#     errors = $form.data 'errors'
define [
  'jquery'
  'underscore'
  'i18n!validate'
], ($, _, I18n) ->

  $.fn.validate = ->
    errors = {}

    this.find('[required]').each ->
      $input = $ this
      name = $input.attr 'name'
      value = $input.val()
      if value is ''
        (errors[name] ?= []).push
          name: name
          type: 'required'
          message: I18n.t 'is_required', 'This field is required'

    hasErrors = _.size(errors) > 0

    if hasErrors
      this.data 'errors', errors
      false
    else
      this.data 'errors', null
      true

