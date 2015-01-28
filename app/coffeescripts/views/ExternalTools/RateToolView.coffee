define [
  'Backbone'
  'jquery'
  'i18n!external_tools'
  'str/htmlEscape'
  'jst/ExternalTools/RateToolView'
  'compiled/models/AppReview'
], (Backbone, $, I18n, htmlEscape, template, AppReview) ->

  class RateToolView extends Backbone.View
    template: template
    tagName: 'form'
    id: 'rate_app_form'

    els:
      '#rate-app-star': '$rateAppStar'
      'textarea[name="review_text"]': '$reviewText'

    afterRender: ->
      @$reviewText.val(@model.get('comments'))

      @$rateAppStar.raty
        path     : '/images/raty/'
        size     : 24
        starOff  : 'star-off-big.png'
        starOn   : 'star-on-big.png'
        score    : @model.get('rating')
        click: (score, evt) ->
          $('.alert-error').remove()

      @$el.dialog(
        title: I18n.t 'dialog_title_rate_tool', 'How do you rate this tool?'
        width: 520
        height: "auto"
        resizable: true
        close: => @$el.remove()
        buttons: [
          text: I18n.t('buttons.cancel', 'Cancel')
          click: -> $(this).dialog('close')
        ,
          class: "btn-primary"
          text: I18n.t 'submit', 'Submit'
          'data-text-while-loading': I18n.t 'saving', 'Saving...'
          click: => @submit()
        ]
      )

      @$el.submit (e) =>
        @submit()
        return false

      this

    submit: ->
      $('.alert-error').remove()
      if @$rateAppStar.raty('score')
        @model.save
          id: undefined
          rating: @$rateAppStar.raty('score')
          comments:  @$reviewText.val()
        ,
          success: (m, r) =>
            if r.type == 'error'
              $.flashError(I18n.t('save_failed', "Unable to save review: %{message}", { message: r.message }))
            m.trigger 'sync'
        @$el.dialog('close')

      else
        @showErrorMessage()

    showErrorMessage: ->
      message = I18n.t 'missing_stars', 'You must select a star rating'
      @$el.prepend("<div class='alert alert-error'>#{message}</span>")
