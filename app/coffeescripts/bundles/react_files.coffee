require [
  'react'
  'react-router'
  'compiled/react_files/components/FilesApp'
  'compiled/react_files/components/ShowFolder'
  'compiled/react_files/components/SearchResults'
], (React, {Routes, Route, Redirect}, FilesApp, ShowFolder, SearchResults) ->

  baseUrl = if location.pathname is '/files'
    '/files'
  else
    '/:contextType/:contextId/files'

  routes =
    Routes location: 'history',
      Route path:'/:contextType/:contextId', handler: FilesApp,
        Route path: "#{baseUrl}/search", name: 'search', handler: SearchResults
        Route path: "#{baseUrl}/folder/*", name: 'folder', handler: ShowFolder
        Route path: baseUrl, name: 'rootFolder', handler: ShowFolder
      Redirect from: "#{baseUrl}/folder", to: "#{baseUrl}"

  React.renderComponent(routes, document.getElementById('content'))
