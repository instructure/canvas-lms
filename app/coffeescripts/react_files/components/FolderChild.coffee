define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-router'
  '../mixins/BackboneMixin'
  'compiled/react/shared/utils/withReactDOM'
  './FriendlyDatetime'
  './ItemCog'
  './FilesystemObjectThumbnail'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/fn/preventDefault'
  './PublishCloud'
  './UsageRightsIndicator'
  'compiled/jquery.rails_flash_notifications'
], (_, I18n, React, {Link}, BackboneMixin, withReactDOM, FriendlyDatetime, ItemCog, FilesystemObjectThumbnail, friendlyBytes, Folder, preventDefault, PublishCloud, UsageRightsIndicator) ->

  classSet = React.addons.classSet;

  FolderChild = React.createClass
    displayName: 'FolderChild'

    mixins: [BackboneMixin('model')]

    getInitialState: ->
      editing: @props.model.isNew()
      hideKeyboardCheck: true
      isSelected: @props.isSelected

    componentDidMount: ->
      @focusNameInput() if @state.editing

    startEditingName: ->
      @setState editing: true, @focusNameInput

    focusPreviousElement: ->
      @previouslyFocusedElement?.focus()
      return if document.activeElement ==  @previouslyFocusedElement
      @focusNameLink()

    focusNameInput: ->
      @previouslyFocusedElement = document.activeElement
      setTimeout () =>
        @refs.newName?.getDOMNode().focus()
      , 0

    focusNameLink: ->
      setTimeout () =>
        @refs.nameLink?.getDOMNode().focus()
      , 0

    saveNameEdit: ->
      @setState editing: false, @focusNameLink
      @props.model.save(name: @refs.newName.getDOMNode().value, {success: =>
          @focusNameLink()
      })

    cancelEditingName: ->
      @props.model.collection.remove(@props.model) if @props.model.isNew()
      @setState editing: false, @focusPreviousElement

    getAttributesForRootNode: ->
      attrs =
        onClick: @props.toggleSelected
        className: "ef-item-row
                   #{'ef-item-selected' if @props.isSelected}
                   #{'activeDragTarget' if @state.isActiveDragTarget}"
        role: 'row'
        'aria-selected': @props.isSelected
        draggable: !@state.editing
        onDragStart: =>
          @props.toggleSelected() unless @props.isSelected
          @props.dndOptions.onItemDragStart arguments...

      if @props.model instanceof Folder
        toggleActive = (setActive) =>
          @setState({isActiveDragTarget: setActive}) if @state.isActiveDragTarget isnt setActive
        attrs.onDragEnter = attrs.onDragOver = (event) =>
          @props.dndOptions.onItemDragEnterOrOver(event, toggleActive(true))
        attrs.onDragLeave = attrs.onDragEnd = (event) =>
          @props.dndOptions.onItemDragLeaveOrEnd(event, toggleActive(false))
        attrs.onDrop = (event) =>
          @props.dndOptions.onItemDrop(event, @props.model, toggleActive(false))
      attrs

    checkForAccess: (event) ->
      if @props.model.get('locked_for_user')
        event.preventDefault()
        message = I18n.t('This folder is currently locked and unavailable to view.')
        $.flashError message
        $.screenReaderFlashMessage message
        return false

    render: withReactDOM ->

      keyboardCheckboxClass = classSet({
        'screenreader-only': @state.hideKeyboardCheck
        'multiselectable-toggler': true
      })

      keyboardLabelClass = classSet({
        'screenreader-only': !@state.hideKeyboardCheck
      })

      div @getAttributesForRootNode(),
        label className: keyboardCheckboxClass, role: 'gridcell',
          input {
            type: 'checkbox'
            onFocus: => @setState({hideKeyboardCheck: false})
            onBlur: => @setState({hideKeyboardCheck: true})
            className: keyboardCheckboxClass
            checked: @props.isSelected
            onChange: -> #noop, will be caught by 'click' on root node
          }
          span {className: keyboardLabelClass},
            I18n.t('labels.select', 'Select This Item')

        div className:'ef-name-col ellipsis', role: 'rowheader',
          if @state.editing
            form className: 'ef-edit-name-form', onSubmit: preventDefault(@saveNameEdit),
              input({
                type:'text'
                ref:'newName'
                className: 'input-block-level'
                placeholder: I18n.t('name', 'Name')
                'aria-label': I18n.t('folder_name', 'Folder Name')
                defaultValue: @props.model.displayName()
                onKeyUp: (event) => @cancelEditingName() if event.keyCode is 27
              }),
              button {
                type: 'button'
                className: 'btn btn-link ef-edit-name-cancel'
                'aria-label': I18n.t('cancel', 'Cancel')
                onClick: @cancelEditingName
              },
                i className: 'icon-x'
          else if @props.model instanceof Folder
            Link {
              ref: 'nameLink'
              to: 'folder'
              className: 'media'
              onClick: @checkForAccess
              params: {splat: @props.model.urlPath()}
            },
              span className: 'pull-left',
                FilesystemObjectThumbnail(model: @props.model)
              span className: 'media-body',
                @props.model.displayName()
          else
            a {
              href: @props.model.get('url')
              onClick: preventDefault(@props.previewItem)
              className: 'media'
              ref: 'nameLink'
            },
              span className: 'pull-left',
                FilesystemObjectThumbnail(model: @props.model)
              span className: 'media-body',
                @props.model.displayName()

        div className: 'screenreader-only', role: 'gridcell',
          if @props.model instanceof Folder
            I18n.t('folder', 'Folder')
          else
            @props.model.get('content-type')


        div className:'ef-date-created-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('created_at')

        div className:'ef-date-modified-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('updated_at')

        div className:'ef-modified-by-col ellipsis', role: 'gridcell',
          a href: @props.model.get('user')?.html_url, className: 'ef-plain-link',
            @props.model.get('user')?.display_name

        div className:'ef-size-col', role: 'gridcell',
          friendlyBytes(@props.model.get('size'))

        if @props.usageRightsRequiredForContext
          div className: 'ef-usage-rights-col', role: 'gridcell',
            UsageRightsIndicator({
              model: @props.model
              userCanManageFilesForContext: @props.userCanManageFilesForContext
              usageRightsRequiredForContext: @props.usageRightsRequiredForContext
            })

        div className: 'ef-links-col', role: 'gridcell',
          unless @props.model.isNew()
            PublishCloud({
              model: @props.model,
              ref: 'publishButton',
              userCanManageFilesForContext: @props.userCanManageFilesForContext,
              usageRightsRequiredForContext: @props.usageRightsRequiredForContext
            })

          unless @props.model.isNew() or @props.model.get('locked_for_user')
            ItemCog({
              model: @props.model
              startEditingName: @startEditingName
              userCanManageFilesForContext: @props.userCanManageFilesForContext
              usageRightsRequiredForContext: @props.usageRightsRequiredForContext
              externalToolsForContext: @props.externalToolsForContext
            })
