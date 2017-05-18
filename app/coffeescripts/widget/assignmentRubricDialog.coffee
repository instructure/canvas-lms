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

define [
  'i18n!rubrics'
  'jquery'
  'str/htmlEscape'
  'jqueryui/dialog'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, htmlEscape) ->

  assignmentRubricDialog =

    # the markup for the trigger should look like:
    # <a class="rubric_dialog_trigger" href="#" data-rubric-exists="<%= !!attached_rubric %>" data-url="<%= context_url(@topic.assignment.context, :context_assignment_rubric_url, @topic.assignment.id) %>">
    #   <%= attached_rubric ? t(:show_rubric, "Show Rubric") : t(:add_rubric, "Add Rubric") %>
    # </a>

    initTriggers: ->
      if $trigger = $('.rubric_dialog_trigger')
        @noRubricExists = $trigger.data('noRubricExists')
        @url = $trigger.data('url')
        @$focusReturnsTo = $ $trigger.data('focusReturnsTo')

        $trigger.click (event) ->
          event.preventDefault()
          assignmentRubricDialog.openDialog()

    initDialog: ->
      @dialogInited = true

      @$dialog = $("<div><h4>#{htmlEscape I18n.t 'loading', 'Loading...'}</h4></div>").dialog
        title: I18n.t("titles.assignment_rubric_details", "Assignment Rubric Details")
        width: 600
        modal: false
        resizable: true
        autoOpen: false
        close: => @$focusReturnsTo.focus()

      $.get @url, (html) ->

        # if there is not already a rubric, we want to click the "add rubric" button for them,
        # since that is the point of why they clicked the link.
        if assignmentRubricDialog.noRubricExists
          $.subscribe 'edit_rubric/initted', ->
            assignmentRubricDialog.$dialog.find('.btn.add_rubric_link').click()

        # weird hackery because the server returns a <div id="rubrics" style="display:none">
        # as it's root node, so we need to show it before we inject it
        assignmentRubricDialog.$dialog.html $(html).show()

    openDialog: ->
      @initDialog() unless @dialogInited
      @$dialog.dialog 'open'
