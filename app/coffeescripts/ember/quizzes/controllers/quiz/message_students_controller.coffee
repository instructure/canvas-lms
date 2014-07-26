define [
  'ember'
  'ic-ajax'
  'i18n!quiz_message_students'
], (Ember, ajax, I18n) ->

  {equal} = Ember.computed

  Ember.ArrayController.extend
    needs: ['quiz']
    quiz: Ember.computed.alias('controllers.quiz.model')

    title: I18n.t('message_students_who', 'Message Students Who...')

    recipientGroups: (->
      [
        Ember.Object.create({
          id: 'submitted'
          name: I18n.t('students_who_have_taken_the_quiz', 'Students Who Have Taken the Quiz'),
        })
        Ember.Object.create({
          id: 'unsubmitted'
          name: I18n.t('student_who_have_not_taken_the_quiz', 'Students Who Have Not Taken the Quiz')
        })
      ]
    ).property('quiz.submittedStudents', 'quiz.unsubmittedStudents')

    recipients: (->
      if @get('selectedRecipientGroup') is 'submitted'
        @get('quiz.submittedStudents')
      else
        @get('quiz.unsubmittedStudents')
    ).property('selectedRecipientGroup', 'quiz.submittedStudents', 'quiz.unsubmittedStudents')

    showUnsubmitted: equal 'selectedRecipientGroup', 'unsubmitted'

    noRecipients: equal 'recipients.length', 0

    moreRecipientsLabel: (->
      if @get('selectedRecipientGroup') is 'submitted'
        pagination = @store.metadataFor("submittedStudent").pagination
        shown = @get('quiz.submittedStudents.length')
      else
        pagination = @store.metadataFor("unsubmittedStudent").pagination
        shown = @get('quiz.unsubmittedStudents.length')

      total = if pagination then pagination.count else 0
      if total > shown
        I18n.t('and_num_more_students', 'and %{num} more students', num: total - shown)

    ).property('selectedRecipientGroup', 'quiz.submittedStudents', 'quiz.unsubmittedStudents')

    # base height + 10px height for every student
    modalHeight: (->
      325 + @get('recipients.length') * 10
    ).property('recipients', 'recipients.isFulfilled')

    actions:
      submit: ->
        if @get('messageBody')
          ajax.request
            url: @get('quiz.messageStudentsUrl')
            data: JSON.stringify(
              conversations: [
                recipients: @get('selectedRecipientGroup')
                body: @get('messageBody')
              ]
            )
            type: 'POST'
            dataType: 'json'
            contentType: 'application/json'
          Ember.$.flashMessage I18n.t 'message_sent_successfully', 'Message sent successfully'
        else
          Ember.$.flashWarning I18n.t 'message_not_sent_because_empty', 'Message not sent because it was left empty'
