require [
  'jquery'
  'react'
  'jsx/shared/FileNotFound'
], ($, React, preventDefault, FileNotFound) ->

  FileNotFoundElement = React.createElement(FileNotFound, {
    contextCode: window.ENV.context_asset_string
  });

  React.render(FileNotFoundElement, $('#sendMessageForm')[0])