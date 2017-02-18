define([
  'react',
  'axios',
  'instructure-ui/Spinner',
  'i18n!webzip_exports',
  'compiled/str/splitAssetString',
  'jsx/webzip_export/components/ExportList',
  'jsx/webzip_export/components/ExportInProgress',
  'jsx/webzip_export/components/Errors',
], (React, axios, {default: Spinner}, I18n, splitAssetString, ExportList, ExportInProgress, Errors) => {
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

    getViewableExports () {
      return this.state.exports.filter(ex =>
        ex.workflowState === 'generated' || ex.newExport
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
      const viewableExports = this.getViewableExports()
      if (!this.state.loaded) {
        app = <Spinner size="small" title={I18n.t('Loading')} />
      } else if (this.state.errors.length > 0) {
        app = <Errors errors={this.state.errors} />
      } else if (viewableExports.length > 0 || !webzipInProgress) {
        app = <ExportList exports={viewableExports} />
      }
      return (
        <div>
          <h1>{I18n.t('Exported Package History')}</h1>
          {app}
          <ExportInProgress webzip={webzipInProgress} loadExports={this.getExports} />
        </div>
      )
    }
  }

  return WebZipExportApp
})
