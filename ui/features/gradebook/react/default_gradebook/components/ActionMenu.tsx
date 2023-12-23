// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import GradebookExportManager from '../../shared/GradebookExportManager'
import PostGradesApp from '../../SISGradePassback/PostGradesApp'
import * as tz from '@canvas/datetime'
import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('gradebookActionMenu')

const {Item: MenuItem, Separator: MenuItemSeparator} = Menu as any

export type ActionMenuProps = {
  gradingPeriodId: string | null
  gradebookIsEditable: boolean
  contextAllowsGradebookUploads: boolean
  getAssignmentOrder: any
  getStudentOrder: any
  gradebookImportUrl: string
  showStudentFirstLastName: boolean
  lastExport?: {
    progressId: string
    workflowState: string
  }
  currentUserId: string
  gradebookExportUrl: string
  postGradesFeature: {
    enabled: boolean
    store: any
    returnFocusTo: any
    label: any
  }
  attachment?: {
    id: string
    downloadUrl: string | null
    updatedAt: string
    createdAt: string
  }
  postGradesLtis: {
    id: string
    name: string
    onSelect: any
  }[]
  publishGradesToSis: {
    isEnabled: boolean
    publishToSisUrl: string
  }
  updateExportState?: (name?: string, val?: number) => void
  setExportManager?: (val?: GradebookExportManager) => void
}

export type ActionMenuState = {
  exportInProgress: any
  previousExport: any
}

class ActionMenu extends React.Component<ActionMenuProps, ActionMenuState> {
  static defaultProps = {
    lastExport: undefined,
    attachment: undefined,
    postGradesLtis: [],
    publishGradesToSis: {
      publishToSisUrl: undefined,
    },
  }

  static gotoUrl(url) {
    window.location.href = url
  }

  exportManager?: GradebookExportManager

  constructor(props) {
    super(props)

    this.state = {
      exportInProgress: false,
      previousExport: null,
    }
    this.launchPostGrades = this.launchPostGrades.bind(this)
  }

  UNSAFE_componentWillMount() {
    const existingExport = this.getExistingExport()

    this.exportManager = new GradebookExportManager(
      this.props.gradebookExportUrl,
      this.props.currentUserId,
      existingExport,
      undefined,
      this.props.updateExportState
    )

    if (this.props.setExportManager) {
      this.props.setExportManager(this.exportManager)
    }

    const {lastExport} = this.props
    if (
      lastExport &&
      lastExport.workflowState !== 'completed' &&
      lastExport.workflowState !== 'failed'
    ) {
      this.handleResumeExport()
    }
  }

  componentWillUnmount() {
    if (this.exportManager) this.exportManager.clearMonitor()
  }

  getExistingExport() {
    if (!(this.props.lastExport && this.props.attachment)) return undefined
    if (!(this.props.lastExport.progressId && this.props.attachment.id)) return undefined

    return {
      progressId: this.props.lastExport.progressId,
      attachmentId: this.props.attachment.id,
      workflowState: this.props.lastExport.workflowState,
    }
  }

  setExportInProgress(status) {
    this.setState({exportInProgress: !!status})
  }

  handleExport(currentView) {
    this.setExportInProgress(true)
    $.flashMessage(I18n.t('Gradebook export has started. This may take a few minutes.'))

    return this.exportManager
      ?.startExport(
        this.props.gradingPeriodId,
        this.props.getAssignmentOrder,
        this.props.showStudentFirstLastName,
        this.props.getStudentOrder,
        currentView
      )
      .then(resolution => this.handleExportSuccess(resolution))
      .catch(error => this.handleExportError(error))
  }

  handleResumeExport() {
    new Promise((resolve, reject) => {
      this.exportManager?.monitorExport(resolve, reject)
    })
      .then(resolution => this.handleExportSuccess(resolution))
      .catch(error => this.handleExportError(error))
  }

  handleUpdateExportState(name?: string, value?: number) {
    setTimeout(() => {
      if (this.props.updateExportState) {
        this.props.updateExportState(name, value)
      }
    }, 3500)
  }

  handleExportSuccess(resolution) {
    this.setExportInProgress(false)

    if (!resolution) {
      return
    }

    const attachmentUrl = resolution.attachmentUrl
    const updatedAt = new Date(resolution.updatedAt)

    const previousExport = {
      label: `${I18n.t('New Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
      attachmentUrl,
    }

    this.setState({previousExport})

    // Since we're still on the page, let's automatically download the CSV for them as well
    ActionMenu.gotoUrl(attachmentUrl)

    this.handleUpdateExportState(undefined, undefined)

    $.flashMessage(I18n.t('Gradebook export has completed'))
  }

  handleExportError(error) {
    this.setExportInProgress(false)

    $.flashError(I18n.t('Gradebook Export Failed: %{error}', {error}))
  }

  handleImport() {
    ActionMenu.gotoUrl(this.props.gradebookImportUrl)
  }

  handlePublishGradesToSis() {
    ActionMenu.gotoUrl(this.props.publishGradesToSis.publishToSisUrl)
  }

  disableImports() {
    return !(this.props.gradebookIsEditable && this.props.contextAllowsGradebookUploads)
  }

  lastExportFromProps() {
    if (!(this.props.lastExport && this.props.lastExport.workflowState === 'completed'))
      return undefined

    return this.props.lastExport
  }

  lastExportFromState() {
    if (this.state.exportInProgress || !this.state.previousExport) return undefined

    return this.state.previousExport
  }

  previousExport() {
    const completedExportFromState = this.lastExportFromState()

    if (completedExportFromState) return completedExportFromState

    const completedLastExport = this.lastExportFromProps()
    const attachment = completedLastExport && this.props.attachment

    if (!completedLastExport || !attachment) return undefined

    const createdAt = tz.parse(attachment.createdAt)

    return {
      label: `${I18n.t('Previous Export')} (${DateHelper.formatDatetimeForDisplay(createdAt)})`,
      attachmentUrl: attachment.downloadUrl,
    }
  }

  exportInProgress() {
    return this.state.exportInProgress
  }

  launchPostGrades() {
    const {store, returnFocusTo} = this.props.postGradesFeature
    setTimeout(() => PostGradesApp.AppLaunch(store, returnFocusTo), 10)
  }

  renderPostGradesTools() {
    const tools = this.renderPostGradesLtis()

    if (this.props.postGradesFeature.enabled) {
      tools.push(this.renderPostGradesFeature())
    }

    if (tools.length) {
      tools.push(<MenuItemSeparator key="postGradesSeparator" />)
    }

    return tools
  }

  renderPostGradesLtis() {
    return this.props.postGradesLtis.map(tool => {
      const key = `post_grades_lti_${tool.id}`
      return (
        <MenuItem onSelect={tool.onSelect} key={key}>
          <span data-menu-id={key}>{I18n.t('Sync to %{name}', {name: tool.name})}</span>
        </MenuItem>
      )
    })
  }

  renderPostGradesFeature() {
    const sisName = this.props.postGradesFeature.label || I18n.t('SIS')
    return (
      <MenuItem onSelect={this.launchPostGrades} key="post_grades_feature_tool">
        <span data-menu-id="post_grades_feature_tool">
          {I18n.t('Sync to %{sisName}', {sisName})}
        </span>
      </MenuItem>
    )
  }

  renderPreviousExports() {
    const previousExport = this.previousExport()

    if (!previousExport) return ''

    const lastExportDescription = previousExport.label
    const downloadFrdUrl = previousExport.attachmentUrl

    const previousMenu = (
      <MenuItem
        key="previousExport"
        onSelect={() => {
          ActionMenu.gotoUrl(downloadFrdUrl)
        }}
      >
        <span data-menu-id="previous-export">{lastExportDescription}</span>
      </MenuItem>
    )

    return [<MenuItemSeparator key="previousExportSeparator" />, previousMenu]
  }

  renderPublishGradesToSis() {
    const {isEnabled, publishToSisUrl} = this.props.publishGradesToSis

    if (!isEnabled || !publishToSisUrl) {
      return null
    }

    return (
      <MenuItem
        onSelect={() => {
          this.handlePublishGradesToSis()
        }}
      >
        <span data-menu-id="publish-grades-to-sis">{I18n.t('Sync grades to SIS')}</span>
      </MenuItem>
    )
  }

  render() {
    const buttonTypographyProps: any = {
      weight: 'normal',
      style: 'normal',
      size: 'medium',
      color: 'primary',
    }
    const publishGradesToSis = this.renderPublishGradesToSis()

    return (
      <Menu
        trigger={
          <Link as="button">
            <Text {...buttonTypographyProps}>
              {I18n.t('Actions')}
              <IconMiniArrowDownSolid />
            </Text>
          </Link>
        }
      >
        {this.renderPostGradesTools()}
        {publishGradesToSis}

        <MenuItem
          disabled={this.disableImports()}
          onSelect={() => {
            this.handleImport()
          }}
        >
          <span data-menu-id="import">{I18n.t('Import')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.exportInProgress()}
          onSelect={() => {
            this.handleExport(true)
          }}
        >
          <span data-menu-id="export">
            {this.exportInProgress()
              ? I18n.t('Export in progress')
              : I18n.t('Export Current Gradebook View')}
          </span>
        </MenuItem>

        <MenuItem
          disabled={this.exportInProgress()}
          onSelect={() => {
            this.handleExport(false)
          }}
        >
          <span data-menu-id="export-all">
            {this.exportInProgress()
              ? I18n.t('Export in progress')
              : I18n.t('Export Entire Gradebook')}
          </span>
        </MenuItem>

        {[...this.renderPreviousExports()]}
      </Menu>
    )
  }
}

export default ActionMenu
