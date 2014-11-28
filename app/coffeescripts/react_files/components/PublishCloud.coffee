define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!broccoli_cloud'
  'compiled/models/FilesystemObject'
  './RestrictedDialogForm'
  '../modules/customPropTypes'
  'compiled/jquery.rails_flash_notifications'
], ($, React, withReactDOM, I18n, FilesystemObject, RestrictedDialogForm, customPropTypes) ->
  PublishCloud = React.createClass
    displayName: 'PublishCloud'

    propTypes:
      model: customPropTypes.filesystemObject
      userCanManageFilesForContext: React.PropTypes.bool.isRequired

    # == React Functions == #
    getInitialState: -> @extractStateFromModel( @props.model )

    componentWillMount: ->
      setState = (model) => @setState(@extractStateFromModel( model ))
      @props.model.on('change', setState, this)

    componentWillUnmount: ->
      @props.model.off(null, null, this)

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
        width: 400
        close: ->
          React.unmountComponentAtNode this
          $(this).remove()

      React.renderComponent(RestrictedDialogForm({
        models: [@props.model]
        closeDialog: -> $dialog.dialog('close')
      }), $dialog[0])

    # Function Summary
    # Opens the restricted dialog window

    handleClick: (event) ->
      event.preventDefault()
      @openRestrictedDialog()

    render: withReactDOM ->
      if @props.userCanManageFilesForContext
        if @state.published && @state.restricted
          button 
            'data-tooltip': 'left'
            onClick: @handleClick
            ref: "publishCloud"
            className:'btn-link published-status restricted'
            title: I18n.t('restricted_title', "Available from %{from_date} until %{until_date}",from_date: $.datetimeString(@props.model.get('unlock_at')), until_date: $.datetimeString(@props.model.get('lock_at')) )
            'aria-label': I18n.t('restricted_title', "Available from %{from_date} until %{until_date}",from_date: $.datetimeString(@props.model.get('unlock_at')), until_date: $.datetimeString(@props.model.get('lock_at')) ),
              i className:'icon-calendar-day'
        else if @state.published && @state.hidden
          button 
            'data-tooltip': 'left'
            onClick: @handleClick
            ref: "publishCloud"
            className:'btn-link published-status hiddenState'
            title: I18n.t('hidden_title', 'Hidden. Available with a link')
            'aria-label': I18n.t('label.hidden', 'Hidden. Available with a link'),
              i className:'icon-paperclip'
        else if @state.published
          button 
            'data-tooltip': 'left'
            onClick: @handleClick,
            ref: "publishCloud",
            className:'btn-link published-status published'
            title: I18n.t('published_title', 'Published')
            'aria-label': I18n.t('label.published', 'Published'),
              i className:'icon-publish'
        else
          button 
            'data-tooltip': 'left'
            onClick: @handleClick
            ref: "publishCloud"
            className:'btn-link published-status unpublished'
            title: I18n.t('unpublished_title', 'Unpublished')
            'aria-label': I18n.t('label.unpublished', 'Unpublished'),
              i className:'icon-unpublish'
      else
        if @state.published && @state.restricted
          div 
            'style': {'margin-right': '12px'}
            'data-tooltip': 'left'
            ref: "publishCloud"
            className:'published-status restricted'
            title: I18n.t('restricted_title', "Available from %{from_date} until %{until_date}",from_date: $.datetimeString(@props.model.get('unlock_at')), until_date: $.datetimeString(@props.model.get('lock_at')) )
            'aria-label': I18n.t('restricted_title', "Available from %{from_date} until %{until_date}",from_date: $.datetimeString(@props.model.get('unlock_at')), until_date: $.datetimeString(@props.model.get('lock_at')) ),
              i className:'icon-calendar-day'
        else
          div
            'style': {width: 28, height: 36}

