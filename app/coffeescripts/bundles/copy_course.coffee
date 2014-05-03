require [
  'i18n!content_migrations'
  'jquery',
  'Backbone',
  'compiled/views/content_migrations/subviews/DateShiftView',
  'compiled/views/content_migrations/subviews/DaySubstitutionView',
  'compiled/collections/DaySubstitutionCollection',
  'compiled/views/CollectionView',
  'jst/content_migrations/subviews/DaySubstitutionCollection',
  'compiled/models/ContentMigration',
  'jquery.instructure_date_and_time'
], (I18n, $, Backbone, DateShiftView, DaySubstitutionView, DaySubstitutionCollection, CollectionView, template, ContentMigration)->

  $(document).ready ->
    $(".datetime_field").datetime_field(addHiddenInput: true)

  daySubCollection          = new DaySubstitutionCollection
  daySubCollectionView      = new CollectionView
                                 collection: daySubCollection
                                 emptyMessage: -> I18n.t('no_day_substitutions', "No Day Substitutions Added")
                                 itemView: DaySubstitutionView
                                 template: template


  dateShiftView = new DateShiftView
                                model: new ContentMigration
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE
                                addHiddenInput: true

  $('#date_shift').html dateShiftView.render().el
  dateShiftView.$oldStartDate.val(ENV.OLD_START_DATE).trigger('change')
  dateShiftView.$oldEndDate.val(ENV.OLD_END_DATE).trigger('change')

  $('#course_start_at').on 'change', ->
    dateShiftView.$newStartDate.val($(this).val()).trigger('change')

  $('#course_conclude_at').on 'change', ->
    dateShiftView.$newEndDate.val($(this).val()).trigger('change')
