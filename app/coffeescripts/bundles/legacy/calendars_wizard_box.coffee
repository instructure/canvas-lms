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

define [
  "jquery",
  "jquery.instructure_misc_plugins"
], ($) ->
  $(document).ready ->
    $(document).bind("edit_event_dialog", ->
      if $("#wizard_box .option.create_calendar_event_option.selected").length > 0
        $("#wizard_box .edit_calendar_event_option").click()
      else $("#wizard_box .tab_assignment_option").click()  if $("#wizard_box .option.create_assignment_option.selected").length > 0
    ).bind("event_dialog", ->
      $("#wizard_box .confirm_delete_calendar_event_option").click()  if $("#wizard_box .option.delete_calendar_event_option.selected").length > 0
    ).bind("event_tag_select", (event, index) ->
      $("#wizard_box .edit_assignment_option").click()  if index is 1 and $("#wizard_box .option.tab_assignment_option.selected").length > 0
    ).bind("add_event", (event, $object) ->
      if $("#wizard_box .option.edit_calendar_event_option.selected").length > 0
        $("#wizard_box .review_calendar_event_option").click()
      else $("#wizard_box .review_assignment_option").click()  if $("#wizard_box .option.edit_assignment_option.selected").length > 0
    ).bind "delete_event", ->
      $("#wizard_box .review_delete_calendar_event_option").click()  if $("#wizard_box .option.confirm_delete_calendar_event_option.selected").length > 0

    $(".highlight_calendar_event_title").hover (->
      $("#edit_calendar_event_form input[name='calendar_event[title]']").indicate()
    ), ->

    $(".highlight_undated_events").hover (->
      $(".calendar_undated").indicate()
    ), ->

    $(".highlight_assignment_tab").hover (->
      $(".edit_assignment_option").indicate()
    ), ->

    $(".highlight_assignment_title").hover (->
      $("#edit_assignment_form input[name='assignment[title]']").indicate()
    ), ->

    $(".highlight_delete_event").hover (->
      $("#event_details .delete_event_link").indicate()
    ), ->