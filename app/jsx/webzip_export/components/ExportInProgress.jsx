define([
  'react',
  'jsx/shared/ApiProgressBar',
  'i18n!webzip_exports',
], (React, ApiProgressBar, I18n) => {
  class ExportInProgress extends React.Component {
    static propTypes = {
      webzip: React.PropTypes.shape({
        progressId: React.PropTypes.string.isRequired
      }),
      loadExports: React.PropTypes.func.isRequired
    }

    constructor (props) {
      super(props)
      this.state = {completed: false}
      this.onComplete = this.onComplete.bind(this)
    }

    onComplete () {
      this.setState({completed: true})
      this.props.loadExports(this.props.webzip.progressId)
    }

    render () {
      if (!this.props.webzip || this.state.completed) {
        return null
      }

      return (
        <div className="webzipexport__inprogress">
          <span>{I18n.t('Processing')}</span>
          <p>{I18n.t('this may take a bit...')}</p>
          <ApiProgressBar
            progress_id={this.props.webzip.progressId}
            onComplete={this.onComplete}
            key={this.props.webzip.progressId}
          />
          <p>{I18n.t(`The download process has started. This
          can take awhile for large courses. You can leave the
          page and you'll get a notification when the download
          is complete.`)}</p>
        </div>
      )
    }
  }

  return ExportInProgress
})

