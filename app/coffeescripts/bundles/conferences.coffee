require [
  'INST' # INST
  'i18n!conferences'
  'jquery' # $
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/collections/ConferenceCollection'
  'compiled/models/Conference'
  'compiled/views/conferences/ConferenceView'
  'compiled/views/conferences/ConcludedConferenceView'
  'compiled/views/conferences/EditConferenceView'
  'jquery.ajaxJSON' # ajaxJSON
  'jquery.instructure_forms' # formSubmit, fillFormData
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers' # replaceTags
  'jquery.keycodes' # keycodes
  'jquery.loadingImg' # loadingImage
  'compiled/jquery.rails_flash_notifications'
  'jquery.templateData' # fillTemplateData, getTemplateData
  'jquery.instructure_date_and_time' # date_field
], (INST, I18n, $, _, Backbone, CollectionView, ConferenceCollection, Conference, ConferenceView, ConcludedConferenceView, EditConferenceView) ->
  class ConferencesRouter extends Backbone.Router
    routes:
      '': 'index'
      'conference_:id': 'edit'

    editView: null
    currentConferences: null
    concludedConferences: null

    initialize: ->
      # populate the conference list with inital set of data
      course_id = ENV.context_asset_string.split('_')[1]

      @editView = new EditConferenceView()

      @currentConferences = new ConferenceCollection(ENV.current_conferences, course_id: course_id)
      view = @currentView = new CollectionView
        el: $("#new-conference-list")
        itemView: ConferenceView
        collection: @currentConferences
        emptyMessage: I18n.t('no_new_conferences', 'There are no new conferences')
        listClassName: 'ig-list'
      view.render()

      @concludedConferences = new ConferenceCollection(ENV.concluded_conferences, course_id: course_id)
      view = @concludedView = new CollectionView
        el: $("#concluded-conference-list")
        itemView: ConcludedConferenceView
        collection: @concludedConferences
        emptyMessage: I18n.t('no_concluded_conferences', 'There are no concluded conferences')
        listClassName: 'ig-list'
      view.render()

      $.screenReaderFlashMessage(
        I18n.t('notifications.inaccessible',
               'Warning: This page contains third-party content which is not accessible ' +
               'to screen readers.'),
        20000
      )

      $('.new-conference-btn').on('click', (event) =>
        conference = new Conference(_.clone(ENV.default_conference), course_id: course_id)
        conference.once('startSync', => @currentConferences.unshift(conference))
        @edit(conference)
      )

    index: ->
      @editView.close()

    edit: (conference) =>
      if typeof conference == 'string'
        conference = @currentConferences.get(conference)
      return unless conference
      @editView.show(conference)

    close: (conference) =>
      @currentConferences.remove(conference)
      @concludedConferences.unshift(conference)

  @router = new ConferencesRouter
  Backbone.history.start()
