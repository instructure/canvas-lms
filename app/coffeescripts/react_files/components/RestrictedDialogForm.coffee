define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'i18n!restrict_student_access'
  'compiled/models/Folder'
  '../modules/customPropTypes'
  '../utils/setUsageRights'
  '../utils/updateModelsUsageRights'
  'jsx/files/DialogPreview'
  'jsx/files/UsageRightsSelectBox'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], ($, React, withReactElement, I18n, Folder, customPropTypes, setUsageRights, updateModelsUsageRights, DialogPreview, UsageRightsSelectBox) ->

  RestrictedDialogForm =

    # === React Functions === #
    displayName: 'RestrictedDialogForm'

    propTypes:
      closeDialog: React.PropTypes.func.isRequired,
      models: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
      usageRightsRequiredForContext: React.PropTypes.bool.isRequired

    getInitialState: ->
      submitable: false

    componentDidMount: ->
      @updateSubmitable()
      $('.ui-dialog-titlebar-close').focus()

    updateSubmitable: ->
      if @refs.restrictedSelection.state && @refs.restrictedSelection.state.selectedOption
        @setState({submitable: true})

    # === Custom Functions === #
    # Function Summary
    #
    # Event though you can technically set each of these fields independently, since we
    # are using them with a radio button we will grab all of the values and treat it as
    # a state based on the input fields.

    handleSubmit: (event) ->
      event.preventDefault()

      if (@props.usageRightsRequiredForContext && !@usageRightsOnAll() && !@allFolders())
        values = @refs.usageSelection.getValues()
        # They didn't choose a use justification
        if (values.use_justification == 'choose')
          $(@refs.usageSelection.refs.usageRightSelection.getDOMNode()).errorBox(I18n.t('You must specify a usage right.'))
          return false

        # We need to first set usage rights before handling the setting of
        # restricted access things.
        setUsageRights(@props.models, values, (success, data) =>
          if success
            updateModelsUsageRights(data, @props.models)
            @setRestrictedAccess()
          else
            $.flashError(I18n.t('There was an error setting usage rights.'))
        )

      else
        @setRestrictedAccess()

    setRestrictedAccess: ->
      attributes = @refs.restrictedSelection.extractFormValues()
      promises = @props.models.map (item) ->
        # Calling .save like this (passing data as the 'attrs' property on
        # the 'options' argument instead of as the first argument) is so that we just send
        # the 3 attributes we care about (hidden, lock_at, unlock_at) in the PUT
        # request (like you would for a PATCH request, execept our api doesn't support PATCH).
        # We do this so if some other user changes the name while we are looking at the page,
        # when we submit this form, we don't blow away their change and change the name back
        # to what it was. we just update the things we intended.
        item.save({}, {attrs: attributes})

      dfd = $.when(promises...)
      dfd.done => @props.closeDialog()
      $(@refs.dialogForm.getDOMNode()).disableWhileLoading dfd


    ###
    # Returns true if all the models passed in have usage rights
    ###
    usageRightsOnAll: ->
      @props.models.every (model) -> model.get('usage_rights')

    ###
    # Returns true if all the models passed in are folders.
    ###
    allFolders: ->
      @props.models.every (model) -> model instanceof Folder

    ###
    # Returns true if all the models passed in are folders.
    ###
    anyFolders: ->
      @props.models.filter((model) -> model instanceof Folder).length

    # callback function passed to RestrictedRadioButtons as props
    # for disabling/enabling of the Update Button
    radioStateChange: ->
      @setState({submitable: true})
