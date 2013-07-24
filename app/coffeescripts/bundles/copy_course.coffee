require [
  'jquery',
  'Backbone',
  'compiled/views/content_migrations/subviews/DateShiftView',
  'compiled/views/content_migrations/subviews/DaySubstitutionView',
  'compiled/collections/DaySubstitutionCollection',
  'compiled/views/CollectionView',
  'jst/content_migrations/subviews/DaySubstitutionCollection',
  'compiled/models/ContentMigration',
  'jquery.instructure_date_and_time'
], ($, Backbone, DateShiftView, DaySubstitutionView, DaySubstitutionCollection, CollectionView, template, ContentMigration)->

  $(document).ready ->
    $(".datetime_field").datetime_field()

  daySubCollection          = new DaySubstitutionCollection
  daySubCollectionView      = new CollectionView
                                 collection: daySubCollection
                                 emptyTemplate: -> "No Day Substitutions Added"
                                 itemView: DaySubstitutionView
                                 template: template


  dateShiftView = new DateShiftView
                                model: new ContentMigration
                                           daySubCollection: daySubCollection
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView

  $('#date_shift').html dateShiftView.render().el
  dateShiftView.$oldStartDate.val ENV.OLD_START_DATE
  dateShiftView.$oldEndDate.val ENV.OLD_END_DATE

  $('#course_start_at').on 'change', ->
    dateShiftView.$newStartDate.val $(this).val()

  $('#course_conclude_at').on 'change', ->
    dateShiftView.$newEndDate.val $(this).val()