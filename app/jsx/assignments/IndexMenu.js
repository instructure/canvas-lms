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

export default class IndexMenu extends React.Component {
  static propTypes = {
    store: PropTypes.object.isRequired,
    contextType: PropTypes.string.isRequired,
    contextId: PropTypes.number.isRequired,
    setTrigger: PropTypes.func.isRequired,
    setDisableTrigger: PropTypes.func.isRequired,
    registerWeightToggle: PropTypes.func.isRequired,
    disableSyncToSis: PropTypes.func.isRequired,
    sisName: PropTypes.string.isRequired,
    postToSisDefault: PropTypes.bool.isRequired,
    hasAssignments: PropTypes.bool.isRequired
  }

  state = this.props.store.getState()

  componentWillMount() {
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
