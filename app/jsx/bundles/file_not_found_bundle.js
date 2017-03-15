require [
  'jquery'
  'react'
  'react-dom'
  'jsx/shared/FileNotFound'
], ($, React, ReactDOM, preventDefault, FileNotFound) ->

  FileNotFoundElement = React.createElement(FileNotFound, {
    contextCode: window.ENV.context_asset_string
  })

  ReactDOM.render(FileNotFoundElement, $('#sendMessageForm')[0])
