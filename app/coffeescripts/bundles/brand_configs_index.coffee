require [
  'react'
  'react-dom'
  'jsx/theme_editor/CollectionView'
], (React, ReactDOM, CollectionView) ->

  el = React.createElement(CollectionView, window.ENV.brandConfigStuff)
  ReactDOM.render(el, document.getElementById('content'))
