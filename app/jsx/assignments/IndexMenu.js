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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!assignment_index_menu'
import ExternalToolModalLauncher from '../shared/ExternalToolModalLauncher'
import Actions from './actions/IndexMenuActions'
import ReactDOM from 'react-dom'
import ContentTypeExternalToolTray from 'jsx/shared/ContentTypeExternalToolTray'
import {ltiState} from '../../../public/javascripts/lti/post_message/handleLtiPostMessage'

export default class IndexMenu extends React.Component {
  static propTypes = {
    store: PropTypes.object.isRequired,
    contextType: PropTypes.string.isRequired,
    contextId: PropTypes.number.isRequired,
    requestBulkEdit: PropTypes.func, // not required. no menu item if not specified
    setTrigger: PropTypes.func.isRequired,
    setDisableTrigger: PropTypes.func.isRequired,
    registerWeightToggle: PropTypes.func.isRequired,
    disableSyncToSis: PropTypes.func.isRequired,
    sisName: PropTypes.string.isRequired,
    postToSisDefault: PropTypes.bool.isRequired,
    hasAssignments: PropTypes.bool.isRequired,
    assignmentGroupsCollection: PropTypes.object
  }

  state = this.props.store.getState()

  UNSAFE_componentWillMount() {
    this.setState(this.props.store.getState())
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(() => {
      this.setState(this.props.store.getState())
    })

    const toolsUrl = [
      '/api/v1/',
      this.props.contextType,
      's/',
      this.props.contextId,
      '/lti_apps/launch_definitions?placements[]=course_assignments_menu'
    ].join('')

    this.props.store.dispatch(Actions.apiGetLaunches(null, toolsUrl))
    this.props.setTrigger(this.refs.trigger)
    this.props.setDisableTrigger(this.disableTrigger)
    this.props.registerWeightToggle('weightedToggle', this.onWeightedToggle, this)
  }

  componentWillUnmount() {
    this.unsubscribe()
  }

  onWeightedToggle = value => {
    this.props.store.dispatch(Actions.setWeighted(value))
  }

  onLaunchTool = tool => e => {
    e.preventDefault()
    this.props.store.dispatch(Actions.launchTool(tool))
  }

  closeModal = () => {
    this.props.store.dispatch(Actions.setModalOpen(false))
  }

  renderWeightIcon = () => {
    if (this.state && this.state.weighted) {
      return <i className="icon-check" />
    }
    return <i className="icon-blank" />
  }

  renderDisablePostToSis = () => {
    if (this.props.hasAssignments && this.props.postToSisDefault) {
      return (
        <li role="menuitem">
          <a
            ref={node => {
              this.disableTrigger = node
            }}
            href="#"
            role="button"
            id="assignmentDisableSyncCog"
            title={I18n.t('Disable Sync to %{name}', {name: this.props.sisName})}
            aria-label={I18n.t('Disable Sync to %{name}', {name: this.props.sisName})}
            data-focus-returns-to="course_assignment_settings_link"
            onClick={() => {
              this.props.setDisableTrigger(this.disableTrigger)
              this.props.disableSyncToSis()
            }}
          >
            {I18n.t('Disable Sync to %{name}', {name: this.props.sisName})}
          </a>
        </li>
      )
    }
  }

  renderTools = () =>
    this.state.externalTools.map(tool => (
      <li key={tool.definition_id} role="menuitem">
        <a aria-label={tool.name} href="#" onClick={this.onLaunchTool(tool)}>
          <i className="icon-import" />
          {tool.name}
        </a>
      </li>
    ))

  renderTrayTools = () => {
    if (ENV.assignment_index_menu_tools) {
      return ENV.assignment_index_menu_tools.map(tool => (
        <li key={tool.id} role="menuitem">
          <a aria-label={tool.title} href="#" onClick={this.onLaunchTrayTool(tool)}>
            {this.iconForTrayTool(tool)}
            {tool.title}
          </a>
        </li>
      ))
    }
  }

  iconForTrayTool(tool) {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon" alt="" src={tool.icon_url} />
    }
  }

  onLaunchTrayTool = tool => e => {
    if (e != null) {
      e.preventDefault()
    }
    this.setExternalToolTray(tool, document.getElementById('course_assignment_settings_link'))
  }

  setExternalToolTray(tool, returnFocusTo) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        window.location.reload()
      }
    }
    const groupData = [
      {
        course_id: this.props.contextId,
        type: 'assignment_group'
      }
    ]
    ReactDOM.render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="assignment_index_menu"
        acceptedResourceTypes={['assignment']}
        targetResourceType="assignment"
        allowItemSelection
        selectableItems={groupData}
        onDismiss={handleDismiss}
        open={tool !== null}
      />,
      document.getElementById('external-tool-mount-point')
    )
  }

  render() {
    return (
      <div
        className="inline-block"
        ref={node => {
          this.node = node
        }}
      >
        <a
          className="al-trigger btn"
          id="course_assignment_settings_link"
          role="button"
          tabIndex="0"
          title={I18n.t('Assignments Settings')}
          aria-label={I18n.t('Assignments Settings')}
        >
          <i className="icon-more" aria-hidden="true" />
          <span className="screenreader-only">{I18n.t('Assignment Options')}</span>
        </a>
        <ul className="al-options" role="menu">
          {this.props.requestBulkEdit && (
            <li role="menuitem">
              <a
                tabIndex="0"
                id="requestBulkEditMenuItem"
                className="requestBulkEditMenuItem"
                role="button"
                title={I18n.t('Bulk Edit')}
                onClick={this.props.requestBulkEdit}
              >
                <i className="icon-edit" />
                {I18n.t('Bulk Edit')}
              </a>
            </li>
          )}
          <li role="menuitem">
            <a
              ref="trigger"
              href="#"
              id="assignmentSettingsCog"
              role="button"
              title={I18n.t('Assignment Groups Weight')}
              data-focus-returns-to="course_assignment_settings_link"
              aria-label={I18n.t('Assignment Groups Weight')}
            >
              {this.renderWeightIcon()}
              {I18n.t('Assignment Groups Weight')}
            </a>
          </li>
          {this.renderDisablePostToSis()}
          {this.renderTools()}
          {this.renderTrayTools()}
        </ul>
        {this.state.modalIsOpen && (
          <ExternalToolModalLauncher
            tool={this.state.selectedTool}
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}
            contextType={this.props.contextType}
            contextId={this.props.contextId}
            launchType="course_assignments_menu"
            title={
              this.state.selectedTool &&
              this.state.selectedTool.placements.course_assignments_menu.title
            }
          />
        )}
      </div>
    )
  }
}
