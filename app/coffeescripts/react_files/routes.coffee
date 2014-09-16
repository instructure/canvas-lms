define [
  'react-router'
  'compiled/react_files/modules/filesEnv'
  'compiled/react_files/components/FilesApp'
  'compiled/react_files/components/ShowFolder'
  'compiled/react_files/components/SearchResults'
], ({Routes, Route, Redirect}, filesEnv, FilesApp, ShowFolder, SearchResults) ->

  routes = [
    # TODO: do I need this next line? why?
    Route path:filesEnv.baseUrl.replace(/\/files$/, ''), handler: FilesApp,
      Route path: "#{filesEnv.baseUrl}/search", name: 'search', handler: SearchResults
      Route path: "#{filesEnv.baseUrl}/folder/*", name: 'folder', handler: ShowFolder
      Route path: "#{filesEnv.baseUrl}", name: 'rootFolder', handler: ShowFolder
    Redirect from: "#{filesEnv.baseUrl}/folder", to: filesEnv.baseUrl
  ]
  if filesEnv.showingAllContexts
    routes.push Redirect from: "#{filesEnv.baseUrl}/folder/#{filesEnv.contexts[0].asset_string}", to: filesEnv.baseUrl

  Routes location: 'history', routes




