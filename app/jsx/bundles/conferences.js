import I18n from 'i18n!conferences'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import CollectionView from 'compiled/views/CollectionView'
import ConferenceCollection from 'compiled/collections/ConferenceCollection'
import Conference from 'compiled/models/Conference'
import ConferenceView from 'compiled/views/conferences/ConferenceView'
import ConcludedConferenceView from 'compiled/views/conferences/ConcludedConferenceView'
import EditConferenceView from 'compiled/views/conferences/EditConferenceView'
import 'jquery.ajaxJSON'
import 'jquery.instructure_forms'
import 'jqueryui/dialog'
import 'jquery.instructure_misc_helpers'
import 'jquery.keycodes'
import 'jquery.loadingImg'
import 'compiled/jquery.rails_flash_notifications'
import 'jquery.templateData'
import 'jquery.instructure_date_and_time'

const ConferencesRouter = Backbone.Router.extend({
  routes: {
    '': 'index',
    'conference_:id': 'edit'
  },

  editView: null,
  currentConferences: null,
  concludedConferences: null,

  initialize () {
    this.close = this.close.bind(this)
    // populate the conference list with inital set of data
    this.editView = new EditConferenceView()

    this.currentConferences = new ConferenceCollection(ENV.current_conferences)
    this.currentConferences.on('change', () => {
      // focus if edit finalized (element is redrawn so we find by id)
      if (this.editConferenceId) {
        $(`#new-conference-list div[data-id=${this.editConferenceId}] .al-trigger`).focus()
      }
    })
    let view = this.currentView = new CollectionView({
      el: $('#new-conference-list'),
      itemView: ConferenceView,
      collection: this.currentConferences,
      emptyMessage: I18n.t('no_new_conferences', 'There are no new conferences'),
      listClassName: 'ig-list'
    })
    view.render()

    this.concludedConferences = new ConferenceCollection(ENV.concluded_conferences)
    view = this.concludedView = new CollectionView({
      el: $('#concluded-conference-list'),
      itemView: ConcludedConferenceView,
      collection: this.concludedConferences,
      emptyMessage: I18n.t('no_concluded_conferences', 'There are no concluded conferences'),
      listClassName: 'ig-list'
    })
    view.render()

    $.screenReaderFlashMessage(
      I18n.t(
        'notifications.inaccessible',
        'Warning: This page contains third-party content which is not accessible to screen readers.'
      ),
      20000
    )

    $('.new-conference-btn').on('click', () => this.create())
  },

  index () {
    this.editView.close()
  },

  create () {
    const conference = new Conference(_.clone(ENV.default_conference))
    conference.once('startSync', () => this.currentConferences.unshift(conference))
    if (conference.get('permissions').create) {
      this.editView.show(conference)
    }
  },

  edit (conference) {
    conference = this.currentConferences.get(conference) || this.concludedConferences.get(conference)
    if (!conference) return

    if (conference.get('permissions').update) {
      this.editConferenceId = conference.get('id')
      this.editView.show(conference, {isEditing: true})
    }
    // reached when a user without edit permissions navigates
    // to a specific conference's url directly
    $(`#conf_${conference.get('id')}`)[0].scrollIntoView()
  },

  close (conference) {
    this.currentConferences.remove(conference)
    this.concludedConferences.unshift(conference)
  }
})

window.router = new ConferencesRouter()
Backbone.history.start()
