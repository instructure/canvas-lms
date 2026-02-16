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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import splitAssetString from '@canvas/util/splitAssetString'
import {assignLocation} from '@canvas/util/globalUtils'
import ExportList from './components/ExportList'
import ExportInProgress from './components/ExportInProgress'
import Errors from './components/Errors'

const I18n = createI18nScope('webzip_exports')

interface WebZipExport {
  created_at: string
  zip_attachment?: {
    url: string
  }
  workflow_state: string
  progress_id: string
}

interface FormattedExport {
  date: string
  link: string
  workflowState: string
  progressId: string
  newExport: boolean
}

interface WebZipExportAppState {
  exports: FormattedExport[]
  errors: Error[]
  loaded: boolean
}

class WebZipExportApp extends React.Component<Record<string, never>, WebZipExportAppState> {
  private finishedStates: string[]

  static webZipFormat(
    webZipExports: WebZipExport[],
    newExportId: string | null = null,
  ): FormattedExport[] {
    return webZipExports
      .map(webZipExport => {
        const url = webZipExport.zip_attachment ? webZipExport.zip_attachment.url : ''
        const isNewExport = newExportId === webZipExport.progress_id
        return {
          date: webZipExport.created_at,
          link: url || '',
          workflowState: webZipExport.workflow_state,
          progressId: webZipExport.progress_id,
          newExport: isNewExport,
        }
      })
      .reverse()
  }

  constructor(props: Record<string, never>) {
    super(props)
    this.finishedStates = ['generated', 'failed']
    this.state = {exports: [], errors: [], loaded: false}
  }

  componentDidMount(): void {
    this.getExports()
  }

  componentDidUpdate(): void {
    const newExport = this.findNewExport()
    if (newExport && newExport.link) {
      this.downloadLink(newExport.link)
    }
  }

  getExports = (newExportId: string | null = null): void => {
    // @ts-expect-error - ENV global not typed
    const courseId = splitAssetString(ENV.context_asset_string)[1]
    this.loadExistingExports(courseId, newExportId)
  }

  getExportsInProgress(): FormattedExport | undefined {
    return this.state.exports.find(ex => !this.finishedStates.includes(ex.workflowState))
  }

  getFinishedExports(): FormattedExport[] {
    return this.state.exports.filter(ex => this.finishedStates.includes(ex.workflowState))
  }

  findNewExport(): FormattedExport | undefined {
    return this.state.exports.find(ex => ex.newExport)
  }

  loadExistingExports(courseId: string, newExportId: string | null = null): void {
    doFetchApi({path: `/api/v1/courses/${courseId}/web_zip_exports`})
      .then(({json}) => {
        this.setState({
          loaded: true,
          exports: WebZipExportApp.webZipFormat(json as WebZipExport[], newExportId),
          errors: [],
        })
      })
      .catch((error: Error) => {
        this.setState({
          exports: [],
          errors: [error],
          loaded: true,
        })
      })
  }

  downloadLink(link: string): void {
    assignLocation(link)
  }

  render(): React.JSX.Element {
    let app = null
    const webzipInProgress = this.getExportsInProgress()
    const finishedExports = this.getFinishedExports()
    if (!this.state.loaded) {
      app = <Spinner size="small" renderTitle={I18n.t('Loading')} />
    } else if (this.state.errors.length > 0) {
      app = <Errors errors={this.state.errors} />
    } else if (finishedExports.length > 0 || !webzipInProgress) {
      app = <ExportList exports={finishedExports} />
    }
    return (
      <div>
        <h1>{I18n.t('Exported Package History')}</h1>
        {app}
        <p>
          <strong>
            {I18n.t(`You may not reproduce or communicate any of the content on
            this course, including files exported from this course without the prior written
            permission of your institution.  Check with your institution for specific online
            user agreement guidelines.`)}
          </strong>
        </p>
        <hr />
        <ExportInProgress webzip={webzipInProgress} loadExports={this.getExports} />
      </div>
    )
  }
}

export default WebZipExportApp
