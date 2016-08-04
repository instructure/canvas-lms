define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-dom'
  '../mixins/BackboneMixin'
  'compiled/models/Folder'
  'compiled/fn/preventDefault'
  '../modules/FocusStore'
  'classnames'
  'compiled/jquery.rails_flash_notifications'
], (_, I18n, React, ReactDOM, BackboneMixin, Folder, preventDefault, FocusStore, classnames) ->

  FolderChild =
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
                                    ReactDOM.findDOMNode(@refs.nameLink)
                                  else
                                    document.activeElement

      setTimeout () =>
        ReactDOM.findDOMNode(@refs.newName)?.focus()
      , 0

    focusNameLink: ->
      setTimeout () =>
        ReactDOM.findDOMNode(@refs.nameLink)?.focus()
      , 0

    saveNameEdit: ->
      @setState editing: false, @focusNameLink
      newName = ReactDOM.findDOMNode(@refs.newName).value
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

      classNameString = classnames({
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

      if @props.model instanceof Folder && !@props.model.get('for_submissions')
        toggleActive = (setActive) =>
          @setState({isActiveDragTarget: setActive}) if @state.isActiveDragTarget isnt setActive
        attrs.onDragEnter = attrs.onDragOver = (event) =>
          @props.dndOptions.onItemDragEnterOrOver(event, toggleActive(true))
        attrs.onDragLeave = attrs.onDragEnd = (event) =>
          @props.dndOptions.onItemDragLeaveOrEnd(event, toggleActive(false))
        attrs.onDrop = (event) =>
          @props.dndOptions.onItemDrop(event, @props.model, ({success, event}) =>
            toggleActive(false)
            ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@refs.FolderChild).parentNode) if success
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
      FocusStore.setItemToFocus ReactDOM.findDOMNode(@refs.nameLink)
      @props.previewItem()
