import React from 'react'
import ReactDOM from 'react-dom'
import CollectionView from 'jsx/theme_editor/CollectionView'

ReactDOM.render(
  <CollectionView {...window.ENV.brandConfigStuff} />,
  document.getElementById('content')
)
