import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import EpubExportsApp from 'jsx/epub_exports/App'

$('.course-epub-exports-app').each((_i, element) => {
  ReactDOM.render(<EpubExportsApp />, element)
})

