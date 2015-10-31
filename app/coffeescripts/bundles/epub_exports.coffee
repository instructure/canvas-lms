require [
  'jquery'
  'react'
  'jsx/epub_exports/App'
], ($, React, EpubExportsApp) ->
  $('.course-epub-exports-app').each( (_i, element) ->
    component = React.createElement(EpubExportsApp)
    React.render(component, element)
  )
