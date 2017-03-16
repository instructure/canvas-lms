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
      @model.postToSIS(!c)
      if sisUrl
        @model.save({ override_dates: false }, {
          type: 'POST',
          url: sisUrl,
          success: =>
            @setAttributes()
        })
      else
        @model.save({ override_dates: false }, {
          success: =>
            @setAttributes()
        })

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
