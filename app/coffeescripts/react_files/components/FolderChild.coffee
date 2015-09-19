define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-router'
  '../mixins/BackboneMixin'
  'compiled/react/shared/utils/withReactElement'
  'jsx/files/FriendlyDatetime'
  './ItemCog'
  'jsx/files/FilesystemObjectThumbnail'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/fn/preventDefault'
  'jsx/shared/PublishCloud'
  './UsageRightsIndicator'
  '../modules/FocusStore'
  'compiled/jquery.rails_flash_notifications'
], (_, I18n, React, ReactRouter, BackboneMixin, withReactElement, FriendlyDatetimeComponent, ItemCogComponent, FilesystemObjectThumbnail, friendlyBytes, Folder, preventDefault, PublishCloud, UsageRightsIndicatorComponent, FocusStore) ->

  FriendlyDatetime = React.createFactory FriendlyDatetimeComponent
  ItemCog = React.createFactory ItemCogComponent
  UsageRightsIndicator = React.createFactory  UsageRightsIndicatorComponent
  Link = React.createFactory ReactRouter.Link
  classSet = React.addons.classSet

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

      # If the activeElement is currently the "body" that means they clicked on some type of cog to enable this state.
      # This is an edge case that ensures focus remains in context of whats being edited, in this case, the nameLink
      @previouslyFocusedElement = if document.activeElement.nodeName == "BODY"
                                    @refs.nameLink?.getDOMNode()
                                  else
                                    document.activeElement

      setTimeout () =>
        @refs.newName?.getDOMNode().focus()
      , 0

    focusNameLink: ->
      setTimeout () =>
        @refs.nameLink?.getDOMNode().focus()
      , 0

    saveNameEdit: ->
      @setState editing: false, @focusNameLink
      newName = @refs.newName.getDOMNode().value
      @props.model.save(name: newName, {
        success: =>
          @focusNameLink()
        error: (model, response) =>
          $.flashError(I18n.t("A file named %{itemName} already exists in this folder.", itemName: newName)) if response.status == 409
        }
      )

    cancelEditingName: ->
      @props.model.collection.remove(@props.model) if @props.model.isNew()
      @setState editing: false, @focusPreviousElement

    getAttributesForRootNode: ->

      classNameString = classSet({
        'ef-item-row': true
        'ef-item-selected': @props.isSelected
        'activeDragTarget': @state.isActiveDragTarget
      })

      attrs =
        onClick: @props.toggleSelected
        className: classNameString
        role: 'row'
        'aria-selected': @props.isSelected
        draggable: !@state.editing
        ref: 'FolderChild'
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
          @props.dndOptions.onItemDrop(event, @props.model, ({success, event}) =>
            toggleActive(false)
            React.unmountComponentAtNode(@refs.FolderChild.parentNode) if success
          )
      attrs

    checkForAccess: (event) ->
      if @props.model.get('locked_for_user')
        event.preventDefault()
        message = I18n.t('This folder is currently locked and unavailable to view.')
        $.flashError message
        $.screenReaderFlashMessage message
        return false

    handleFileLinkClick: ->
      FocusStore.setItemToFocus @refs.nameLink.getDOMNode()
      @props.previewItem()


    render: withReactElement ->
      selectCheckboxLabel = I18n.t('Select %{itemName}', itemName: @props.model.displayName())

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
            'aria-label': selectCheckboxLabel
            onFocus: => @setState({hideKeyboardCheck: false})
            onBlur: => @setState({hideKeyboardCheck: true})
            className: keyboardCheckboxClass
            checked: @props.isSelected
            onChange: -> #noop, will be caught by 'click' on root node
          }
          span {className: keyboardLabelClass},
            selectCheckboxLabel

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
              onClick: preventDefault(@handleFileLinkClick)
              className: 'media'
              ref: 'nameLink'
            },
              span className: 'pull-left',
                FilesystemObjectThumbnail(model: @props.model)
              span className: 'media-body',
                @props.model.displayName()


        div className:'ef-date-created-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('created_at')

        div className:'ef-date-modified-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('modified_at')

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
              modalOptions: @props.modalOptions
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
              modalOptions: @props.modalOptions
              clearSelectedItems: @props.clearSelectedItems
            })
