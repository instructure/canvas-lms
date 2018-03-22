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
import I18n from 'i18n!outcomes'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'
import { showFlashAlert } from '../shared/FlashAlert'
import * as apiClient from './apiClient'

export function showOutcomesImporterIfInProgress (props, userId) {
  return apiClient.queryImportStatus(props.contextUrlRoot, 'latest').
    then((response) => {
      if (response.status === 200 && response.data.workflow_state === 'importing') {
        const importId = response.data.id
        const invokedImport = userId === response.data.user.id
        ReactDOM.render(<OutcomesImporter {...props} importId={importId} invokedImport={invokedImport} />, props.mount)
      }
    }).
    catch(() => {
    })
}

export function showOutcomesImporter (props) {
  ReactDOM.render(<OutcomesImporter {...props} invokedImport/>, props.mount)
}

export default class OutcomesImporter extends Component {
  static propTypes = {
    mount: PropTypes.instanceOf(Element).isRequired,
    disableOutcomeViews: PropTypes.func.isRequired,
    resetOutcomeViews: PropTypes.func.isRequired,
    file: PropTypes.instanceOf(File),
    importId: PropTypes.string,
    contextUrlRoot: PropTypes.string.isRequired,
    invokedImport: PropTypes.bool.isRequired
  }

  static defaultProps = {
    file: null,
    importId: null
  }

  componentDidMount () {
    this.beginUpload()
  }

  pollImportStatus (importId) {
    const pollStatus = setInterval(() => {
      apiClient.queryImportStatus(this.props.contextUrlRoot, importId).
        then((response) => {
          const workflowState = response.data.workflow_state
          if (workflowState === 'succeeded' || workflowState === 'failed') {
            this.completeUpload(response.data.processing_errors.length)
            clearInterval(pollStatus)
          }
        })
    }, 1000)
  }

  beginUpload () {
    const {disableOutcomeViews, contextUrlRoot, file, importId} = this.props
    disableOutcomeViews()
    if (file !== null) {
      apiClient.createImport(contextUrlRoot, file).
        then((resp) => this.pollImportStatus(resp.data.id)).
        catch(() => {
          showFlashAlert({type: 'error', message: I18n.t('There was an error uploading your file. Please try again.')})
        })
    } else if (importId !== null) {
      this.pollImportStatus(importId)
    }
  }

  completeUpload (count) {
    const {mount, resetOutcomeViews, invokedImport} = this.props
    if (mount) ReactDOM.unmountComponentAtNode(mount)
    resetOutcomeViews()
    if (!invokedImport) {
      return
    }
    if (count > 0) {
      const wereErrors = I18n.t({one: "was an error", other: "were errors"}, {count})
      showFlashAlert({ type: 'error', message: I18n.t('There %{wereErrors} with your import, please examine your file and attempt the upload again. Check your email for more details.', {wereErrors}) })
    } else {
      showFlashAlert({ type: 'success', message: I18n.t('Your outcomes were successfully imported.') })
    }
  }

  render () {
    const {invokedImport} = this.props
    const styles = {
      'textAlign': 'center',
      'marginTop': '3rem'
    }
    return (
      <div style={styles}>
        <Spinner
          title = {I18n.t('importing outcomes')}
          size = 'large'
        />
        <Heading level='h4'>
          {invokedImport && I18n.t("Please wait as we upload and process your file.")}
          {!invokedImport && I18n.t("An outcome import is currently in progress.")}
        </Heading>
        <Text fontStyle='italic'>
          {invokedImport && I18n.t("It's ok to leave this page, we'll email you when the import is done.")}
        </Text>
      </div>
    )
  }
}