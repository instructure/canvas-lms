/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import * as apiClient from './apiClient'

const I18n = useI18nScope('OutcomesImporter')

const unmount = mount => () => ReactDOM.unmountComponentAtNode(mount)
export function showOutcomesImporterIfInProgress({mount, ...props}, userId) {
  return apiClient
    .queryImportStatus(props.contextUrlRoot, 'latest')
    .then(response => {
      if (response.status === 200 && response.data.workflow_state === 'importing') {
        const importId = response.data.id
        const invokedImport = userId === response.data.user.id
        ReactDOM.render(
          <OutcomesImporter
            {...props}
            hide={unmount(mount)}
            importId={importId}
            invokedImport={invokedImport}
          />,
          mount
        )
      }
    })
    .catch(() => {})
}

export function showOutcomesImporter({mount, ...props}) {
  ReactDOM.render(<OutcomesImporter {...props} hide={unmount(mount)} invokedImport={true} />, mount)
}

export default class OutcomesImporter extends Component {
  static propTypes = {
    hide: PropTypes.func.isRequired,
    disableOutcomeViews: PropTypes.func.isRequired,
    resetOutcomeViews: PropTypes.func.isRequired,
    learningOutcomeGroupId: PropTypes.string,
    learningOutcomeGroupAncestorIds: PropTypes.array,
    file: PropTypes.instanceOf(File),
    importId: PropTypes.string,
    contextUrlRoot: PropTypes.string.isRequired,
    invokedImport: PropTypes.bool.isRequired,
    onSuccessfulOutcomesImport: PropTypes.func,
  }

  static defaultProps = {
    file: null,
    importId: null,
    learningOutcomeGroupAncestorIds: [],
    onSuccessfulOutcomesImport: () => {},
  }

  componentDidMount() {
    this.beginUpload()
  }

  componentWillUnmount() {
    clearInterval(this.pollStatus)
  }

  pollImportStatus(importId) {
    this.pollStatus = setInterval(() => {
      // eslint-disable-next-line promise/catch-or-return
      apiClient.queryImportStatus(this.props.contextUrlRoot, importId).then(response => {
        const workflowState = response.data.workflow_state
        if (workflowState === 'succeeded' || workflowState === 'failed') {
          this.completeUpload(
            importId,
            response.data.processing_errors.length,
            workflowState === 'succeeded'
          )
          clearInterval(this.pollStatus)
        }
      })
    }, 1000)
  }

  beginUpload() {
    const {
      disableOutcomeViews,
      resetOutcomeViews,
      contextUrlRoot,
      learningOutcomeGroupId,
      file,
      importId,
    } = this.props
    disableOutcomeViews()
    if (file !== null) {
      apiClient
        .createImport(contextUrlRoot, file, learningOutcomeGroupId)
        .then(resp => this.pollImportStatus(resp.data.id))
        .catch(() => {
          showFlashAlert({
            type: 'error',
            message: I18n.t('There was an error uploading your file. Please try again.'),
          })
          resetOutcomeViews()
        })
    } else if (importId !== null) {
      this.pollImportStatus(importId)
    }
  }

  completeUpload(importId, count, succeeded) {
    const {hide, resetOutcomeViews, invokedImport} = this.props
    if (hide) hide()
    resetOutcomeViews()
    if (!invokedImport) {
      return
    }
    if (!succeeded) {
      showFlashAlert({
        type: 'error',
        message: I18n.t(
          'There was an error with your import, please examine your file and attempt the upload again. Check your email for more details.'
        ),
      })
    } else {
      apiClient
        .queryImportCreatedGroupIds(this.props.contextUrlRoot, importId)
        .then(response => {
          if (count > 0) this.completedWithErrors(response.data)
          else this.successfulUpload(response.data)
        })
        .catch(err => {
          throw err
        })
    }
  }

  getImportedGroups(createdGroupIds) {
    this.props.onSuccessfulOutcomesImport({
      selectedGroupAncestorIds: [...this.props.learningOutcomeGroupAncestorIds, ...createdGroupIds],
    })
  }

  successfulUpload(createdGroupIds) {
    this.getImportedGroups(createdGroupIds)
    showFlashAlert({
      type: 'success',
      message: I18n.t('Your outcomes were successfully imported.'),
    })
  }

  completedWithErrors(createdGroupIds) {
    this.getImportedGroups(createdGroupIds)
    showFlashAlert({
      type: 'warning',
      message: I18n.t(
        'There was a problem importing some of the outcomes in the uploaded file. Check your email for more details.'
      ),
    })
  }

  render() {
    const {invokedImport} = this.props
    const styles = {
      textAlign: 'center',
      marginTop: '3rem',
    }
    return (
      <div style={styles}>
        <Spinner renderTitle={I18n.t('importing outcomes')} size="large" />
        <Heading level="h4">
          {invokedImport && I18n.t('Please wait as we upload and process your file.')}
          {!invokedImport && I18n.t('An outcome import is currently in progress.')}
        </Heading>
        <Text fontStyle="italic">
          {invokedImport &&
            I18n.t("It's ok to leave this page, we'll email you when the import is done.")}
        </Text>
      </div>
    )
  }
}
