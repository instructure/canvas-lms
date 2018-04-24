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
  'Backbone'
  'i18n!assignments'
  'jquery'
  'underscore'
  'jst/assignments/homework_submission_tool'
  '../views/ExternalTools/ExternalContentReturnView',
  '../external_tools/ExternalToolCollection'
  '../views/assignments/ExternalContentFileSubmissionView'
  '../views/assignments/ExternalContentUrlSubmissionView'
  '../views/assignments/ExternalContentLtiLinkSubmissionView'
  '../../../public/javascripts/submit_assignment_helper'
  'jquery.disableWhileLoading'
], ( Backbone, I18n, $, _, homeworkSubmissionTool, ExternalContentReturnView,
     ExternalToolCollection, ExternalContentFileSubmissionView,
     ExternalContentUrlSubmissionView, ExternalContentLtiLinkSubmissionView,
     SubmitAssignmentHelper) ->

  class HomeworkSubmissionLtiContainer
    @homeworkSubmissionViewMap:
      FileItem: ExternalContentFileSubmissionView
      LtiLinkItem: ExternalContentLtiLinkSubmissionView

    constructor: (toolsFormSelector) ->
      @renderedViews = {}
      @toolsForm = $(toolsFormSelector)
      @externalToolCollection = new ExternalToolCollection
      @externalToolCollection.add(ENV.EXTERNAL_TOOLS)

    # load external tools and populate 'More' tab with the returned tools
    loadExternalTools: ->
      if @externalToolCollection.length > 0
        $(".submit_from_external_tool_option").parent().show() # display the 'More' tab
        @toolsForm.find("ul.tools").empty()
        @externalToolCollection.forEach (tool) =>
          @addToolToMoreList(tool)
      else
        @toolsForm.find("ul.tools li").text I18n.t("no_tools_found", "No tools found")

    # embed the LTI iframe into the tab contents
    embedLtiLaunch: (toolId) ->
      tool = @externalToolCollection.findWhere({ id: toolId.toString(10) })
      @cleanupViewsForTool(tool)
      returnView = @createReturnView(tool)
      $('#submit_from_external_tool_form_' + toolId).prepend(returnView.el)
      returnView.render()
      @renderedViews[toolId.toString(10)].push(returnView)

    # private methods below ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    cleanupViewsForTool: (tool) ->
      if _.has @renderedViews, tool.get('id')
        views = @renderedViews[tool.get('id')]
        views.forEach (v) =>
          v.remove()
      @renderedViews[tool.get('id')] = []

    cancelSubmission: ->
      $('#submit_assignment').hide()
      $('.submit_assignment_link').show()

    addToolToMoreList: (tool) ->
      tool.attributes.display_text = tool.get('homework_submission').label
      html = homeworkSubmissionTool(tool.attributes)
      $li = $(html).data('tool', tool)
      @toolsForm.find("ul.tools").append $li

    createReturnView: (tool) ->
      returnView = new ExternalContentReturnView
        model: tool
        launchType: 'homework_submission'
        launchParams: { assignment_id: ENV.SUBMIT_ASSIGNMENT.ID }
        displayAsModal: false

      returnView.on 'ready', (data) =>
        tool = `this.model` # this will return the model from returnView
        homeworkSubmissionView = @createHomeworkSubmissionView(tool, data)
        homeworkSubmissionView.parentView = this

        `this.remove()`
        $('#submit_from_external_tool_form_' + tool.get('id')).append(homeworkSubmissionView.el)

        @cleanupViewsForTool(tool)
        @renderedViews[tool.get('id')].push(homeworkSubmissionView)
        homeworkSubmissionView.render()
        $('input.turnitin_pledge').click (e) ->
          SubmitAssignmentHelper.recordEulaAgreement('#eula_agreement_timestamp', e.target.checked)

      returnView.on 'cancel', (data) ->
        return

      return returnView

    createHomeworkSubmissionView: (tool, data) ->
      item = data.contentItems[0]
      viewClass = HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap[item['@type']] || ExternalContentUrlSubmissionView

      homeworkSubmissionView = new viewClass
        externalTool: tool
        model: new Backbone.Model(item)

      homeworkSubmissionView.on 'relaunchTool', (tool, model) ->
        @remove()
        @parentView.embedLtiLaunch(tool.get('id'))

      homeworkSubmissionView.on 'cancel', (tool, model) ->
        @parentView.cancelSubmission()

      return homeworkSubmissionView
