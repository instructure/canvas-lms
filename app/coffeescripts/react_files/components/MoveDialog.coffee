define [
  'i18n!react_files'
  'jquery'
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
  '../modules/BBTreeBrowserView'
  'compiled/views/RootFoldersFinder'
  '../modules/customPropTypes'
  '../utils/moveStuff'
], (I18n, $, React, withReactDOM, preventDefault, BBTreeBrowserView, RootFoldersFinder, customPropTypes, moveStuff) ->

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

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      @setState(destinationFolder: folder)

    submit: ->
      promise = moveStuff(@props.thingsToMove, @state.destinationFolder)
      promise.then =>
        @props.closeDialog()
        BBTreeBrowserView.refresh()
      $(@refs.form.getDOMNode()).disableWhileLoading(promise)


    render: withReactDOM ->
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
          button {
            type: 'submit'
            disabled: !@state.destinationFolder
            className: 'btn btn-primary'
            'data-text-while-loading': I18n.t('moving', 'Moving...')
          }, I18n.t('move', 'Move')
