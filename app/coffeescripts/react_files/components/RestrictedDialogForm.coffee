define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!restrict_student_access'
  'compiled/models/Folder'
  'compiled/models/File'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], ($, React, withReactDOM, I18n, Folder, File) ->

  RestrictedDialogForm = React.createClass

    # === React Functions === #
    propTypes:
      closeDialog: React.PropTypes.func.isRequired,
      model: React.PropTypes.oneOfType([
        React.PropTypes.instanceOf(File),
        React.PropTypes.instanceOf(Folder)
      ])

    getInitialState: ->
      calendarOption: @initialCalendarOption()

    componentDidUpdate: ->
      @dateInputFields()
      @focusOnFirst()

    componentDidMount: ->
      @dateInputFields()

    # === Custom Functions === #

    # Function Summary
    #
    # Event though you can technically set each of these fields independently, since we 
    # are using them with a radio button we will grab all of the values and treat it as
    # a state based on the input fields.

    handleSubmit: (event) ->
      event.preventDefault()

      data = 
        'hidden': @refs.hiddenInput.getDOMNode().checked
        'unlock_at': @refs.availableFromInput.getDOMNode().value if @state.calendarOption
        'lock_at': @refs.availableUntilInput.getDOMNode().value if @state.calendarOption

      # Calling .save like this (passing data as the 'attrs' property on
      # the 'options' argument instead of as the first argument) is so that we just send
      # the 3 attributes we care about (hidden, lock_at, unlock_at) in the PUT
      # request (like you would for a PATCH request, execept our api doesn't support PATCH).
      # We do this so if some other user changes the name while we are looking at the page,
      # when we submit this form, we don't blow away their change and change the name back
      # to what it was. we just update the things we intended.
      dfd = @props.model.save({}, {attrs: data})

      $(@refs.dialogForm.getDOMNode()).disableWhileLoading dfd
      dfd.done => @props.closeDialog()

    # Function Summary
    #
    # Because hidden and calendar options might be nil or '' we need some
    # logic to determine if the dialog should show the calendar or hide without
    # url option. The !! are making sure we are working with boolean values
    #
    # @returns boolean

    initialCalendarOption: ->
      hiddenIsFalse = !@props.model.get('hidden')
      lockAtIsTrue = !!@props.model.get('lock_at')
      unlockAtIsTrue = !!@props.model.get('unlock_at')

      hiddenIsFalse && lockAtIsTrue && unlockAtIsTrue

    # Function Summary
    # This function was written for this one case. If more radio buttons are added
    # it might need to be changed.

    radioSelected: (event) ->
      selectedShowCalendar = @refs.showCalendarInput.getDOMNode() == event.target
      @setState calendarOption: selectedShowCalendar

    # Function Summary
    # If possible, focus on the first input element for accessiblity

    focusOnFirst: ->
      $(@refs.availableFromInput?.getDOMNode())?.focus()

    dateInputFields: ->
      if @refs.availableFromInput && @refs.availableUntilInput
        $(@refs.availableFromInput.getDOMNode()).date_field()
        $(@refs.availableUntilInput.getDOMNode()).date_field()

    # === Render Logic === #
    render: withReactDOM ->
      form ref: 'dialogForm', onSubmit: @handleSubmit, className: 'form-horizontal form-dialog', title: I18n.t("title.limit_student_access", "Limit student access"),
        div className: "radio",
          label {},
            input ref: 'hiddenInput', type: 'radio', name: 'restrict_access', value: 'true', onChange: @radioSelected, defaultChecked: !@state.calendarOption
            I18n.t("options_1.description", "Only allow students to view or download files in this folder when I link to them")

        div className: "radio",
          label {},
            input ref: 'showCalendarInput', type: 'radio', name: 'restrict_access', onChange: @radioSelected, defaultChecked: @state.calendarOption
            I18n.t("options_2.description", "Schedule student availability")

        @displayOption()

        div className:"form-controls",
          input type: 'button', onClick: @props.closeDialog, className: "btn", style: {'margin-right': '10px'}, value: I18n.t("button_text.cancel", "Cancel")
          input ref: 'updateBtn', type: "submit", className: "btn btn-primary", value: I18n.t("button_text.update", "Update")
    displayOption: ->
      if @state.calendarOption
        [
          div className: 'control-group',
            label className: 'control-label dialog-adapter-form-calendar-label', for: 'availableFromInput', I18n.t('label.availableFrom', 'Available From')
            div className: 'controls dateSelectInputContainer',
              input ref: 'availableFromInput', defaultValue: $.datetimeString(@props.model.get('unlock_at')), id: 'availableFromInput', className: 'form-control dateSelectInput', type: 'text', 'aria-label': I18n.t('aria_label.availableFrom', 'Available From')
         ,
          div className: 'control-group',
            label className: 'control-label dialog-adapter-form-calendar-label', for: 'availableUntil', I18n.t('label.availableUntil', 'Until')
            div className: 'controls dateSelectInputContainer',
              input ref: 'availableUntilInput', id: 'availableUntil', defaultValue: $.datetimeString(@props.model.get('lock_at')), className: 'form-control dateSelectInput', type: 'text', 'aria-label': I18n.t('aria_label.availableUntil', 'Until')
        ]
