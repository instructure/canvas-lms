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
import axios from 'axios'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import I18n from 'i18n!webzip_exports'
import splitAssetString from 'compiled/str/splitAssetString'
import ExportList from '../webzip_export/components/ExportList'
import ExportInProgress from '../webzip_export/components/ExportInProgress'
import Errors from '../webzip_export/components/Errors'
  class WebZipExportApp extends React.Component {

    static webZipFormat (webZipExports, newExportId = null) {
      return webZipExports.map((webZipExport) => {
        const url = webZipExport.zip_attachment ? webZipExport.zip_attachment.url : null
        const isNewExport = (newExportId === webZipExport.progress_id)
        return {
          date: webZipExport.created_at,
          link: url,
          workflowState: webZipExport.workflow_state,
          progressId: webZipExport.progress_id,
          newExport: isNewExport
        }
      }).reverse()
    }

    constructor (props) {
      super(props)
      this.finishedStates = ['generated', 'failed']
      this.state = {exports: [], errors: [], loaded: false}
      this.getExports = this.getExports.bind(this)
    }

    componentDidMount () {
      this.getExports()
    }

    componentDidUpdate () {
      const newExport = this.findNewExport()
      if (newExport && newExport.link) {
        this.downloadLink(newExport.link)
      }
    }

    getExports (newExportId = null) {
      const courseId = splitAssetString(ENV.context_asset_string)[1]
      this.loadExistingExports(courseId, newExportId)
    }

    getExportsInProgress () {
      return this.state.exports.find(ex =>
        !this.finishedStates.includes(ex.workflowState)
      )
    }

    getFinishedExports () {
      return this.state.exports.filter(ex =>
        this.finishedStates.includes(ex.workflowState)
      )
    }

    findNewExport () {
      return this.state.exports.find(ex =>
        ex.newExport
      )
    }

    loadExistingExports (courseId, newExportId = null) {
      axios.get(`/api/v1/courses/${courseId}/web_zip_exports`)
        .then((response) => {
          this.setState({
            loaded: true,
            exports: WebZipExportApp.webZipFormat(response.data, newExportId),
            errors: []
          })
        })
        .catch((response) => {
          this.setState({
            exports: [],
            errors: [response],
            loaded: true
          })
        })
    }

    downloadLink (link) {
      window.location = link
    }

    render () {
      let app = null
      const webzipInProgress = this.getExportsInProgress()
      const finishedExports = this.getFinishedExports()
      if (!this.state.loaded) {
        app = <Spinner size="small" title={I18n.t('Loading')} />
      } else if (this.state.errors.length > 0) {
        app = <Errors errors={this.state.errors} />
      } else if (finishedExports.length > 0 || !webzipInProgress) {
        app = <ExportList exports={finishedExports} />
      }
      return (
        <div>
          <h1>{I18n.t('Exported Package History')}</h1>
          {app}
          <p><strong>{I18n.t(`You may not reproduce or communicate any of the content on
            this course, including files exported from this course without the prior written
            permission of your institution.  Check with your institution for specific online
            user agreement guidelines.`)}</strong></p>
          <hr />
          <ExportInProgress webzip={webzipInProgress} loadExports={this.getExports} />
        </div>
      )
    }
  }

export default WebZipExportApp
