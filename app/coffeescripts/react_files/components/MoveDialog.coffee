define [
  'i18n!react_files'
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'compiled/models/FilesystemObject'
  'compiled/views/FileBrowserView'
], (I18n, $, React, withReactDOM, preventDefault, Folder,FilesystemObject, FileBrowserView) ->

  MoveDialog = React.createClass
    displayName: 'MoveDialog'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(React.PropTypes.instanceOf(Folder)).isRequired
      thingsToMove: React.PropTypes.arrayOf(React.PropTypes.instanceOf(FilesystemObject)).isRequired
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

      new FileBrowserView({
        onlyShowFolders: true,
        rootFoldersToShow: @props.rootFoldersToShow
        onClick: @onSelectFolder
      }).render().$el.appendTo(@refs.FolderTreeHolder.getDOMNode()).find(':tabbable:first').focus();

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      @setState(destinationFolder: folder)

    submit: ->
      promises = @props.thingsToMove.map (thing) => thing.moveTo(@state.destinationFolder)
      $(@refs.form.getDOMNode()).disableWhileLoading $.when(promises...).then =>
        @props.closeDialog()
        $.flashMessage(I18n.t('move_success', {
          one: "%{item} moved to %{destinationFolder}",
          other: "%{count} items moved to %{destinationFolder}"
        }, {
          count: @props.thingsToMove.length
          item: @props.thingsToMove[0]?.displayName()
          destinationFolder: @state.destinationFolder.displayName()
        }))


    render: withReactDOM ->
      form { ref: 'form', className: 'form-dialog', onSubmit: preventDefault(@submit)},
        div {className: 'form-dialog-content'},
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
