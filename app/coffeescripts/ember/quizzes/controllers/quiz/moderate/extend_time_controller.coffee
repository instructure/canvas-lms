define [
  'ember'
  'ic-ajax'
  'i18n!quiz_extend_time'
], (Ember, ajax, I18n) ->

 ExtendTimeController = Ember.ObjectController.extend
    needs: ['quiz']
    quiz: Ember.computed.alias('controllers.quiz.model')
    extension: Ember.Object.create

    title: I18n.t('extend_time', 'Extend Time')

    extendFor: ( ->
      I18n.t('extensions_student', 'Extend time for for %{student}', student: @get("name"))
    ).property('name')

    timeOptions: [
      {id: 'now', name: I18n.t('now', 'now')},
      {id: 'end', name: I18n.t('ending_time', 'ending time')}
    ]

    setupExtension: ( ->
      @set("extension.extendFromTime", null)
      @set("extension.extendQuizMins", null)
    ).observes("model")

    actions:
      submit: ->
        quizExtension = user_id: @get("id")

        extendFromTime = if @get('extension.extendFromTime') == "now"
          "extend_from_now"
        else if @get('extension.extendFromTime') == "end"
          "extend_from_end_at"

        quizExtension[extendFromTime] = @get('extension.extendQuizMins')

        options =
          url: @get("quiz").get('quizExtensionsUrl')
          data: JSON.stringify(quiz_extensions: [quizExtension])
          type: 'POST'
          dataType: 'json'
          contentType: 'application/json'
          headers: 'Accepts': 'application/vnd.api+json'

        ajax.raw(options).then =>
          $.flashMessage I18n.t 'extensions_successfully_added', 'Extensions Successfully Added'
          @send 'refreshData'

