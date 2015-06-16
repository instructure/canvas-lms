define [
  'react-router'
  'compiled/react_files/modules/filesEnv'
  'compiled/react_files/components/FilesApp'
  'compiled/react_files/components/ShowFolder'
  'compiled/react_files/components/SearchResults'
], (ReactRouter, filesEnv, FilesApp, ShowFolder, SearchResults) ->

  {Route, Redirect} = ReactRouter
  [
    Route path:filesEnv.baseUrl.replace(/\/files$/, ''), handler: FilesApp,
      Redirect from: "/files/?", to: "#{filesEnv.baseUrl}/folder/#{filesEnv.contexts[0].asset_string}"
      Route path: "#{filesEnv.baseUrl}/search", name: "search", handler: SearchResults
      Route path: "#{filesEnv.baseUrl}/folder/*", name: "folder", handler: ShowFolder
      Route path: "#{filesEnv.baseUrl}/?", name: "rootFolder", handler: ShowFolder
    Redirect from: "#{filesEnv.baseUrl}/folder", to: filesEnv.baseUrl
  ]
