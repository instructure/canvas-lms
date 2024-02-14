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
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {IconAddSolid} from '@instructure/ui-icons'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import Actions from './actions/IndexMenuActions'
import ReactDOM from 'react-dom'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import type {SelectableItem} from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ltiState} from '@canvas/lti/jquery/messages'

const I18n = useI18nScope('assignment_index_menu')

type Props = {
  store: any
  contextType: string
  contextId: string
  requestBulkEdit?: () => void
  setTrigger: (node: HTMLElement | null) => void
  setDisableTrigger: (node: HTMLElement | null) => void
  registerWeightToggle: (name: string, callback: (value: boolean) => void, context: any) => void
  disableSyncToSis: () => void
  sisName: string
  postToSisDefault: boolean
  hasAssignments: boolean
}

type State = {
  externalTools: any[]
  modalIsOpen: boolean
  selectedTool: any
  weighted: boolean
}

export default class IndexMenu extends React.Component<Props, State> {
  triggerRef: HTMLElement | null

  unsubscribe: () => void = () => {}

  node: HTMLDivElement | null = null

  disableTrigger: HTMLButtonElement | null = null

  constructor(props: Props) {
    super(props)
    this.state = props.store.getState()
    this.triggerRef = null
  }

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
      '/lti_apps/launch_definitions?placements[]=course_assignments_menu',
    ].join('')

    this.props.store.dispatch(Actions.apiGetLaunches(null, toolsUrl))
    this.props.setTrigger(this.triggerRef)
    this.props.setDisableTrigger(this.disableTrigger)
    this.props.registerWeightToggle('weightedToggle', this.onWeightedToggle, this)
  }

  componentWillUnmount() {
    this.clearExternalToolTray()
    this.unsubscribe()
  }

  onWeightedToggle = (value: any) => {
    this.props.store.dispatch(Actions.setWeighted(value))
  }

  onLaunchTool = (tool: any) => (e: React.MouseEvent<HTMLAnchorElement, MouseEvent>) => {
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
          <button
            type="button"
            ref={node => {
              this.disableTrigger = node
            }}
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
          </button>
        </li>
      )
    }
  }

  renderTools = () =>
    this.state.externalTools.map(tool => (
      <li key={tool.definition_id} role="menuitem">
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a aria-label={tool.name} href="#" onClick={this.onLaunchTool(tool)}>
          <i className="icon-import" />
          {tool.name}
        </a>
      </li>
    ))

  renderTrayTools = () => {
    // @ts-expect-error
    if (ENV.assignment_index_menu_tools) {
      // @ts-expect-error
      return ENV.assignment_index_menu_tools.map(tool => (
        <li key={tool.id} role="menuitem">
          {/* TODO: use InstUI button */}
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a aria-label={tool.title} href="#" onClick={this.onLaunchTrayTool(tool)}>
            {this.iconForTrayTool(tool)}
            {tool.title}
          </a>
        </li>
      ))
    }
  }

  iconForTrayTool(tool: {canvas_icon_class: string; icon_url: string}) {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon" alt="" src={tool.icon_url} />
    }
  }

  onLaunchTrayTool =
    (tool: string | null) => (e: React.MouseEvent<HTMLAnchorElement, MouseEvent>) => {
      if (e != null) {
        e.preventDefault()
      }
      this.setExternalToolTray(tool, document.getElementById('course_assignment_settings_link'))
    }

  setExternalToolTray(tool: any, returnFocusTo: any = null) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        window.location.reload()
      }
    }
    const groupData: SelectableItem[] = [
      {
        course_id: this.props.contextId,
        type: 'assignment_group',
      },
    ]
    ReactDOM.render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="assignment_index_menu"
        acceptedResourceTypes={['assignment']}
        targetResourceType="assignment"
        allowItemSelection={true}
        selectableItems={groupData}
        onDismiss={handleDismiss}
        onExternalContentReady={() => window.location.reload()}
        open={tool !== null}
      />,
      document.getElementById('external-tool-mount-point')
    )
  }

  clearExternalToolTray = () => {
    // unmount tray component and clear its postMessage handler
    const mountPointDomElement = document.getElementById('external-tool-mount-point')
    if (mountPointDomElement) {
      ReactDOM.unmountComponentAtNode(mountPointDomElement)
    }
  }

  render() {
    return (
      <div
        className="inline-block"
        ref={node => {
          this.node = node
        }}
      >
        <>
          <button
            type="button"
            className="al-trigger btn Button"
            id="course_assignment_settings_link"
            tabIndex={0}
            title={I18n.t('Assignments Settings')}
            aria-label={I18n.t('Assignments Settings')}
          >
            <i className="icon-more" aria-hidden="true" />
            <span className="screenreader-only">{I18n.t('Assignment Options')}</span>
          </button>
          <ul className="al-options" role="menu">
            {this.props.requestBulkEdit && (
              <li role="menuitem">
                {/* TODO: use InstUI button */}
                {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
                <a
                  href="#"
                  tabIndex={0}
                  id="requestBulkEditMenuItem"
                  className="requestBulkEditMenuItem"
                  role="button"
                  title={I18n.t('Edit Dates')}
                  onClick={this.props.requestBulkEdit}
                >
                  <i className="icon-edit" />
                  {I18n.t('Edit Assignment Dates')}
                </a>
              </li>
            )}
            <li role="menuitem">
              {/* TODO: use InstUI button */}
              {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
              <a
                ref={ref => {
                  this.triggerRef = ref
                }}
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
        </>
      </div>
    )
  }
}
