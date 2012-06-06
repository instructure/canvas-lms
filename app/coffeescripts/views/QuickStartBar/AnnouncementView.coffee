define [
  'compiled/views/QuickStartBar/BaseItemView'
  'underscore'
  'compiled/models/Announcement'
  'jst/quickStartBar/announcement'
  'jquery.instructure_date_and_time'
], (BaseItemView, _, Announcement, template) ->

  class AnnouncementView extends BaseItemView

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to announce this too..."
      selector:
        baseData:
          type: 'course'
        preparer: (postData, data, parent) ->
          for row in data
            row.noExpand = true
        browser: false


    save: (json) ->

      # get real date
      if json.assignment?.due_at?
        json.assignment.due_at = @$('.datetime_suggest').text()

      # map the course_ids into deferreds, saving a copy for each course
      dfds = _.map json.course_ids, (id) =>
        model = new Announcement json
        model.set 'course_id', id.replace /^course_/, ''
        model.save()

      $.when dfds...

    @type: 'announcement'
    @title: -> super 'announcement', 'Announcement'
