define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!broccoli_cloud'
  'compiled/models/FilesystemObject'
  'compiled/jquery.rails_flash_notifications'
], ($, React, withReactDOM, I18n, FilesystemObject) ->
  PublishCloud = React.createClass
    displayName: 'PublishCloud'
    propTypes:
      model: React.PropTypes.instanceOf(FilesystemObject)

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
    # When hidden is true, the FilesystemObject is unpublished.
    # When we publish, we blow away other restricted access dates.
    # We also revert to the previous state if a successful save can't
    # be had.

    handleClick: (event) ->
      event.preventDefault()

      @togglePublishedState()

      dataToSave = locked: @state.published, hidden: false, lock_at: null, unlock_at: null
      dfd = @props.model.save({}, {attrs: dataToSave})

      dfd.fail =>
        if @state.published
          $.flashError I18n.t('publish_error', 'An error occurred while trying to publish %{name}. Changes have been reverted!', {name: @props.model.displayName()})
        else
          $.flashError I18n.t('unpublish_error', 'An error occurred while trying to unpublish %{name} . Changes have been reverted!', {name: @props.model.displayName()})

        @setState @getInitialState()

    render: withReactDOM ->
      if @state.published && @state.restricted
        button 
          'data-tooltip':'{"tooltipClass":"popover popover-padded", "position":"left"}'
          onClick: @handleClick
          ref: "publishCloud"
          className:'btn-link published-status restricted'
          title: I18n.t('restricted_title', 'Restricted. Click to unpublish')
          'aria-label': I18n.t('label.restricted', 'Restricted. Click to unpublish.'),
            i className:'icon-calendar-day'
      else if @state.published && @state.hidden
        button 
          'data-tooltip':'{"tooltipClass":"popover popover-padded", "position":"left"}'
          onClick: @handleClick
          ref: "publishCloud"
          className:'btn-link published-status hiddenState'
          title: I18n.t('hidden_title', 'Hidden. Click to unpublish')
          'aria-label': I18n.t('label.hidden', 'Hidden. Click to unpublish.'),
            i className:'icon-paperclip'
      else if @state.published
        button 
          'data-tooltip':'{"tooltipClass":"popover popover-padded", "position":"left"}'
          onClick: @handleClick,
          ref: "publishCloud",
          className:'btn-link published-status published'
          title: I18n.t('published_title', 'Published. Click to unpublish')
          'aria-label': I18n.t('label.published', 'Published. Click to unpublish.'),
            i className:'icon-publish'
      else
        button 
          'data-tooltip':'{"tooltipClass":"popover popover-padded", "position":"left"}'
          onClick: @handleClick
          ref: "publishCloud"
          className:'btn-link published-status unpublished'
          title: I18n.t('unpublished_title', 'Unpublished. Click to publish')
          'aria-label': I18n.t('label.unpublished', 'Unpublished. Click to publish.'),
            i className:'icon-unpublish'
