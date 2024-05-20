// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, {useRef, useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {
  IconGradebookExportLine,
  IconGradebookImportLine,
  IconSisSyncedLine,
  IconArrowOpenDownLine,
  IconArrowOpenUpLine,
  IconKeyboardShortcutsLine,
} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import GradebookExportManager from '../../shared/GradebookExportManager'
import PostGradesApp from '../../SISGradePassback/PostGradesApp'
import * as tz from '@canvas/datetime'
import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('gradebookActionMenu')

const {Item: MenuItem, Separator: MenuSeparator} = Menu as any

const {arrayOf, bool, func, object, shape, string} = PropTypes

function gotoUrl(url: string) {
  window.location.href = url
}

type Lti = {id: string; name: string; onSelect: () => void}

export type EnhancedActionMenuProps = {
  attachment: any
  contextAllowsGradebookUploads: boolean
  currentUserId: string
  getAssignmentOrder: () => string[]
  getStudentOrder: () => string[]
  gradebookExportUrl: string
  gradebookImportUrl: string
  gradebookIsEditable: boolean
  gradingPeriodId: string
  lastExport: any
  postGradesFeature: {
    enabled: boolean
    returnFocusTo: HTMLElement
    label: string
    store: any
  }
  postGradesLtis: Lti[]
  publishGradesToSis: {
    isEnabled: boolean
    publishToSisUrl: string
  }
  showStudentFirstLastName: boolean
  updateExportState: (name?: string, val?: number) => void
  setExportManager: (val?: GradebookExportManager) => void
}

export default function EnhancedActionMenu(props: EnhancedActionMenuProps) {
  const [exportInProgress, setExportInProgress] = useState(false)
  const [previousExportState, setPreviousExportState] = useState<null | {
    label: string
    attachmentUrl: string
  }>(null)
  const exportManager = useRef<GradebookExportManager | null>(null)
  const [toggleExportMenu, setToggleExportMenu] = useState(false)
  const [toggleSyncMenu, setToggleSyncMenu] = useState(false)
  const [openKeyboardShortcut, setOpenKeyboardShortcut] = useState(null)

  useEffect(() => {
    const questionMarkKeyDown = new KeyboardEvent('keydown', {keyCode: 191, shiftKey: true})
    setOpenKeyboardShortcut(questionMarkKeyDown)

    const existingExport = getExistingExport()
    exportManager.current = new GradebookExportManager(
      props.gradebookExportUrl,
      props.currentUserId,
      existingExport,
      undefined,
      props.updateExportState
    )
    if (props.setExportManager) {
      props.setExportManager(exportManager.current)
    }

    const {lastExport} = props
    if (
      lastExport &&
      lastExport.workflowState !== 'completed' &&
      lastExport.workflowState !== 'failed'
    ) {
      handleResumeExport()
    }
    return () => {
      if (exportManager.current) exportManager.current.clearMonitor()
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const getExistingExport = () => {
    if (!(props.lastExport && props.attachment)) return undefined
    if (!(props.lastExport.progressId && props.attachment.id)) return undefined

    return {
      progressId: props.lastExport.progressId,
      attachmentId: props.attachment.id,
      workflowState: props.lastExport.workflowState,
    }
  }

  const handleKeyboardShortcuts = () => {
    document.dispatchEvent(openKeyboardShortcut)
  }

  const handleExport = async currentView => {
    setExportInProgress(true)
    $.flashMessage(I18n.t('Gradebook export has started. This may take a few minutes.'))

    if (!exportManager.current) {
      throw new Error('exportManager not loaded')
    }

    try {
      const resolution = await exportManager.current.startExport(
        props.gradingPeriodId,
        props.getAssignmentOrder,
        props.showStudentFirstLastName,
        props.getStudentOrder,
        currentView
      )
      return handleExportSuccess(resolution)
    } catch (reason) {
      return handleExportError(reason)
    }
  }

  const handleResumeExport = () => {
    new Promise((resolve, reject) => {
      exportManager.current?.monitorExport(resolve, reject)
    })
      .then(resolution => handleExportSuccess(resolution))
      .catch(error => handleExportError(error))
  }

  const handleExportSuccess = resolution => {
    setExportInProgress(false)

    if (!resolution) {
      return
    }

    const attachmentUrl = resolution.attachmentUrl
    const updatedAt = new Date(resolution.updatedAt)

    const previousExportValue = {
      label: `${I18n.t('Previous Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
      attachmentUrl,
    }

    setPreviousExportState(previousExportValue)

    // Since we're still on the page, let's automatically download the CSV for them as well
    gotoUrl(attachmentUrl)

    handleUpdateExportState(undefined, undefined)
    $.flashMessage(I18n.t('Gradebook export has completed'))
  }

  const handleExportError = error => {
    setExportInProgress(false)

    $.flashError(I18n.t('Gradebook Export Failed: %{error}', {error}))
  }

  const handleUpdateExportState = (name?: string, value?: number) => {
    setTimeout(() => {
      if (props.updateExportState) {
        props.updateExportState(name, value)
      }
    }, 3500)
  }

  const handleImport = () => {
    gotoUrl(props.gradebookImportUrl)
  }

  const handlePublishGradesToSis = () => {
    gotoUrl(props.publishGradesToSis.publishToSisUrl)
  }

  const disableImports = () => {
    return !(props.gradebookIsEditable && props.contextAllowsGradebookUploads)
  }

  const lastExportFromProps = () => {
    if (!(props.lastExport && props.lastExport.workflowState === 'completed')) return undefined

    return props.lastExport
  }

  const lastExportFromState = () => {
    if (exportInProgress || !previousExportState) return undefined

    return previousExportState
  }

  const launchPostGrades = () => {
    const {store, returnFocusTo} = props.postGradesFeature
    setTimeout(() => PostGradesApp.AppLaunch(store, returnFocusTo), 10)
  }

  const renderPostGradesTools = () => {
    const tools = renderPostGradesLtis()

    if (props.postGradesFeature.enabled) {
      tools.push(renderPostGradesFeature())
    }

    if (tools.length) {
      tools.push(<MenuSeparator key="postGradesSeparator" />)
    }

    return tools
  }

  const renderPostGradesLtis = () => {
    return props.postGradesLtis.map((tool: Lti) => {
      const key = `post_grades_lti_${tool.id}`
      return (
        <MenuItem onSelect={tool.onSelect} key={key}>
          <span data-menu-id={key}>{I18n.t('Sync to %{name}', {name: tool.name})}</span>
        </MenuItem>
      )
    })
  }

  const renderPostGradesFeature = () => {
    const sisName = props.postGradesFeature.label || I18n.t('SIS')
    return (
      <MenuItem onSelect={launchPostGrades} key="post_grades_feature_tool">
        <span data-menu-id="post_grades_feature_tool">
          {I18n.t('Sync to %{sisName}', {sisName})}
        </span>
      </MenuItem>
    )
  }

  const getPreviousExport = () => {
    const completedExportFromState = lastExportFromState()

    if (completedExportFromState) return completedExportFromState

    const completedLastExport = lastExportFromProps()
    const attachment = completedLastExport && props.attachment

    if (!completedLastExport || !attachment) return undefined

    const createdAt = tz.parse(attachment.createdAt)

    return {
      label: `${I18n.t('Previous Export')} (${DateHelper.formatDatetimeForDisplay(createdAt)})`,
      attachmentUrl: attachment.downloadUrl,
    }
  }

  const renderPreviousExports = () => {
    const previousExport = getPreviousExport()

    if (!previousExport) return ''

    const lastExportDescription = previousExport.label
    const downloadFrdUrl = previousExport.attachmentUrl

    const previousMenu = (
      <MenuItem
        key="previousExport"
        onSelect={() => {
          gotoUrl(downloadFrdUrl)
        }}
      >
        <span data-menu-id="previous-export">{lastExportDescription}</span>
      </MenuItem>
    )

    return [<MenuSeparator key="previousExportSeparator" />, previousMenu]
  }

  const renderPublishGradesToSis = () => {
    const {isEnabled, publishToSisUrl} = props.publishGradesToSis

    if (!isEnabled || !publishToSisUrl) {
      return null
    }

    return (
      <MenuItem
        onSelect={() => {
          handlePublishGradesToSis()
        }}
      >
        <span data-menu-id="publish-grades-to-sis">{I18n.t('Sync grades to SIS')}</span>
      </MenuItem>
    )
  }

  const handleRenderArrowIconSyncMenu = () => {
    setToggleSyncMenu(!toggleSyncMenu)
  }

  const renderSyncDropdown = () => {
    const {isEnabled, publishToSisUrl} = props.publishGradesToSis
    const shouldRenderPublishGradesToSis = isEnabled && publishToSisUrl
    const shouldRenderPostGradesLti = props.postGradesLtis.length > 0
    if (shouldRenderPublishGradesToSis || shouldRenderPostGradesLti) {
      return (
        <Menu
          trigger={
            <Button color="secondary" margin="0 small 0 0" renderIcon={IconSisSyncedLine}>
              <View margin="0 x-small 0 0">
                <Text weight="normal" fontStyle="normal" size="medium" color="primary">
                  {I18n.t('Sync')}
                </Text>
              </View>
              {toggleSyncMenu ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
            </Button>
          }
          onToggle={handleRenderArrowIconSyncMenu}
        >
          {renderPostGradesTools()}
          {renderPublishGradesToSis()}
        </Menu>
      )
    } else {
      return null
    }
  }

  const handleRenderArrowIconExportMenu = () => {
    setToggleExportMenu(!toggleExportMenu)
  }

  return (
    <>
      {/* EVAL-3711 Remove Evaluate ICE feature flag */}
      {window.ENV.FEATURES.instui_nav && !ENV.disable_keyboard_shortcuts && (
        <Button
          data-testid="keyboard-shortcuts"
          margin="0 small 0 0"
          onClick={handleKeyboardShortcuts}
          renderIcon={IconKeyboardShortcutsLine}
        />
      )}
      {renderSyncDropdown()}
      <Button
        color="secondary"
        margin="0 small 0 0"
        renderIcon={IconGradebookImportLine}
        interaction={disableImports() ? 'disabled' : undefined}
        onClick={handleImport}
      >
        <span data-menu-id="import">{I18n.t('Import')}</span>
      </Button>

      <Menu
        trigger={
          <Button color="secondary" margin="0 small 0 0" renderIcon={IconGradebookExportLine}>
            <View margin="0 x-small 0 0" data-menu-id="export-dropdown" as="span">
              <Text weight="normal" fontStyle="normal" size="medium" color="primary">
                {I18n.t('Export')}
              </Text>
            </View>
            {toggleExportMenu ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
          </Button>
        }
        onToggle={handleRenderArrowIconExportMenu}
      >
        <MenuItem
          disabled={exportInProgress}
          onSelect={() => {
            handleExport(true)
          }}
        >
          <span data-menu-id="export">
            {exportInProgress
              ? I18n.t('Export in progress')
              : I18n.t('Export Current Gradebook View')}
          </span>
        </MenuItem>

        <MenuItem
          disabled={exportInProgress}
          onSelect={() => {
            handleExport(false)
          }}
        >
          <span data-menu-id="export-all">
            {exportInProgress ? I18n.t('Export in progress') : I18n.t('Export Entire Gradebook')}
          </span>
        </MenuItem>

        {[...renderPreviousExports()]}
      </Menu>
    </>
  )
}

EnhancedActionMenu.propTypes = {
  gradebookIsEditable: bool.isRequired,
  contextAllowsGradebookUploads: bool.isRequired,
  getAssignmentOrder: func.isRequired,
  getStudentOrder: func.isRequired,
  gradebookImportUrl: string.isRequired,

  currentUserId: string.isRequired,
  gradebookExportUrl: string.isRequired,

  lastExport: shape({
    progressId: string.isRequired,
    workflowState: string.isRequired,
  }),

  attachment: shape({
    id: string.isRequired,
    downloadUrl: string.isRequired,
    updatedAt: string.isRequired,
    createdAt: string.isRequired,
  }),

  postGradesLtis: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
      onSelect: func.isRequired,
    })
  ),

  postGradesFeature: shape({
    enabled: bool.isRequired,
    store: object.isRequired,
    returnFocusTo: object,
  }).isRequired,

  publishGradesToSis: shape({
    isEnabled: bool.isRequired,
    publishToSisUrl: string,
  }),

  gradingPeriodId: string.isRequired,
  showStudentFirstLastName: bool,
  updateExportState: PropTypes.func,
  setExportManager: PropTypes.func,
}

EnhancedActionMenu.defaultProps = {
  lastExport: undefined,
  attachment: undefined,
  postGradesLtis: [],
  publishGradesToSis: {
    publishToSisUrl: undefined,
  },
  showStudentFirstLastName: false,
}
