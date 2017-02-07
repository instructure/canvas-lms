define([
  'react',
  'i18n!webzip_exports',
  'jsx/webzip_export/components/ExportList',
], (React, I18n, ExportList) => {
  class WebZipExportApp extends React.Component {

    constructor (props) {
      super(props)
      this.state = {exports: this.fakeData()}
    }

    fakeData () {
      return [
        {date: 'Nov 11, 2016 @ 3:33 PM', link: 'https://example.com'},
        {date: 'Nov 15, 2016 @ 7:07 PM', link: 'https://example.com'}
      ]
    }

    render () {
      return (
        <div>
          <h1>{I18n.t('Course Content Downloads')}</h1>
          <ExportList exports={this.state.exports} />
        </div>
      )
    }
  }

  return WebZipExportApp
})
