require [
  'react'
  'jsx/theme_editor/CollectionView'
], (React, CollectionView) ->

  el = React.createElement(CollectionView, window.ENV.brandConfigStuff)
  React.render(el, document.getElementById('content'))