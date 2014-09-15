define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!restrict_student_access'
], ($, React, withReactDOM, I18n) ->

  RestrictedDialogForm = React.createClass
    getInitialState: ->
      calendarOption: false

    propTypes:
      closeDialog: React.PropTypes.func.isRequired

    handleSubmit: (event) ->
      event.preventDefault()

    componentDidMount: ->
      @dateInputFields()

    radioSelected: (event) ->
      selectedShowCalendar = @refs.showCalendarInput.getDOMNode() == event.target
      @setState calendarOption: selectedShowCalendar

    componentDidUpdate: ->
       @dateInputFields()
       @focusOnFirst()

    # If possible, focus on the first input element for accessiblity
    focusOnFirst: ->
      $(@refs.availableFromInput?.getDOMNode())?.focus()

    dateInputFields: ->
      $(@refs.availableFromInput?.getDOMNode())?.date_field()
      $(@refs.availableUntilInput?.getDOMNode())?.date_field()

    render: withReactDOM ->

      form onSubmit: this.handleSubmit, className: 'form-horizontal form-dialog', title: I18n.t("title.limit_student_access", "Limit student access"),
        div className: "radio",
          label {},
            input type: 'radio', name: 'restrict_access', value: 'true', onChange: @radioSelected, defaultChecked: true
            I18n.t("options_1.description", "Only allow students to view or download files in this folder when I link to them")

        div className: "radio",
          label {},
            input ref: 'showCalendarInput', type: 'radio', name: 'restrict_access', value: 'abc', onChange: @radioSelected
            I18n.t("options_2.description", "Schedule student availability")

        @displayOption()

        div className:"form-controls",
          input type: 'button', onClick: @props.closeDialog, className: "btn", value: I18n.t("button_text.cancel", "Cancel")
          input type: "submit", className: "btn btn-primary", value: I18n.t("button_text.update", "Update")

    displayOption: ->
      if @state.calendarOption
        [
          div className: 'control-group',
            label className: 'control-label dialog-adapter-form-calendar-label', for: 'availableFromInput', I18n.t('label.availableFrom', 'Available From')
            div className: 'controls dateSelectInputContainer',
              input ref: 'availableFromInput', id: 'availableFromInput', className: 'form-control dateSelectInput', type: 'text', 'aria-label': I18n.t('aria_label.availableFrom', 'Available From')
         ,
          div className: 'control-group',
            label className: 'control-label dialog-adapter-form-calendar-label', for: 'availableUntil', I18n.t('label.availableUntil', 'Until')
            div className: 'controls dateSelectInputContainer',
              input ref: 'availableUntilInput', id: 'availableUntil', className: 'form-control dateSelectInput', type: 'text', 'aria-label': I18n.t('aria_label.availableUntil', 'Until')
        ]
