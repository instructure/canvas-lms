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
import I18n from 'i18n!moderated_grading'
import 'compiled/jquery.rails_flash_notifications'
import iframeAllowances from '../external_apps/lib/iframeAllowances'

class AssignmentExternalTools extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tools: [],
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      iframeStyle: {}
    }
  }

  componentWillMount() {
    this.getTools();
  }

  componentDidMount() {
    if (this.state.tools) {
      for (let i = 0; i < this.state.tools.length; i++) {
        const tool = this.state.tools[i]
        this[`tool_iframe_${tool.definition_id}`].setAttribute('allow', iframeAllowances());
      }
    }
  }

  getMaxIFrameWidth = () => {
    if (this.state.tools) {
      let max_width = 0
      for (let i = 0; i < this.state.tools.length; i++) {
        const tool = this.state.tools[i]
        const width = this[`tool_iframe_${tool.definition_id}`].offsetWidth
        if (width > max_width) max_width = width;
      }
      return max_width;
    }
    return null;
  }

  getTools() {
    const self = this;
    const toolsUrl = this.getDefinitionsUrl();
    const data = {
      'placements[]': this.props.placement
    };

    $.ajax({
      type: 'GET',
      url: toolsUrl,
      data,
      success: $.proxy(function(data) {
        const tool_data = data
        for (let i = 0; i < data.length; i++) {
          tool_data[i].launch = this.getLaunch(data[i]);
        }
        this.setState({
          tools: tool_data
        });
      }, self),
      error(_xhr) {
        $.flashError(I18n.t('Error retrieving assignment external tools'));
      }
    });
  }

  getDefinitionsUrl() {
    return `/api/v1/courses/${this.props.courseId}/lti_apps/launch_definitions`;
  }

  getLaunch(tool) {
    const url = tool.placements[this.props.placement].url

    let query = `?borderless=true&url=${encodeURIComponent(url)}&placement=${this.props.placement}`;
    if (this.props.assignmentId) {
      query += `&assignment_id=${this.props.assignmentId}`
    }
    const endpoint = `/courses/${this.props.courseId}/external_tools/retrieve`;

    return endpoint + query;
  }

  handleAlertFocus = (event) => {
    const newState = {
      iframeStyle: { border: '2px solid #008EE2', width: `${this.getMaxIFrameWidth() - 4}px` }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  handleAlertBlur = (event) => {
    const newState = {
      iframeStyle: { border: 'none', width: '100%' }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  renderTool(tool) {
    const styles = {}
    $.extend(styles, this.state.iframeStyle)
    if (tool.placements[this.props.placement].launch_height) {
      styles.height = tool.placements[this.props.placement].launch_height
      styles.minHeight = 'unset'
    }
    if (tool.placements[this.props.placement].launch_width) {
      styles.width = tool.placements[this.props.placement].launch_width
    }
    return(
      <iframe
        src={tool.launch}
        className="tool_launch"
        style={styles}
        key={tool.definition_id}
        title={I18n.t('External Tool %{tool_id}', {tool_id: tool.definition_id})}
        ref={(e) => { this[`tool_iframe_${tool.definition_id}`] = e; }}
      />
    )
  }

  renderToolsContainer() {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return(
      <div style={{ display: this.state.toolLaunchUrl === 'about:blank' ? 'none' : 'block' }}>
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={beforeAlertStyles}
          tabIndex="0"
        >
          <div className="ic-flash-info" style={{ width: 'auto', margin: '20px' }}>
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The following content is partner provided')}
          </div>
        </div>
        {
          this.state.tools.map(tool => this.renderTool(tool))
        }

        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={afterAlertStyles}
          tabIndex="0"
        >
          <div className="ic-flash-info" style={{ width: 'auto', margin: '20px' }}>
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The preceding content is partner provided')}
          </div>
        </div>
      </div>
    );
  }

  render() {
    if (this.state.tools.length === 0) {
      return (<div />)
    }
    return (
      <div>
        <div className="border border-trbl border-round">
          {this.renderToolsContainer()}
        </div>
      </div>
    )
  }
}

AssignmentExternalTools.propTypes = {
  placement: PropTypes.string.isRequired,
  courseId: PropTypes.number.isRequired,
  assignmentId: PropTypes.number
}


AssignmentExternalTools.defaultProps = {
  assignmentId: undefined
}

const attach = function(element, placement, courseId, assignmentId) {
  const configTools = (
    <AssignmentExternalTools
      placement={placement}
      courseId ={courseId}
      assignmentId={assignmentId}
    />
  );
  ReactDOM.render(configTools, element);
};

const ConfigurationTools = {
  configTools: AssignmentExternalTools,
  attach
};

export default ConfigurationTools
