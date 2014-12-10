define [
  'react'
  'react-router'
  'compiled/views/TreeBrowserView'
  'compiled/views/RootFoldersFinder'
  '../modules/customPropTypes'
], (React, Router, TreeBrowserView, RootFoldersFinder, customPropTypes) ->

  FolderTree = React.createClass
    displayName: 'FolderTree'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
      rootTillCurrentFolder: React.PropTypes.arrayOf(customPropTypes.folder)

    mixins: [Router.Navigation, Router.ActiveState]

    componentDidMount: ->
      rootFoldersFinder = new RootFoldersFinder({
        rootFoldersToShow: @props.rootFoldersToShow
      })
      new TreeBrowserView({
        onlyShowFolders: true,
        rootModelsFinder: rootFoldersFinder
        onClick: @onClick
        dndOptions: @props.dndOptions
        href: @hrefFor
        focusStyleClass: @focusStyleClass
        selectedStyleClass: @selectedStyleClass
      }).render().$el.appendTo(@refs.FolderTreeHolder.getDOMNode())
      @expandTillCurrentFolder(@props)


    componentWillReceiveProps: (newProps) ->
      @expandTillCurrentFolder(newProps)


    onClick: (event, folder) ->
      event.preventDefault()
      $(@refs.FolderTreeHolder.getDOMNode()).find('.' + @focusStyleClass).each( (key, value) => $(value).removeClass(@focusStyleClass))
      $(@refs.FolderTreeHolder.getDOMNode()).find('.' + @selectedStyleClass).each( (key, value) => $(value).removeClass(@selectedStyleClass))
      @transitionTo (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()


    hrefFor: (folder) ->
      @makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()



    focusStyleClass: 'FolderTree__folderItem--focused'
    selectedStyleClass: 'FolderTree__folderItem--selected'


    expandTillCurrentFolder: (props) ->
      expandFolder = (folderIndex) ->
        return unless folder = props.rootTillCurrentFolder?[folderIndex]
        folder.expand(false, {onlyShowFolders: true}).then ->
          expandFolder(folderIndex + 1)
      expandFolder(0)


    render: ->
      React.DOM.div( {className:"ef-folder-list", ref: 'FolderTreeHolder'})