define [
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
], (React, ReactRouter, withReactDOM) ->
  Breadcrumbs = React.createClass

    propTypes:
      rootTillCurrentFolder: React.PropTypes.array.isRequired

    render: withReactDOM ->
      nav 'aria-label':'breadcrumbs', role:'navigation', className:'ef-breadcrumbs',
        @props.rootTillCurrentFolder.map (folder) =>
          ReactRouter.Link to: (if folder.urlPath() then 'folder' else 'rootFolder'), contextType: @props.contextType, contextId: @props.contextId, splat: folder.urlPath(), activeClassName: 'active',
            span className:'ellipsible', folder.get('name')
