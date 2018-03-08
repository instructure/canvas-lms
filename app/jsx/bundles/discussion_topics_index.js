/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!discussions'
import _ from 'underscore'
import Backbone from 'Backbone'
import DiscussionTopicsCollection from 'compiled/collections/DiscussionTopicsCollection'
import DiscussionListView from 'compiled/views/DiscussionTopics/DiscussionListView'
import IndexView from 'compiled/views/DiscussionTopics/IndexView'

const DiscussionIndexRouter = Backbone.Router.extend({
  // Public: I18n strings.
  messages: {
    lists: {
      open: I18n.t('discussions', 'Discussions'),
      locked: I18n.t('closed_for_comments', 'Closed for Comments'),
      pinned: I18n.t('pinned_discussions', 'Pinned Discussions')
    },
    help: {
      title: I18n.t('ordered_by_recent_activity', 'Ordered by Recent Activity')
    },
    toggleMessage: I18n.t('toggle_message', 'toggle section visibility')
  },

  // Public: Routes to respond to.
  routes: {
    '': 'index'
  },

  initialize() {
    ;['moveModel', '_onPipelineEnd', '_onPipelineLoad'].forEach(
      method => (this[method] = this[method].bind(this))
    )
    this.discussions = {
      open: this._createListView('open', {
        comparator: 'dateComparator',
        draggable: true,
        destination: '.pinned.discussion-list, .locked.discussion-list'
      }),
      locked: this._createListView('locked', {
        comparator: 'dateComparator',
        destination: '.pinned.discussion-list, .open.discussion-list',
        draggable: true,
        locked: true
      }),
      pinned: this._createListView('pinned', {
        comparator: 'positionComparator',
        destination: '.open.discussion-list, .locked.discussion-list',
        sortable: true,
        pinned: true
      })
    }
  },

  // Public: The index page action.
  index() {
    this.view = new IndexView({
      openDiscussionView: this.discussions.open,
      lockedDiscussionView: this.discussions.locked,
      pinnedDiscussionView: this.discussions.pinned,
      permissions: ENV.permissions,
      atom_feed_url: ENV.atom_feed_url
    })
    this._attachCollections()
    this.fetchDiscussions()
    this.view.render()
  },

  // Public: Fetch this context's discussions from the server. Use a new
  // DiscussionTopicsCollection and then sort/filter results on the client.
  //
  // Returns nothing.
  fetchDiscussions() {
    const pipeline = new DiscussionTopicsCollection()
    pipeline.fetch({
      data: {
        plain_messages: true,
        exclude_assignment_descriptions: true,
        exclude_context_module_locked_topics: true,
        order_by: 'recent_activity',
        include: 'all_dates',
        per_page: 50
      }
    })
    pipeline.on('fetch', this._onPipelineLoad)
    pipeline.on('fetched:last', this._onPipelineEnd)
  },

  // Internal: Create a new DiscussionListView of the given type.
  //
  // type: The type of discussions this list will hold  Options are 'open',
  //   'locked', and 'pinned'.
  //
  // Returns a DiscussionListView object.
  _createListView(type, options = {}) {
    const comparator = DiscussionTopicsCollection[options.comparator]
    delete options.comparator
    return new DiscussionListView({
      collection: new DiscussionTopicsCollection([], {comparator}),
      className: type,
      destination: options.destination,
      draggable: !!options.draggable,
      itemViewOptions: _.extend(options, {pinnable: ENV.permissions.moderate}),
      listID: `${type}-discussions`,
      locked: !!options.locked,
      pinnable: ENV.permissions.moderate,
      pinned: !!options.pinned,
      sortable: !!options.sortable,
      title: this.messages.lists[type],
      titleHelp: _.include(['open', 'locked'], type) ? this.messages.help.title : null,
      toggleMessage: this.messages.toggleMessage
    })
  },

  // Internal: Attach events to the discussion topic collections.
  //
  // Returns nothing.
  _attachCollections() {
    for (const key in this.discussions) {
      const view = this.discussions[key]
      view.collection.on('change:locked change:pinned', this.moveModel)
    }
  },

  // Internal: Handle a page of discussion topic results, fetching the next
  // page if it exists.
  //
  // collection - The collection firing the fetch event.
  // models - The models fetched from the server.
  //
  // Returns nothing.
  _onPipelineLoad(collection, models) {
    this._sortCollection(models)
    if (collection.urls.next) {
      setTimeout(() => collection.fetch({page: 'next'}), 0)
    }
  },

  // Internal: Handle the last page of discussion topic results, propagating
  // the event down to all of the filtered collections.
  //
  // Returns nothing.
  _onPipelineEnd() {
    for (const key in this.discussions) {
      const view = this.discussions[key]
      view.collection.trigger('fetched:last')
    }
    if (!this.discussions.pinned.collection.length && !ENV.permissions.moderate) {
      this.discussions.pinned.$el.remove()
    }

    if (
      this.discussions.pinned.collection.length &&
      !this.discussions.open.collection.length &&
      !ENV.permissions.moderate
    ) {
      this.discussions.open.$el.remove()
    }
  },

  // Internal: Sort the given collection into the open, locked, and pinned
  // collections of topics.
  //
  // pipeline - The collection to filter.
  //
  // Returns nothing.
  _sortCollection(pipeline) {
    const group = this._groupModels(pipeline)

    // add silently and just render whole sorted collection once all the pages have been fetched
    for (const key in group) {
      this.discussions[key].collection.add(group[key], {silent: true})
    }
  },

  // Internal: Group models in the given collection into an object with
  // 'open', 'locked', and 'pinned' keys.
  //
  // pipeline - The collection to group.
  //
  // Returns an object.
  _groupModels(pipeline) {
    const defaults = {pinned: [], locked: [], open: []}
    return _.extend(defaults, _.groupBy(pipeline, this._modelBucket))
  },

  // Determine the name of the model's proper collection.
  //
  // model - A discussion topic model.
  //
  // Returns a string.
  _modelBucket(model) {
    if (model.attributes) {
      if (model.get('pinned')) return 'pinned'
      if (
        model.get('locked') ||
        (model.get('locked_for_user') && model.get('lock_info').unlock_at == null)
      )
        return 'locked'
    } else {
      if (model.pinned) return 'pinned'
      if (model.locked || (model.locked_for_user && model.lock_info.unlock_at == null))
        return 'locked'
    }
    return 'open'
  },

  // Internal: Move a model from one collection to another.
  //
  // model - The model to transition.
  //
  // Returns nothing.
  moveModel(model) {
    const bucket = this.discussions[this._modelBucket(model)].collection
    if (bucket === model.collection) return
    model.collection.remove(model)
    bucket.add(model)
  }
})

// Start up the page
const router = new DiscussionIndexRouter()
Backbone.history.start()
