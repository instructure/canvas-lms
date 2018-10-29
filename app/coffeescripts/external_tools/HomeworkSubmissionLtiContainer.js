//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import I18n from 'i18n!assignments'
import $ from 'jquery'
import _ from 'underscore'
import homeworkSubmissionTool from 'jst/assignments/homework_submission_tool'
import ExternalContentReturnView from '../views/ExternalTools/ExternalContentReturnView'
import ExternalToolCollection from '../external_tools/ExternalToolCollection'
import ExternalContentFileSubmissionView from '../views/assignments/ExternalContentFileSubmissionView'
import ExternalContentUrlSubmissionView from '../views/assignments/ExternalContentUrlSubmissionView'
import ExternalContentLtiLinkSubmissionView from '../views/assignments/ExternalContentLtiLinkSubmissionView'
import {recordEulaAgreement} from '../../../public/javascripts/submit_assignment_helper'
import 'jquery.disableWhileLoading'

export default class HomeworkSubmissionLtiContainer {
  constructor(toolsFormSelector) {
    this.renderedViews = {}
    this.toolsForm = $(toolsFormSelector)
    this.externalToolCollection = new ExternalToolCollection()
    this.externalToolCollection.add(ENV.EXTERNAL_TOOLS)
  }

  // load external tools and populate 'More' tab with the returned tools
  loadExternalTools() {
    if (this.externalToolCollection.length > 0) {
      $('.submit_from_external_tool_option')
        .parent()
        .show() // display the 'More' tab
      this.toolsForm.find('ul.tools').empty()
      this.externalToolCollection.forEach(tool => {
        this.addToolToMoreList(tool)
      })
    } else {
      return this.toolsForm.find('ul.tools li').text(I18n.t('no_tools_found', 'No tools found'))
    }
  }

  // embed the LTI iframe into the tab contents
  embedLtiLaunch(toolId) {
    const tool = this.externalToolCollection.findWhere({id: toolId.toString(10)})
    this.cleanupViewsForTool(tool)
    const returnView = this.createReturnView(tool)
    $(`#submit_from_external_tool_form_${toolId}`).prepend(returnView.el)
    returnView.render()
    return this.renderedViews[toolId.toString(10)].push(returnView)
  }

  // private methods below ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  cleanupViewsForTool(tool) {
    if (_.has(this.renderedViews, tool.get('id'))) {
      const views = this.renderedViews[tool.get('id')]
      views.forEach(v => v.remove())
    }
    return (this.renderedViews[tool.get('id')] = [])
  }

  cancelSubmission() {
    $('#submit_assignment').hide()
    $('.submit_assignment_link').show()
  }

  addToolToMoreList(tool) {
    tool.attributes.display_text = tool.get('homework_submission').label
    const html = homeworkSubmissionTool(tool.attributes)
    const $li = $(html).data('tool', tool)
    return this.toolsForm.find('ul.tools').append($li)
  }

  createReturnView(tool) {
    const returnView = new ExternalContentReturnView({
      model: tool,
      launchType: 'homework_submission',
      launchParams: {assignment_id: ENV.SUBMIT_ASSIGNMENT.ID},
      displayAsModal: false
    })

    returnView.on('ready', (function(_this) {
      return function(data) {
        var homeworkSubmissionView;
        tool = this.model; // this will return the model from returnView
        homeworkSubmissionView = _this.createHomeworkSubmissionView(tool, data);
        homeworkSubmissionView.parentView = _this;
        this.remove();
        $('#submit_from_external_tool_form_' + tool.get('id')).append(homeworkSubmissionView.el);
        _this.cleanupViewsForTool(tool);
        _this.renderedViews[tool.get('id')].push(homeworkSubmissionView);
        homeworkSubmissionView.render();
        return $('input.turnitin_pledge').click(function(e) {
          return SubmitAssignmentHelper.recordEulaAgreement('#eula_agreement_timestamp', e.target.checked);
        });
      };
    })(this));

    returnView.on('cancel', data => {})

    return returnView
  }

  createHomeworkSubmissionView(tool, data) {
    const item = data.contentItems[0]
    const viewClass =
      HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap[item['@type']] ||
      ExternalContentUrlSubmissionView

    const homeworkSubmissionView = new viewClass({
      externalTool: tool,
      model: new Backbone.Model(item)
    })

    homeworkSubmissionView.on('relaunchTool', function(tool, model) {
      this.remove()
      return this.parentView.embedLtiLaunch(tool.get('id'))
    })

    homeworkSubmissionView.on('cancel', function(tool, model) {
      return this.parentView.cancelSubmission()
    })

    return homeworkSubmissionView
  }
}
HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap = {
  FileItem: ExternalContentFileSubmissionView,
  LtiLinkItem: ExternalContentLtiLinkSubmissionView
}
