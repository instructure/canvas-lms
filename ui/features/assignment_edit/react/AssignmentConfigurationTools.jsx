/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import OriginalityReportVisibilityPicker from './OriginalityReportVisibilityPicker'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = useI18nScope('moderated_grading')

class AssignmentConfigurationTools extends React.Component {
  static displayName = 'AssignmentConfigurationTools'

  static propTypes = {
    courseId: PropTypes.number.isRequired,
    secureParams: PropTypes.string.isRequired,
    selectedTool: PropTypes.number,
    selectedToolType: PropTypes.string,
    visibilitySetting: PropTypes.string,
  }

  state = {
    toolLaunchUrl: 'about:blank',
    toolType: '',
    tools: [],
    selectedToolValue: `${this.props.selectedToolType}_${this.props.selectedTool}`,
    beforeExternalContentAlertClass: 'screenreader-only',
    afterExternalContentAlertClass: 'screenreader-only',
    iframeStyle: {},
    visibilityEnabled: !!this.props.selectedTool,
  }

  UNSAFE_componentWillMount() {
    this.getTools()
  }

  componentDidMount() {
    this.setToolLaunchUrl()

    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  getTools = () => {
    const self = this
    const toolsUrl = this.getDefinitionsUrl()
    const data = {
      'placements[]': 'similarity_detection',
    }

    $.ajax({
      type: 'GET',
      url: toolsUrl,
      data,
      success: $.proxy(function (data) {
        let prevToolLaunch
        if (this.props.selectedTool && this.props.selectedToolType) {
          for (let i = 0; i < data.length; i++) {
            if (
              data[i].definition_id == this.props.selectedTool &&
              data[i].definition_type === this.props.selectedToolType
            ) {
              prevToolLaunch = this.getLaunch(data[i])
              break
            }
          }
        }
        this.setState({
          tools: data,
          toolType: this.props.selectedToolType || '',
          toolLaunchUrl: prevToolLaunch || 'about:blank',
        })
      }, self),
      error(_xhr) {
        $.flashError(I18n.t('Error retrieving similarity detection tools'))
      },
    })
  }

  getDefinitionsUrl = () => `/api/v1/courses/${this.props.courseId}/lti_apps/launch_definitions`

  getLaunch = tool => {
    const url = tool.placements.similarity_detection.url
    let query = ''
    let endpoint = ''

    if (tool.definition_type === 'ContextExternalTool') {
      query = `?borderless=true&url=${encodeURIComponent(url)}&secure_params=${
        this.props.secureParams
      }`
      endpoint = `/courses/${this.props.courseId}/external_tools/retrieve`
    } else {
      query = `?display=borderless&secure_params=${this.props.secureParams}`
      endpoint = `/courses/${this.props.courseId}/lti/basic_lti_launch_request/${tool.definition_id}`
    }

    return endpoint + query
  }

  setToolLaunchUrl = () => {
    const selectBox = this.similarityDetectionTool
    this.setState({
      toolLaunchUrl: selectBox[selectBox.selectedIndex].getAttribute('data-launch'),
      toolType: selectBox[selectBox.selectedIndex].getAttribute('data-type') || '',
    })
  }

  handleSelectionChange = event => {
    event.preventDefault()
    this.setState(
      {
        selectedToolValue: event.target.value,
        visibilityEnabled: event.target.value.toLowerCase().indexOf('none') === -1,
      },
      () => this.setToolLaunchUrl()
    )
  }

  handleAlertFocus = event => {
    const newState = {
      iframeStyle: {border: '2px solid #0374B5', width: `${this.iframe.offsetWidth - 4}px`},
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  handleAlertBlur = event => {
    const newState = {
      iframeStyle: {border: 'none', width: '100%'},
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  renderOptions = () => (
    <select
      id="similarity_detection_tool"
      name="similarityDetectionTool"
      onChange={this.handleSelectionChange}
      ref={c => {
        this.similarityDetectionTool = c
      }}
      value={this.state.selectedToolValue}
    >
      <option title="Plagiarism Review Tool" data-launch="about:blank" data-type="none">
        {I18n.t('None')}
      </option>
      {this.state.tools.map(tool => (
        <option
          title="Plagiarism Review Tool"
          key={`${tool.definition_type}_${tool.definition_id}`}
          value={`${tool.definition_type}_${tool.definition_id}`}
          data-launch={this.getLaunch(tool)}
          data-type={tool.definition_type}
        >
          {tool.name}
        </option>
      ))}
    </select>
  )

  renderToolType = () => (
    <input
      type="hidden"
      id="configuration-tool-type"
      name="configuration_tool_type"
      value={this.state.toolType}
    />
  )

  renderConfigTool = () => {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`
    return (
      <div style={{display: this.state.toolLaunchUrl === 'about:blank' ? 'none' : 'block'}}>
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={beforeAlertStyles}
          // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
          tabIndex="0"
        >
          <div className="ic-flash-info" style={{width: 'auto', margin: '20px'}}>
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The following content is partner provided')}
          </div>
        </div>
        <ToolLaunchIframe
          src={this.state.toolLaunchUrl}
          style={this.state.iframeStyle}
          ref={e => {
            this.iframe = e
          }}
        />
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={afterAlertStyles}
          // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
          tabIndex={0}
        >
          <div className="ic-flash-info" style={{width: 'auto', margin: '20px'}}>
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The preceding content is partner provided')}
          </div>
        </div>
      </div>
    )
  }

  render() {
    return (
      <div>
        <div className="form-column-left">
          <label htmlFor="similarity_detection_tool">{I18n.t('Plagiarism Review')}</label>
        </div>

        <div className="form-column-right">
          <div className="border border-trbl border-round">
            {this.renderOptions()}
            {this.renderToolType()}
            {this.renderConfigTool()}
            <OriginalityReportVisibilityPicker
              isEnabled={!!this.state.visibilityEnabled}
              selectedOption={this.props.visibilitySetting}
            />
          </div>
        </div>
      </div>
    )
  }
}

const attach = function (
  element,
  courseId,
  secureParams,
  selectedTool,
  selectedToolType,
  visibilitySetting
) {
  const configTools = (
    <AssignmentConfigurationTools
      courseId={courseId}
      secureParams={secureParams}
      selectedTool={selectedTool}
      selectedToolType={selectedToolType}
      visibilitySetting={visibilitySetting}
    />
  )
  return ReactDOM.render(configTools, element)
}

const ConfigurationTools = {
  configTools: AssignmentConfigurationTools,
  attach,
}

export default ConfigurationTools
