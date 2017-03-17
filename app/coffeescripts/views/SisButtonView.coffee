define [
  'i18n!assignments',
  'Backbone',
  'jquery',
  'jst/_sisButton'
], (I18n, Backbone, $, template) ->

  class SisButtonView extends Backbone.View
    template: template
    tagName: 'span'
    className: 'sis-button'
    events:
      'click': 'togglePostToSIS'

    # {string}
    # text used to describe the SIS NAME
    @optionProperty 'sisName'

    # {boolean}
    # boolean used to determine if due date
    # is required
    @optionProperty 'dueDateRequired'

    setAttributes: ->
      newSisAttributes = @sisAttributes()
      @$input.attr({
        'src': newSisAttributes['src'],
        'alt': newSisAttributes['description'],
        'title': newSisAttributes['description']
      })
      @$label.text(newSisAttributes['label'])

    togglePostToSIS: (e) =>
      e.preventDefault()
      sisUrl = @model.get('toggle_post_to_sis_url')
      c = @model.postToSIS()
      errors = @errorsExist()
      if !c == true && errors['has_error'] == true
        $.flashWarning(errors['message'])
      else if sisUrl
        @model.postToSIS(!c)
        @model.save({ override_dates: false }, {
          type: 'POST',
          url: sisUrl,
          success: =>
            @setAttributes()
        })
      else
        @model.postToSIS(!c)
        @model.save({ override_dates: false }, {
          success: =>
            @setAttributes()
        })

    errorsExist: =>
      errors = {}
      name = @modelName()
      base_message = "Unable to sync with #{@sisName}."
      if @dueDateErrorExists() && @nameLengthErrorExists()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} has a due date and name is not too long.", name: name, base_message: base_message)
      else if @dueDateErrorExists()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} has a due date.", name: name, base_message: base_message)
      else if @nameLengthErrorExists()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} name is not too long.", name: name, base_message: base_message)
      errors

    modelName: =>
      if @model.constructor.name == 'Assignment'
        @model.name()
      else if @model.constructor.name == 'Quiz'
        @model.attributes.title

    dueDateErrorExists: =>
      if @model.constructor.name == 'Assignment'
        @dueDateRequired && @model.dueAt() == null
      else if @model.constructor.name == 'Quiz'
        @dueDateRequired && @model.attributes.due_at == undefined

    nameLengthErrorExists: =>
      if @model.constructor.name == 'Assignment'
        @model.name().length > @model.maxNameLength()
      else if @model.constructor.name == 'Quiz'
        @model.attributes.title.length > @model.maxNameLength()

    sisAttributes: =>
      if @model.postToSIS()
        {
          src: '/images/svg-icons/svg_icon_sis_synced.svg',
          description: I18n.t('Sync to %{name} enabled. Click to toggle.', name: @sisName),
          label: I18n.t('The grade for this assignment will sync to the student information system.'),
        }
      else
        {
          src: '/images/svg-icons/svg_icon_sis_not_synced.svg',
          description: I18n.t('Sync to %{name} disabled. Click to toggle.', name: @sisName),
          label: I18n.t('The grade for this assignment will not sync to the student information system.')
        }


    render: ->
      super
      labelId = 'sis-status-label-'+ @model.id
      @$label = @$el.find('label')
      @$input = @$el.find('input')
      @$input.attr('aria-describedby': labelId)
      @$label.attr('id', labelId)
      @setAttributes()
