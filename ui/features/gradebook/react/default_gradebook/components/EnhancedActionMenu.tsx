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
  IconMiniArrowDownSolid,
  IconGradebookExportLine,
  IconGradebookImportLine,
  IconSisSyncedLine
} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import GradebookExportManager from '../../shared/GradebookExportManager'
import PostGradesApp from '../../SISGradePassback/PostGradesApp'
import tz from '@canvas/timezone'
import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('gradebookActionMenu')

const {arrayOf, bool, func, object, shape, string} = PropTypes

function gotoUrl(url) {
  window.location.href = url
}

export default function EnhancedActionMenu(props) {
  const [exportInProgress, setExportInProgress] = useState(false)
  const [previousExportState, setPreviousExportState] = useState(null)
  const exportManager = useRef(null)

  useEffect(() => {
    const existingExport = getExistingExport()
    exportManager.current = new GradebookExportManager(
      props.gradebookExportUrl,
      props.currentUserId,
      existingExport
    )
    return () => {
      if (exportManager) exportManager.current.clearMonitor()
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const getExistingExport = () => {
    if (!(props.lastExport && props.attachment)) return undefined
    if (!(props.lastExport.progressId && props.attachment.id)) return undefined

    return {
      progressId: props.lastExport.progressId,
      attachmentId: props.attachment.id,
      workflowState: props.lastExport.workflowState
    }
  }

  const handleExport = currentView => {
    setExportInProgress(true)
    $.flashMessage(I18n.t('Gradebook export started'))

    return exportManager.current
      .startExport(
        props.gradingPeriodId,
        props.getAssignmentOrder,
        props.showStudentFirstLastName,
        props.getStudentOrder,
        currentView
      )
      .then(resolution => {
        setExportInProgress(false)

        const attachmentUrl = resolution.attachmentUrl
        const updatedAt = new Date(resolution.updatedAt)

        const previousExportValue = {
          label: `${I18n.t('Previous Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
          attachmentUrl
        }

        setPreviousExportState(previousExportValue)

        // Since we're still on the page, let's automatically download the CSV for them as well
        gotoUrl(attachmentUrl)
      })
      .catch(reason => {
        setExportInProgress(false)

        $.flashError(I18n.t('Gradebook Export Failed: %{reason}', {reason}))
      })
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
      tools.push(<Menu.Separator key="postGradesSeparator" />)
    }

    return tools
  }

  const renderPostGradesLtis = () => {
    return props.postGradesLtis.map(tool => {
      const key = `post_grades_lti_${tool.id}`
      return (
        <Menu.Item onSelect={tool.onSelect} key={key}>
          <span data-menu-id={key}>{I18n.t('Sync to %{name}', {name: tool.name})}</span>
        </Menu.Item>
      )
    })
  }

  const renderPostGradesFeature = () => {
    const sisName = props.postGradesFeature.label || I18n.t('SIS')
    return (
      <Menu.Item onSelect={launchPostGrades} key="post_grades_feature_tool">
        <span data-menu-id="post_grades_feature_tool">
          {I18n.t('Sync to %{sisName}', {sisName})}
        </span>
      </Menu.Item>
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
      attachmentUrl: attachment.downloadUrl
    }
  }

  const renderPreviousExports = () => {
    const previousExport = getPreviousExport()

    if (!previousExport) return ''

    const lastExportDescription = previousExport.label
    const downloadFrdUrl = previousExport.attachmentUrl

    const previousMenu = (
      <Menu.Item
        key="previousExport"
        onSelect={() => {
          gotoUrl(downloadFrdUrl)
        }}
      >
        <span data-menu-id="previous-export">{lastExportDescription}</span>
      </Menu.Item>
    )

    return [<Menu.Separator key="previousExportSeparator" />, previousMenu]
  }

  const renderPublishGradesToSis = () => {
    const {isEnabled, publishToSisUrl} = props.publishGradesToSis

    if (!isEnabled || !publishToSisUrl) {
      return null
    }

    return (
      <Menu.Item
        onSelect={() => {
          handlePublishGradesToSis()
        }}
      >
        <span data-menu-id="publish-grades-to-sis">{I18n.t('Sync grades to SIS')}</span>
      </Menu.Item>
    )
  }

  const renderSyncDropdown = () => {
    const {isEnabled, publishToSisUrl} = props.publishGradesToSis
    const shouldRenderPublishGradesToSis = isEnabled && publishToSisUrl
    const shouldRenderPostGradesLti = props.postGradesLtis.length > 0
    const buttonTypographyProps = {
      weight: 'normal',
      style: 'normal',
      size: 'medium',
      color: 'primary'
    }
    if (shouldRenderPublishGradesToSis || shouldRenderPostGradesLti) {
      return (
        <Menu
          trigger={
            <Button color="secondary" margin="0 xx-small" renderIcon={IconSisSyncedLine}>
              <Text {...buttonTypographyProps}>
                {I18n.t('Sync')}
                <IconMiniArrowDownSolid />
              </Text>
            </Button>
          }
        >
          {renderPostGradesTools()}
          {renderPublishGradesToSis()}
        </Menu>
      )
    } else {
      return null
    }
  }

  const buttonTypographyProps = {
    weight: 'normal',
    style: 'normal',
    size: 'medium',
    color: 'primary'
  }

  return (
    <>
      {renderSyncDropdown()}

      <Button
        color="secondary"
        margin="0 xx-small"
        renderIcon={IconGradebookImportLine}
        interaction={disableImports() ? 'disabled' : null}
        onClick={handleImport}
      >
        <span data-menu-id="import">{I18n.t('Import')}</span>
      </Button>

      <Menu
        trigger={
          <Button color="secondary" margin="0 xx-small" renderIcon={IconGradebookExportLine}>
            <Text {...buttonTypographyProps}>
              <span data-menu-id="export-dropdown">{I18n.t('Export')}</span>
              <IconMiniArrowDownSolid />
            </Text>
          </Button>
        }
      >
        <Menu.Item
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
        </Menu.Item>

        <Menu.Item
          disabled={exportInProgress}
          onSelect={() => {
            handleExport(false)
          }}
        >
          <span data-menu-id="export-all">
            {exportInProgress ? I18n.t('Export in progress') : I18n.t('Export Entire Gradebook')}
          </span>
        </Menu.Item>

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
    workflowState: string.isRequired
  }),

  attachment: shape({
    id: string.isRequired,
    downloadUrl: string.isRequired,
    updatedAt: string.isRequired,
    createdAt: string.isRequired
  }),

  postGradesLtis: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
      onSelect: func.isRequired
    })
  ),

  postGradesFeature: shape({
    enabled: bool.isRequired,
    store: object.isRequired,
    returnFocusTo: object
  }).isRequired,

  publishGradesToSis: shape({
    isEnabled: bool.isRequired,
    publishToSisUrl: string
  }),

  gradingPeriodId: string.isRequired,
  showStudentFirstLastName: bool
}

EnhancedActionMenu.defaultProps = {
  lastExport: undefined,
  attachment: undefined,
  postGradesLtis: [],
  publishGradesToSis: {
    publishToSisUrl: undefined
  },
  showStudentFirstLastName: false
}
