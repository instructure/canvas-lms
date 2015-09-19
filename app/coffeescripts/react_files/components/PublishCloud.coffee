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

  PublishCloud =
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