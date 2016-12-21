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

    static webZipFormat (webZipExports) {
      return webZipExports.map((webZipExport) => {
        const url = webZipExport.zip_attachment ? webZipExport.zip_attachment.url : null
        return {
          date: webZipExport.created_at,
          link: url,
          workflowState: webZipExport.workflow_state,
          progressId: webZipExport.progress_id
        }
      }).reverse()
    }

    constructor (props) {
      super(props)
      this.finishedStates = ['generated', 'failed']
      this.state = {exports: [], errors: []}
      this.getExports = this.getExports.bind(this)
    }

    componentDidMount () {
      this.getExports()
    }

    getExports () {
      const courseId = splitAssetString(ENV.context_asset_string)[1]
      this.loadExistingExports(courseId)
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

    loadExistingExports (courseId) {
      axios.get(`/api/v1/courses/${courseId}/web_zip_exports`)
        .then((response) => {
          this.setState({
            exports: WebZipExportApp.webZipFormat(response.data),
            errors: [],
          })
        })
        .catch((response) => {
          this.setState({
            exports: [],
            errors: [response],
          })
        })
    }

    render () {
      const webzipInProgress = this.getExportsInProgress()
      let app = null
      if (this.state.exports.length === 0 && this.state.errors.length === 0) {
        app = (<Spinner size="small" title={I18n.t('Loading')} />)
      } else if (this.state.exports.length === 0) {
        app = (<Errors errors={this.state.errors} />)
      } else {
        const finishedExports = this.getFinishedExports()
        app = (<ExportList exports={finishedExports} />)
      }
      return (
        <div>
          <h1>{I18n.t('Course Content Downloads')}</h1>
          {app}
          <ExportInProgress webzip={webzipInProgress} loadExports={this.getExports} />
        </div>
      )
    }
  }

  return WebZipExportApp
})
