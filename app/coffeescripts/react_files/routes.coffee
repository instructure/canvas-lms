define [
  'react'
  'react-router'
  'compiled/react_files/modules/filesEnv'
  'jsx/files/FilesApp'
  'jsx/files/ShowFolder'
  'jsx/files/SearchResults'
], (React, ReactRouter, filesEnv, FilesApp, ShowFolder, SearchResults) ->

  {Route, Redirect} = ReactRouter

  [
    React.createElement(Route, {
      path:filesEnv.baseUrl.replace(/\/files$/, ''),
      handler: FilesApp
    },
      React.createElement(Redirect, {
        from: "/files/?",
        to: "#{filesEnv.baseUrl}/folder/#{filesEnv.contexts[0].asset_string}"
      }),
      React.createElement(Route, {
        path: "#{filesEnv.baseUrl}/search",
        name: "search",
        handler: SearchResults
      }),
      React.createElement(Route, {
        path: "#{filesEnv.baseUrl}/folder/*",
        name: "folder",
        handler: ShowFolder
      }),
      React.createElement(Route, {
        path: "#{filesEnv.baseUrl}/?",
        name: "rootFolder",
        handler: ShowFolder
      })
    ),
    React.createElement(Redirect, {
      from: "#{filesEnv.baseUrl}/folder",
      to: filesEnv.baseUrl
    })
  ]
