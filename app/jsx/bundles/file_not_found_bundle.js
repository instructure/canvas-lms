import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import FileNotFound from 'jsx/shared/FileNotFound'

ReactDOM.render(<FileNotFound contextCode={window.ENV.context_asset_string} />, $('#sendMessageForm')[0])
