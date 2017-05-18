#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery'
  'compiled/calendar/EditAssignmentDetails'
  'compiled/util/fcUtil'
  'timezone'
  'timezone/America/Detroit'
  'timezone/fr_FR'
  'helpers/I18nStubber'
], ($, EditAssignmentDetails, fcUtil, tz, detroit, french, I18nStubber) ->

  QUnit.module "EditAssignmentDetails",
    setup: ->
      @snapshot = tz.snapshot()
      @$holder = $('<table />').appendTo(document.getElementById("fixtures"))
      @event =
        possibleContexts: -> []
        isNewEvent: -> true
        startDate: -> fcUtil.wrap('2015-08-07T17:00:00Z')
        allDay: false

    teardown: ->
      # tick past any remaining errorBox fade-ins
      @$holder.detach()
      document.getElementById("fixtures").innerHTML = ""
      tz.restore(@snapshot)

  test "should initialize input with start date and time", ->
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Fri Aug 7, 2015 5:00pm"

  test "should have blank input when no start date", ->
    @event.startDate = -> null
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), ""

  test "should include start date only if all day", ->
    @event.allDay = true
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Fri Aug 7, 2015"

  test "should treat start date as fudged", ->
    tz.changeZone(detroit, 'America/Detroit')
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Fri Aug 7, 2015 1:00pm"

  test "should localize start date", ->
    I18nStubber.pushFrame()
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'date.formats.full_with_weekday': '%a %-d %b %Y %-k:%M'

    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "ven. 7 août 2015 17:00"

    I18nStubber.popFrame()
