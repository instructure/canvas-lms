require [
  'jquery'
  'react'
  'react-dom'
  'jsx/epub_exports/App'
], ($, React, ReactDOM, EpubExportsApp) ->
  $('.course-epub-exports-app').each( (_i, element) ->
    component = React.createElement(EpubExportsApp)
    ReactDOM.render(component, element)
  )
