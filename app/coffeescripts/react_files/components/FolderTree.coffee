define [
  'react'
  'react-router'
  'compiled/views/FileBrowserView'
], (React, Router, FileBrowserView) ->

  FolderTree = React.createClass
    displayName: 'FolderTree'

    propTypes:
      rootFoldersToShow: React.PropTypes.array.isRequired
      rootTillCurrentFolder: React.PropTypes.array

    componentDidMount: ->
      new FileBrowserView({
        onlyShowFolders: true,
        rootFoldersToShow: @props.rootFoldersToShow
        onClick: @onClick
        href: @hrefFor
      }).render().$el.appendTo(@refs.FolderTreeHolder.getDOMNode())
      @expandTillCurrentFolder(@props)


    componentWillReceiveProps: (newProps) ->
      @expandTillCurrentFolder(newProps)


    onClick: (event, folder) ->
      event.preventDefault()
      Router.transitionTo (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()


    hrefFor: (folder) ->
      Router.makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()


    expandTillCurrentFolder: (props) ->
      expandFolder = (folderIndex) ->
        return unless folder = props.rootTillCurrentFolder?[folderIndex]
        folder.expand(false, {onlyShowFolders: true}).then ->
          expandFolder(folderIndex + 1)
      expandFolder(0)


    render: ->
      React.DOM.div( {className:"ef-folder-list", ref: 'FolderTreeHolder'})