/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import ReactModal from 'react-modal'
import store from '../../external_apps/lib/ExternalAppsStore'
import 'compiled/jquery.rails_flash_notifications'

const modalOverrides = {
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  },
  content: {
    position: 'static',
    top: '0',
    left: '0',
    right: 'auto',
    bottom: 'auto',
    borderRadius: '0',
    border: 'none',
    padding: '0'
  }
}

export default class ExternalToolPlacementButton extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    type: PropTypes.string, // specify "button" if this is not a menu item
    onClose: PropTypes.func
  }

  state = {
    tool: this.props.tool,
    modalIsOpen: false
  }

  componentDidUpdate() {
    const _this = this
    window.requestAnimationFrame(() => {
      if (_this.refs.closex) {
        _this.refs.closex.focus()
      }
    })
  }

  openModal = e => {
    e.preventDefault()
    if (this.props.tool.app_type === 'ContextExternalTool') {
      store.fetchWithDetails(this.props.tool).then(data => {
        const tool = _.extend(data, this.props.tool)
        this.setState({
          tool,
          modalIsOpen: true
        })
      })
    } else {
      this.setState({
        tool: this.props.tool,
        modalIsOpen: true
      })
    }
  }

  closeModal = () => {
    this.setState({modalIsOpen: false}, () => {
      if (this.props.onClose) this.props.onClose()
    })
  }

  placements = () => {
    const allPlacements = {
      account_navigation: I18n.t('Account Navigation'),
      assignment_edit: I18n.t('Assignment Edit'),
      assignment_selection: I18n.t('Assignment Selection'),
      assignment_view: I18n.t("Assignment View"),
      similarity_detection: I18n.t('Similarity Detection'),
      assignment_menu: I18n.t('Assignment Menu'),
      collaboration: I18n.t('Collaboration'),
      course_assignments_menu: I18n.t('Course Assignments Menu'),
      course_home_sub_navigation: I18n.t('Course Home Sub Navigation'),
      course_navigation: I18n.t('Course Navigation'),
      course_settings_sub_navigation: I18n.t('Course Settings Sub Navigation'),
      discussion_topic_menu: I18n.t('Discussion Topic Menu'),
      editor_button: I18n.t('Editor Button'),
      file_menu: I18n.t('File Menu'),
      global_navigation: I18n.t('Global Navigation'),
      homework_submission: I18n.t('Homework Submission'),
      link_selection: I18n.t('Link Selection'),
      migration_selection: I18n.t('Migration Selection'),
      module_menu: I18n.t('Module Menu'),
      post_grades: I18n.t('Sync Grades'),
      quiz_menu: I18n.t('Quiz Menu'),
      tool_configuration: I18n.t('Tool Configuration'),
      user_navigation: I18n.t('User Navigation'),
      wiki_page_menu: I18n.t('Page Menu')
    }

    const tool = this.state.tool
    let hasPlacements = false
    const appliedPlacements = _.map(allPlacements, (value, key) => {
      if (
        tool[key] ||
        (tool.resource_selection && key == 'assignment_selection') ||
        (tool.resource_selection && key == 'link_selection')
      ) {
        hasPlacements = true
        return <div>{value}</div>
      }
    })
    return hasPlacements ? appliedPlacements : null
  }

  getModal = () => (
    <ReactModal
      ref="reactModal"
      isOpen={this.state.modalIsOpen}
      onRequestClose={this.closeModal}
      style={modalOverrides}
      className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
      overlayClassName="ReactModal__Overlay--canvas"
    >
      <div id={`${this.state.tool.name}Heading`} className="ReactModal__Layout">
        <div className="ReactModal__Header">
          <div className="ReactModal__Header-Title">
            <h4 tabIndex="-1">{I18n.t('App Placements')}</h4>
          </div>
          <div className="ReactModal__Header-Actions">
            <button
              className="Button Button--icon-action"
              type="button"
              ref="closex"
              onClick={this.closeModal}
            >
              <i className="icon-x" />
              <span className="screenreader-only">Close</span>
            </button>
          </div>
        </div>
        <div tabIndex="-1" className="ReactModal__Body">
          <div id={`${this.state.tool.name.replace(/\s/g, '')}Placements`}>
            {this.placements() || I18n.t('No Placements Enabled')}
          </div>
        </div>
        <div className="ReactModal__Footer">
          <div className="ReactModal__Footer-Actions">
            <button
              ref="btnClose"
              type="button"
              className="btn btn-default"
              id={`close${this.state.tool.name}`}
              onClick={this.closeModal}
            >
              {I18n.t('Close')}
            </button>
          </div>
        </div>
      </div>
    </ReactModal>
  )

  getButton = () => {
    const editAriaLabel = I18n.t('View %{toolName} Placements', {toolName: this.state.tool.name})

    if (this.props.type === 'button') {
      return (
        <a
          href="#"
          ref="placementButton"
          role="button"
          aria-label={editAriaLabel}
          className="btn long"
          onClick={this.openModal}
        >
          <i className="icon-info" data-tooltip="left" title={I18n.t('Tool Placements')} />
          {this.getModal()}
        </a>
      )
    } else {
      return (
        <li role="presentation" className="ExternalToolPlacementButton">
          <a
            href="#"
            tabIndex="-1"
            ref="placementButton"
            role="menuitem"
            aria-label={editAriaLabel}
            className="icon-info"
            onClick={this.openModal}
          >
            {I18n.t('Placements')}
          </a>
          {this.getModal()}
        </li>
      )
    }
  }

  render() {
    if (this.state.tool.app_type === 'ContextExternalTool') {
      return this.getButton()
    }
    return false
  }
}
