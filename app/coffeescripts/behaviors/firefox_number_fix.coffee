#
# Copyright (C) 2014 - present Instructure, Inc.
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

# Firefox doesn't clamp values for the number input. See: https://bugzilla.mozilla.org/1028712
# Should be removed once firefox fixes the issue and is used in production version of firefox.
define [
  'jquery'
  'i18n!firefox_fix'
  'jquery.instructure_forms'
], ($, I18n) ->

  onChangeHandler = (e) ->
    numInput = $(e.target)
    min = parseInt(numInput.attr("min"))
    throw "'min' attribute needs to be a number" if isNaN(min)
    current = parseInt(numInput.val())
    if !isNaN(current) and current < min  ## If current is a number and current < min
      numInput.val(min)
      #So the user's not wondering why their stuff got reset.
      #Will quickly flash on firefox when coming from a blank input.
      numInput.errorBox I18n.t("You must set it to a number greater than or equal to %{min}", { min: numInput.prop("min") })

  $.fn.activate_firefox_fix = () ->
    this.on 'change', 'input[type=number][min]', onChangeHandler

  $(document).activate_firefox_fix()
