define [
  'i18n!react_files'
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'compiled/fn/preventDefault'
  '../modules/BBTreeBrowserView'
  'compiled/views/RootFoldersFinder'
  '../modules/customPropTypes'
  '../utils/moveStuff'
], (I18n, $, React, withReactElement, preventDefault, BBTreeBrowserView, RootFoldersFinder, customPropTypes, moveStuff) ->

  MoveDialog = React.createClass
    displayName: 'MoveDialog'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
      thingsToMove: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
      closeDialog: React.PropTypes.func.isRequired

    getInitialState: ->
      destinationFolder: null

    componentDidMount: ->
      @props.setTitle I18n.t('move_question', {
        one: "Where would you like to move %{item}?",
        other: "Where would you like to move these %{count} items?"
      },{
        count: @props.thingsToMove.length
        item: @props.thingsToMove[0]?.displayName()
      })

      rootFoldersFinder = new RootFoldersFinder({
        rootFoldersToShow: @props.rootFoldersToShow
      })

      @treeBrowserViewId = BBTreeBrowserView.create({
          onlyShowSubtrees: true,
          rootModelsFinder: rootFoldersFinder
          rootFoldersToShow: @props.rootFoldersToShow
          onClick: @onSelectFolder
          focusStyleClass: 'MoveDialog__folderItem--focused'
          selectedStyleClass: 'MoveDialog__folderItem--selected'
        },
        {
          element: @refs.FolderTreeHolder.getDOMNode()
        }).index

      BBTreeBrowserView.getView(@treeBrowserViewId).render().$el.appendTo(@refs.FolderTreeHolder.getDOMNode()).find(':tabbable:first').focus()

    componentWillUnmount: ->
      BBTreeBrowserView.remove(@treeBrowserViewId)

    contextsAreEqual: (destination = {}, sources = []) ->
      differentContexts = sources.filter (source) ->
        source.collection.parentFolder.get("context_type") is destination.get("context_type") and
        source.collection.parentFolder.get("context_id")?.toString() is destination.get("context_id")?.toString()

      !!differentContexts.length

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      @setState(destinationFolder: folder, isCopyingFile: !@contextsAreEqual(folder, @props.thingsToMove))

    submit: ->
      promise = moveStuff(@props.thingsToMove, @state.destinationFolder)
      promise.then =>
        @props.closeDialog()
        BBTreeBrowserView.refresh()
      $(@refs.form.getDOMNode()).disableWhileLoading(promise)


    render: withReactElement ->
      form { ref: 'form', className: 'form-dialog', onSubmit: preventDefault(@submit)},
        div {className: 'form-dialog-content'},
          aside {
            role: 'region'
            'aria-label' : I18n.t('folder_browsing_tree', 'Folder Browsing Tree')
          },
            div ref: 'FolderTreeHolder'
        div {className: 'form-controls'},
          button {
            type: 'button'
            className: 'btn'
            onClick: @props.closeDialog
          }, I18n.t('cancel', 'Cancel')
          if @state.isCopyingFile
            button {
              type: 'submit'
              disabled: !@state.destinationFolder
              className: 'btn btn-primary'
              'data-text-while-loading': I18n.t('Copying...')
            }, I18n.t('Copy to Folder')
          else
            button {
              type: 'submit'
              disabled: !@state.destinationFolder
              className: 'btn btn-primary'
              'data-text-while-loading': I18n.t('Moving...')
            }, I18n.t('Move')
