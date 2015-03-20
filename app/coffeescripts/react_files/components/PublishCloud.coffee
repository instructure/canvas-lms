define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'i18n!broccoli_cloud'
  'compiled/models/FilesystemObject'
  './RestrictedDialogForm'
  '../modules/customPropTypes'
  'compiled/jquery.rails_flash_notifications'
], ($, React, withReactElement, I18n, FilesystemObject, RestrictedDialogFormComponent, customPropTypes) ->

  RestrictedDialogForm = React.createFactory RestrictedDialogFormComponent

  PublishCloud = React.createClass
    displayName: 'PublishCloud'

    propTypes:
      togglePublishClassOn: React.PropTypes.object
      model: customPropTypes.filesystemObject
      userCanManageFilesForContext: React.PropTypes.bool.isRequired

    # == React Functions == #
    getInitialState: -> @extractStateFromModel( @props.model )

    componentDidMount: -> @updatePublishClassElements() if @props.togglePublishClassOn
    componentDidUpdate: -> @updatePublishClassElements() if @props.togglePublishClassOn

    componentWillMount: ->
      setState = (model) => @setState(@extractStateFromModel( model ))
      @props.model.on('change', setState, this)

    componentWillUnmount: ->
      @props.model.off(null, null, this)

    updatePublishClassElements: ->
      if @state.published
        @props.togglePublishClassOn.classList.add('ig-published')
      else
        @props.togglePublishClassOn.classList.remove('ig-published')

    getRestrictedText: ->
      if @props.model.get('unlock_at') and @props.model.get('lock_at')
        I18n.t("Available after %{unlock_at} until %{lock_at}", unlock_at: $.datetimeString(@props.model.get('unlock_at')), lock_at: $.datetimeString(@props.model.get('lock_at')))
      else if @props.model.get('unlock_at') and not @props.model.get('lock_at')
        I18n.t("Available after %{unlock_at}", unlock_at: $.datetimeString(@props.model.get('unlock_at')))
      else if not @props.model.get('unlock_at') and @props.model.get('lock_at')
        I18n.t("Available until %{lock_at}", lock_at: $.datetimeString(@props.model.get('lock_at')))

    # == Custom Functions == #

    # Function Summary
    # extractStateFromModel expects a backbone model wtih the follow attributes
    # * hidden, lock_at, unlock_at
    #
    # It takes those attributes and returns an object that can be used to set the
    # components internal state
    #
    # returns object

    extractStateFromModel: (model) ->
      published: !model.get('locked')
      restricted: !!model.get('lock_at') || !!model.get('unlock_at')
      hidden: !!model.get('hidden')

    # Function Summary
    # Toggling always sets restricted state to false because we only
    # allow publishing/unpublishing in this component.

    togglePublishedState: ->
      @setState published: !@state.published, restricted: false, hidden: false

    # Function Summary
    # Create a blank dialog window via jQuery, then dump the RestrictedDialogForm into that
    # dialog window. This allows us to do react things inside of this all ready rendered
    # jQueryUI widget

    openRestrictedDialog: ->
      $dialog = $('<div>').dialog
        title: I18n.t("title.permissions", "Editing permissions for: %{name}", {name: @props.model.displayName()})
        width: 800
        minHeight: 300
        close: ->
          React.unmountComponentAtNode this
          $(this).remove()

      React.render(RestrictedDialogForm({
        usageRightsRequiredForContext: @props.usageRightsRequiredForContext
        models: [@props.model]
        closeDialog: -> $dialog.dialog('close')
      }), $dialog[0])


    render: withReactElement ->
      if @props.userCanManageFilesForContext
        if @state.published && @state.restricted
          button
            type: 'button'
            'data-tooltip': 'left'
            onClick: @openRestrictedDialog
            ref: "publishCloud"
            className:'btn-link published-status restricted'
            title: @getRestrictedText()
            'aria-label': @getRestrictedText() + ' - ' + I18n.t('Click to modify'),
              i className:'icon-cloud-lock'
        else if @state.published && @state.hidden
          button
            type: 'button'
            'data-tooltip': 'left'
            onClick: @openRestrictedDialog
            ref: "publishCloud"
            className:'btn-link published-status hiddenState'
            title: I18n.t('hidden_title', 'Hidden. Available with a link')
            'aria-label': I18n.t('Hidden. Available with a link - Click to modify'),
              i className:'icon-cloud-lock'
        else if @state.published
          button
            type: 'button'
            'data-tooltip': 'left'
            onClick: @openRestrictedDialog,
            ref: "publishCloud",
            className:'btn-link published-status published'
            title: I18n.t('published_title', 'Published')
            'aria-label': I18n.t('Published - Click to modify'),
              i className:'icon-publish'
        else
          button
            type: 'button'
            'data-tooltip': 'left'
            onClick: @openRestrictedDialog
            ref: "publishCloud"
            className:'btn-link published-status unpublished'
            title: I18n.t('unpublished_title', 'Unpublished')
            'aria-label': I18n.t('Unpublished - Click to modify'),
              i className:'icon-unpublish'
      else
        if @state.published && @state.restricted
          div
            'style': {'margin-right': '12px'}
            'data-tooltip': 'left'
            ref: "publishCloud"
            className:'published-status restricted'
            title: @getRestrictedText()
            'aria-label': @getRestrictedText(),
              i className:'icon-calendar-day'
        else
          div
            'style': {width: 28, height: 36}

