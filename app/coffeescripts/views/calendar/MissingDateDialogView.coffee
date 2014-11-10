define [
  'jquery'
  'underscore'
  'Backbone'
  'i18n!calendar.edit'
  'jst/calendar/missingDueDateDialog'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], ($, _, {View}, I18n, template) ->

  class MissingDateDialogView extends View
    dialogTitle: """
      <span>
        <i class="icon-warning"></i>
        #{I18n.t('titles.warning', 'Warning')}
      </span>
    """

    initialize: (options) ->
      super
      @validationFn = options.validationFn
      @labelFn      = options.labelFn or @defaultLabelFn
      @success      = options.success
      @da_enabled   = options.da_enabled

    defaultLabelFn: (input) ->
      $("label[for=#{$(input).attr('id')}]").text()

    render: ->
      @invalidFields = @validationFn()
      if @invalidFields == true
        false
      else
        @invalidSectionNames = _.map(@invalidFields, @labelFn)
        @showDialog()
        this

    getInvalidFields: ->
      invalidDates = _.select(@$dateFields, (date) -> $(date).val() is '')
      sectionNames = _.map(invalidDates, @labelFn)

      if sectionNames.length > 0
        [invalidDates, sectionNames]
      else
        false

    showDialog: ->
      description = I18n.t('missingDueDate', {
        one  : '%{sections} does not have a due date assigned.'
        other: '%{sections} do not have a due date assigned.'
      }, {
        sections: ''
        count: @invalidSectionNames.length
      })

      tpl = template(description: description,da_enabled: @da_enabled, sections: @invalidSectionNames)
      @$dialog = $(tpl).dialog
        dialogClass: 'dialog-warning'
        draggable  : false
        modal      : true
        resizable  : false
        title      : $(@dialogTitle)
      .fixDialogButtons()
      .on('click', '.btn', @onAction)
      @$dialog.parents('.ui-dialog:first').focus()

    onAction: (e) =>
      if $(e.currentTarget).hasClass('btn-primary')
        @success(@$dialog)
      else
        @cancel(@invalidFields, @sectionNames)

    cancel: (e) =>
      @$dialog.dialog('close').remove()
      @invalidFields[0].focus()
