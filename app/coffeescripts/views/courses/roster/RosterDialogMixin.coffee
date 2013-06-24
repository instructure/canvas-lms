define [
  'i18n!roster'
  'underscore'
  'jquery.disableWhileLoading'
], (I18n, _) ->

  RosterDialogMixin =

    disable: (dfds) ->
      @$el.disableWhileLoading dfds, buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')}

    updateEnrollments: (addEnrollments, removeEnrollments) ->
      enrollments = @model.get 'enrollments'
      enrollments.push(en) for en in addEnrollments
      removeIds = _.pluck removeEnrollments, 'id'
      enrollments = _.reject enrollments, (en) -> _.include removeIds, en.id
      sectionIds = _.pluck enrollments, 'course_section_id'
      sections = _.select ENV.SECTIONS, (s) -> _.include sectionIds, s.id
      @model.set enrollments: enrollments, sections: sections
