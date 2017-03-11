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
      @editView = new EditConferenceView()

      @currentConferences = new ConferenceCollection(ENV.current_conferences)
      @currentConferences.on('change', (event) =>
        # focus if edit finalized (element is redrawn so we find by id)
        if @editConferenceId
          $("#new-conference-list div[data-id=" + @editConferenceId + "] .al-trigger").focus()
      )
      view = @currentView = new CollectionView
        el: $("#new-conference-list")
        itemView: ConferenceView
        collection: @currentConferences
        emptyMessage: I18n.t('no_new_conferences', 'There are no new conferences')
        listClassName: 'ig-list'
      view.render()

      @concludedConferences = new ConferenceCollection(ENV.concluded_conferences)
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

      $('.new-conference-btn').on('click', (event) => @create())

    index: ->
      @editView.close()

    create: ->
      conference = new Conference(_.clone(ENV.default_conference))
      conference.once('startSync', => @currentConferences.unshift(conference))
      if conference.get('permissions').create
        @editView.show(conference)

    edit: (conference) ->
      conference = @currentConferences.get(conference) || @concludedConferences.get(conference)
      return unless conference

      if conference.get('permissions').update
        @editConferenceId = conference.get('id')
        @editView.show(conference, isEditing: true)
      else
        # reached when a user without edit permissions navigates
        # to a specific conference's url directly
        $("#conf_#{conference.get('id')}")[0].scrollIntoView()

    close: (conference) =>
      @currentConferences.remove(conference)
      @concludedConferences.unshift(conference)

  window.router = new ConferencesRouter
  Backbone.history.start()
