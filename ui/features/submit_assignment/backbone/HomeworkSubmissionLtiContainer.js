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

import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {has} from 'lodash'
import ExternalContentReturnView from '@canvas/external-tools/backbone/views/ExternalContentReturnView'
import ExternalToolCollection from './collections/ExternalToolCollection'
import ExternalContentFileSubmissionView from './views/ExternalContentFileSubmissionView'
import ExternalContentUrlSubmissionView from './views/ExternalContentUrlSubmissionView'
import ExternalContentLtiLinkSubmissionView from './views/ExternalContentLtiLinkSubmissionView'
import {recordEulaAgreement} from '../jquery/helper'
import {handleContentItem, handleDeepLinkingError} from '../deepLinking'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import {findContentExtension} from './contentExtension'
import {getEnv} from './environment'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('external_toolsHomeworkSubmissionLtiContainer')

export const isValidFileSubmission = contentItem => {
  if (!getEnv()?.SUBMIT_ASSIGNMENT?.ALLOWED_EXTENSIONS?.length) {
    return true
  }

  return getEnv().SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.includes(findContentExtension(contentItem))
}

export default class HomeworkSubmissionLtiContainer {
  constructor() {
    this.renderedViews = {}
    this.externalToolCollection = new ExternalToolCollection()
    this.externalToolCollection.add(ENV.EXTERNAL_TOOLS)
  }

  handleDeepLinking = event => {
    if (
      event.origin !== ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN ||
      !event.data ||
      event.data.subject !== 'LtiDeepLinkingResponse'
    ) {
      return
    }
    try {
      const result = processSingleContentItem(event)
      handleContentItem(result, this.contentReturnView, this.removeDeepLinkingListener)
    } catch (e) {
      handleDeepLinkingError(e, this.contentReturnView, this.embedLtiLaunch.bind(this))
    }
  }

  removeDeepLinkingListener = () => {
    window.removeEventListener('message', this.handleDeepLinking)
  }

  addDeepLinkingListener = () => {
    this.removeDeepLinkingListener()
    window.addEventListener('message', this.handleDeepLinking)
  }

  // embed the LTI iframe into the tab contents
  embedLtiLaunch(toolId) {
    const tool = this.externalToolCollection.findWhere({id: toolId.toString(10)})
    this.cleanupViewsForTool(tool)
    const returnView = this.createReturnView(tool)
    this.addDeepLinkingListener()
    $(`#submit_from_external_tool_form_${toolId}`).prepend(returnView.el)
    returnView.render()
    return this.renderedViews[toolId.toString(10)].push(returnView)
  }

  // private methods below ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  cleanupViewsForTool(tool) {
    if (has(this.renderedViews, tool.get('id'))) {
      const views = this.renderedViews[tool.get('id')]
      views.forEach(v => v.remove())
    }
    return (this.renderedViews[tool.get('id')] = [])
  }

  cancelSubmission() {
    $('#submit_assignment').hide()
    $('.submit_assignment_link').show()
  }

  createReturnView(tool) {
    const returnView = new ExternalContentReturnView({
      model: tool,
      launchType: 'homework_submission',
      launchParams: {assignment_id: ENV.SUBMIT_ASSIGNMENT.ID},
      displayAsModal: false,
    })

    this.contentReturnView = returnView

    returnView.on(
      'ready',
      (function (_this) {
        return function (data) {
          // render inline submitted file view
          tool = this.model // this will return the model from returnView
          const homeworkSubmissionView = _this.createHomeworkSubmissionView(tool, data)
          homeworkSubmissionView.parentView = _this
          this.remove()
          $('#submit_from_external_tool_form_' + tool.get('id')).append(homeworkSubmissionView.el)
          _this.cleanupViewsForTool(tool)
          _this.renderedViews[tool.get('id')].push(homeworkSubmissionView)
          homeworkSubmissionView.render()

          // Disable submit button if the file does not match the required type
          if (!isValidFileSubmission(homeworkSubmissionView.model.attributes)) {
            $('.external-tool-submission button[type=submit]').prop('disabled', true)
            $.flashError(I18n.t('Invalid submission file type'))
          }

          return $('input.turnitin_pledge').click(e =>
            recordEulaAgreement('#eula_agreement_timestamp', e.target.checked)
          )
        }
      })(this)
    )

    returnView.on('cancel', () => {})

    return returnView
  }

  createHomeworkSubmissionView(tool, data) {
    const item = data.contentItems[0]
    const ViewClass =
      HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap[item['@type']] ||
      ExternalContentUrlSubmissionView

    const homeworkSubmissionView = new ViewClass({
      externalTool: tool,
      model: new Backbone.Model(item),
    })

    homeworkSubmissionView.on('relaunchTool', function (t) {
      this.remove()
      return this.parentView.embedLtiLaunch(t.get('id'))
    })

    homeworkSubmissionView.on('cancel', function () {
      return this.parentView.cancelSubmission()
    })

    return homeworkSubmissionView
  }
}
HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap = {
  FileItem: ExternalContentFileSubmissionView,
  LtiLinkItem: ExternalContentLtiLinkSubmissionView,
}
