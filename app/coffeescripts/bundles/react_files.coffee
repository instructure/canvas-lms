require [
  'react'
  'react-router'
  'compiled/react_files/components/FilesApp'
  'compiled/react_files/components/ShowFolder'
  'compiled/react_files/components/SearchResults'
  'compiled/react_files/components/RedirectToRoot'
], (React, {Routes, Route}, FilesApp, ShowFolder, SearchResults, redirectToRoot) ->

  baseUrl = if location.pathname is '/files'
    '/files'
  else
    '/:contextType/:contextId/files'

  routes =
    Routes location: 'history',
      Route path:'/:contextType/:contextId', handler: FilesApp,
        Route path: "#{baseUrl}/search", name: 'search', handler: SearchResults
        Route path: "#{baseUrl}/folder/*", name: 'folder', handler: ShowFolder
        # FIXME: If I don't put this below the previous line it will ALWAYS redirect.
        # but if I put it below it NEVER redirects
        Route path: "#{baseUrl}/folder", handler: redirectToRoot
        Route path: baseUrl, name: 'rootFolder', handler: ShowFolder

  React.renderComponent(routes, document.getElementById('content'))
