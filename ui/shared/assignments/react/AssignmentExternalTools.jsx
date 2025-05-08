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
import {useScope as createI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import {asJson, getPrefetchedXHR, defaultFetchOptions} from '@canvas/util/xhr'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = createI18nScope('moderated_grading')

class AssignmentExternalTools extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      tools: [],
    }
  }

  UNSAFE_componentWillMount() {
    this.getTools()
  }

  componentDidMount() {
    if (this.state.tools) {
      for (let i = 0; i < this.state.tools.length; i++) {
        const tool = this.state.tools[i]
        this[`tool_iframe_${tool.definition_id}`].setAttribute('allow', iframeAllowances())
      }
    }
  }

  getMaxIFrameWidth = () => {
    if (this.state.tools) {
      let max_width = 0
      for (let i = 0; i < this.state.tools.length; i++) {
        const tool = this.state.tools[i]
        const width = this[`tool_iframe_${tool.definition_id}`].offsetWidth
        if (width > max_width) max_width = width
      }
      return max_width
    }
    return null
  }

  async getTools() {
    const url = encodeURI(`${this.getDefinitionsUrl()}?placements[]=${this.props.placement}`)

    try {
      const request = getPrefetchedXHR(url) || fetch(url, defaultFetchOptions())
      const tools = await asJson(request)
      tools.forEach(t => (t.launch = this.getLaunch(t)))
      this.setState({tools})
    } catch (e) {
      $.flashError(I18n.t('Error retrieving assignment external tools'))
    }
  }

  getDefinitionsUrl() {
    return `/api/v1/courses/${this.props.courseId}/lti_apps/launch_definitions`
  }

  getLaunch(tool) {
    const url = tool.placements[this.props.placement].url

    let query = `?borderless=true&url=${encodeURIComponent(url)}&placement=${this.props.placement}`
    if (this.props.assignmentId) {
      query += `&assignment_id=${this.props.assignmentId}`
    }
    const endpoint = `/courses/${this.props.courseId}/external_tools/retrieve`

    return endpoint + query
  }

  renderTool(tool) {
    const styles = {}
    if (tool.placements[this.props.placement].launch_height) {
      styles.height = tool.placements[this.props.placement].launch_height
      styles.minHeight = 'unset'
    }
    if (tool.placements[this.props.placement].launch_width) {
      styles.width = tool.placements[this.props.placement].launch_width
    }
    return (
      <ToolLaunchIframe
        src={tool.launch}
        style={styles}
        key={tool.definition_id}
        title={I18n.t('External Tool %{tool_id}', {tool_id: tool.definition_id})}
        ref={e => {
          this[`tool_iframe_${tool.definition_id}`] = e
        }}
      />
    )
  }

  renderToolsContainer() {
    return (
      <div style={{display: this.state.toolLaunchUrl === 'about:blank' ? 'none' : 'block'}}>
        {this.state.tools.map(tool => this.renderTool(tool))}
      </div>
    )
  }

  render() {
    if (this.state.tools.length === 0) {
      return <div />
    }
    return (
      <div>
        <div className="border border-trbl border-round">{this.renderToolsContainer()}</div>
      </div>
    )
  }
}

AssignmentExternalTools.propTypes = {
  placement: PropTypes.string.isRequired,
  courseId: PropTypes.number.isRequired,
  assignmentId: PropTypes.number,
}

AssignmentExternalTools.defaultProps = {
  assignmentId: undefined,
}

const attach = function (element, placement, courseId, assignmentId) {
  const configTools = (
    <AssignmentExternalTools
      placement={placement}
      courseId={courseId}
      assignmentId={assignmentId}
    />
  )

  ReactDOM.render(configTools, element)
}

const ConfigurationTools = {
  configTools: AssignmentExternalTools,
  attach,
}

export default ConfigurationTools
