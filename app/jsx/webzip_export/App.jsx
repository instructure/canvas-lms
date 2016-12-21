define([
  'react',
  'axios',
  'instructure-ui/Spinner',
  'i18n!webzip_exports',
  'compiled/str/splitAssetString',
  'jsx/webzip_export/components/ExportList',
  'jsx/webzip_export/components/Errors',
], (React, axios, {default: Spinner}, I18n, splitAssetString, ExportList, Errors) => {
  class WebZipExportApp extends React.Component {

    static datesAndLinksFromAPI (webZipExports) {
      return webZipExports.filter(webZipExport =>
        webZipExport.workflow_state === 'generated' || webZipExport.workflow_state === 'failed'
      ).map((webZipExport) => {
        const url = webZipExport.zip_attachment ? webZipExport.zip_attachment.url : null
        return {date: webZipExport.created_at, link: url}
      }).reverse()
    }

    constructor (props) {
      super(props)
      this.state = {exports: [], errors: []}
    }

    componentDidMount () {
      const courseId = splitAssetString(ENV.context_asset_string)[1]
      this.loadExistingExports(courseId)
    }

    loadExistingExports (courseId) {
      axios.get(`/api/v1/courses/${courseId}/web_zip_exports`)
        .then((response) => {
          this.setState({
            exports: WebZipExportApp.datesAndLinksFromAPI(response.data),
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
      let app = null
      if (this.state.exports.length === 0 && this.state.errors.length === 0) {
        app = (<Spinner size="small" title={I18n.t('Loading')} />)
      } else if (this.state.exports.length === 0) {
        app = (<Errors errors={this.state.errors} />)
      } else {
        app = (<ExportList exports={this.state.exports} />)
      }
      return (
        <div>
          <h1>{I18n.t('Course Content Downloads')}</h1>
          {app}
        </div>
      )
    }
  }

  return WebZipExportApp
})
