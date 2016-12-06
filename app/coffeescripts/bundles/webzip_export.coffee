require [
  'jquery'
  'react'
  'react-dom'
  'jsx/webzip_export/App'
], ($, React, ReactDOM, WebZipExportApp) ->
    component = React.createElement(WebZipExportApp)
    ReactDOM.render(component, $('#course-webzip-export-app')[0])
