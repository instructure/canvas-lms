define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!restrict_student_access'
  'compiled/models/Folder'
  '../modules/customPropTypes'
  '../utils/setUsageRights'
  '../utils/updateModelsUsageRights'
  './DialogPreview'
  './UsageRightsSelectBox'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], ($, React, withReactDOM, I18n, Folder, customPropTypes, setUsageRights, updateModelsUsageRights, DialogPreview, UsageRightsSelectBox) ->

  RestrictedDialogForm = React.createClass

    # === React Functions === #
    displayName: 'RestrictedDialogForm'

    propTypes:
      closeDialog: React.PropTypes.func.isRequired,
      models: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
      usageRightsRequiredForContext: React.PropTypes.bool.isRequired

    getInitialState: ->
      permissionAttributes = ['hidden', 'locked', 'lock_at', 'unlock_at']
      initialState = {}

      allAreEqual = @props.models.every (model) =>
        permissionAttributes.every (attribute) =>
          @props.models[0].get(attribute) is model.get(attribute) || ( !@props.models[0].get(attribute) && !model.get(attribute) )

      if allAreEqual
        initialState = @props.models[0].pick(permissionAttributes)
        initialState.selectedOption = if initialState.locked
          'unpublished'
        else if initialState.hidden
          'link_only'
        else if initialState.lock_at || initialState.unlock_at
          'date_range'
        else
          'published'

      initialState

    componentDidMount: ->
      $([@refs.unlock_at.getDOMNode(), @refs.lock_at.getDOMNode()]).datetime_field()
      $('.ui-dialog-titlebar-close').focus()

    # === Custom Functions === #

    # Function Summary
    #
    # Extracts data from the form and converts it into an object.
    #
    # Refactoring Notes:
    #   This function should be refactored so no refs are used. This could
    #   be accomplished by storing form values to send in state and binding
    #   from the inputs themselves when things change.
    #
    # Returns an object representing data the api expects.

    extractFormValues: ->
      hidden   : @state.selectedOption is 'link_only'
      unlock_at: @state.selectedOption is 'date_range' && $(@refs.unlock_at.getDOMNode()).data('unfudged-date') or ''
      lock_at  : @state.selectedOption is 'date_range' && $(@refs.lock_at.getDOMNode()).data('unfudged-date') or ''
      locked: @state.selectedOption is 'unpublished'

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
      attributes = @extractFormValues()
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

    renderUsageRightsWarning: ->
      div {className: 'RestrictedDialogForm__banner col-xs-12'},
        span {className: 'alert'},
          i {className: 'icon-warning RestrictedDialogForm__warning'}
          I18n.t('Before publishing, you must set usage rights on your files.')

    ###
    # Renders out the restricted access form
    # - options is an object which can be used to conditionally set certain aspects
    #   of rendering.
    #
    # Future Refactor: Move this to another component should it's use elsewhere
    #                  be meritted.
    ###
    renderRestrictedAccessForm: (options) ->
      div {className: "RestrictedDialogForm__form col-xs-9 #{'off-xs-3' if options?.offset}"},
        form {
          ref: 'dialogForm',
          onSubmit: @handleSubmit,
          className: 'form-horizontal form-dialog permissions-dialog-form',
        },
          div className: "radio",
            label {},
              input {
                ref: 'publishInput'
                type: 'radio'
                name: 'permissions'
                checked: @state.selectedOption is 'published'
                onChange: (event) =>
                  @setState { selectedOption: 'published'}
              },
            I18n.t("options.publish.description", "Publish")

          div className: "radio",
            label {},
              input {
                ref: 'unpublishInput'
                type: 'radio'
                name: 'permissions'
                checked: @state.selectedOption is 'unpublished'
                onChange: (event) =>
                  @setState { selectedOption: 'unpublished'}
              },
              I18n.t("options.unpublish.description", "Unpublish")

          div className: "radio",
            label {},
              input {
                ref: 'permissionsInput'
                type: 'radio'
                name: 'permissions'
                checked: @state.selectedOption in ['link_only', 'date_range']
                onChange: (event) =>
                    @setState selectedOption: if @state.unlock_at
                                                'date_range'
                                              else
                                                'link_only'
              },
              I18n.t("options.restrictedAccess.description", "Restricted Access")


          div {
            style:
              'margin-left': '20px',
              display: (if  @state.selectedOption in ['link_only', 'date_range'] then 'block' else 'none')
            'aria-hidden': (if  @state.selectedOption in ['link_only', 'date_range'] then 'false' else 'true')
          },
            div className: "radio",
              label {},
                input {
                  ref: 'link_only'
                  type: 'radio'
                  name: 'restrict_options'
                  checked: @state.selectedOption is 'link_only'
                  onChange: (event) =>
                      @setState selectedOption: 'link_only'
                },
                if @allFolders()
                  I18n.t("Hidden, files inside will be available with links.")
                else if @props.models.length > 1 and @anyFolders()
                  I18n.t("Files and folder contents only available to students with link. Not visible in student files.")
                else
                  I18n.t("options.hiddenInput.description", "Only available to students with link. Not visible in student files.")

            div className: "radio",
              label {},
                 input {
                   ref: 'dateRange'
                   type: 'radio',
                   name: 'restrict_options',
                   checked: @state.selectedOption is 'date_range',
                   onChange: (event) =>
                     @setState({selectedOption: 'date_range'})
                 }
                 I18n.t("options_2.description", "Schedule student availability")

            div {
              className: 'control-group'
              style:
                hidden: @state.selectedOption is 'date_range'
            },
              label className: 'control-label dialog-adapter-form-calendar-label', I18n.t('Available From')
                div className: 'controls dateSelectInputContainer',
                  input
                    ref: 'unlock_at'
                    defaultValue: $.datetimeString(@state.unlock_at) if @state.unlock_at,
                    className: 'form-control dateSelectInput',
                    type: 'text',
                    'aria-label': I18n.t('Available From')
              div className: 'control-group',
                label className: 'control-label dialog-adapter-form-calendar-label', I18n.t('Available Until')
                  div className: 'controls dateSelectInputContainer',
                  input
                    ref: 'lock_at'
                    defaultValue: $.datetimeString(@state.lock_at) if @state.lock_at,
                    className: 'form-control dateSelectInput',
                    type: 'text'
                    'aria-label': I18n.t('Available Until')

          div className:"form-controls",
            button {
              type: 'button',
              onClick: @props.closeDialog,
              className: "btn",
            },
              I18n.t("button_text.cancel", "Cancel")

            button {
              ref: 'updateBtn'
              type: "submit",
              className: "btn btn-primary",
              disabled: !(@state.selectedOption)
            },
              I18n.t("button_text.update", "Update")



    render: withReactDOM ->
      # Doing this here to prevent possible repeat runs of @usageRightsOnAll and @allFolders
      showUsageRights = @props.usageRightsRequiredForContext && !@usageRightsOnAll() && !@allFolders()
      div {className: 'RestrictedDialogForm__container'},
        if (showUsageRights)
          div {className: 'RestrictedDialogForm__firstRow grid-row'},
            @renderUsageRightsWarning()
        div {className: 'RestrictedDialogForm__secondRow grid-row'},
          div {className: 'RestrictedDialogForm__preview col-xs-3'},
            DialogPreview({itemsToShow:@props.models})
          if (showUsageRights)
            div {className: 'RestrictedDialogForm__usageRights col-xs-9'},
              UsageRightsSelectBox {ref: 'usageSelection'}
              hr {}
          else
            @renderRestrictedAccessForm()
        if (showUsageRights)
          div {className: 'RestrictedDialogForm__thirdRow grid-row'},
            @renderRestrictedAccessForm({offset: true})

