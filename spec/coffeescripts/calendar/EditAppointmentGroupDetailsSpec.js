#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'compiled/calendar/EditAppointmentGroupDetails'
  'compiled/util/fcUtil'
  'timezone'
  'timezone/America/Detroit'
  'timezone/fr_FR'
  'helpers/I18nStubber'
], ($, EditAppointmentGroupDetails, fcUtil, tz, detroit, french, I18nStubber) ->

  QUnit.module "EditAppointmentGroupDetails",
    setup: ->
      @snapshot = tz.snapshot()
      @$holder = $('<table />').appendTo(document.getElementById("fixtures"))
      @new_event = # the important bit is to not have an id
        appointments: []
        participants_per_appointment: 1
        title: 'Appointment 1'
        possibleContexts: -> [{asset_string: 'course_1', course_sections: [{asset_string: 'section_1'}]}]
        context_code: 'course_1'
        context_codes: ['course_1']
        sub_context_codes: ['section_1']
        startDate: -> fcUtil.wrap('2015-08-07T17:00:00Z')
        allDay: false
      @existing_event = $.extend({id: 1}, @new_event)
      @contexts = [{asset_string: 'course_1', course_sections: [{asset_string: 'section_1'}], can_create_appointment_groups: {all_sections: true}}]

   teardown: ->
      # tick past any remaining errorBox fade-ins
      @$holder.detach()
      document.getElementById("fixtures").innerHTML = ""
      tz.restore(@snapshot)

  test "disable context and group controls when editing an existing appointment", ->
    instance = new EditAppointmentGroupDetails('#fixtures', @existing_event, @contexts, null)
    equal instance.form.find('#option_course_1').attr('disabled'), 'disabled'
    equal instance.form.find('.group-signup-checkbox').attr('disabled'), 'disabled'
