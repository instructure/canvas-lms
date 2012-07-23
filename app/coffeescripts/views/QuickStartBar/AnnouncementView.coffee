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

      # map the context_ids into deferreds, saving a copy for each context
      dfds = _.map json.context_ids, (id) =>
        debugger
        model = new Announcement json
        model.contextCode = id
        model.save()

      $.when dfds...

    @type: 'announcement'
    @title: -> super 'announcement', 'Announcement'
