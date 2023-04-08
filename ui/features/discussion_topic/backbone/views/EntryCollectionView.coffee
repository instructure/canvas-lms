#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import walk from '../../array-walk'
import {View} from '@canvas/backbone'
import {isRTL} from '@canvas/i18n/rtlHelper'
import template from '../../jst/EntryCollectionView.handlebars'
import entryStatsTemplate from '../../jst/entryStats.handlebars'
import EntryView from './EntryView'
import 'jquery-scroll-into-view'

I18n = useI18nScope('discussions')

export default class EntryCollectionView extends View

  defaults:
    descendants: 2
    showMoreDescendants: 2
    showReplyButton: false
    displayShowMore: true

    # maybe make a sub-class for threaded discussions if the branching gets
    # out of control. UPDATE: it is out of control
    threaded: false

    # its collection represents the root of the discussion, should probably
    # be a subclass instead :\
    root: false

  events:
    'click .loadNext': 'loadNextFromEvent'

  template: template

  $window: $ window

  els: '.discussion-entries': 'list'

  initialize: ->
    super
    @childViews = []

  attach: ->
    @collection.on 'reset', @addAll, this
    @collection.on 'add', @add, this

  toJSON: -> @options

  addAll: ->
    @teardown()
    @collection.each @add.bind(this)

  add: (entry) ->
    view = new EntryView
      model: entry
      treeView: @constructor
      descendants: @options.descendants
      children: @collection.options.perPage
      showMoreDescendants: @options.showMoreDescendants
      threaded: @options.threaded
      collapsed: @options.collapsed
    view.render()
    entry.on('change:editor', @nestEntries)
    return @addNewView view if entry.get 'new'
    if @options.descendants
      view.renderTree()
    else if entry.hasChildren()
      view.renderDescendantsLink()
    if !@options.threaded and !@options.root
      @list.prepend view.el
    else
      @list.append view.el
    @childViews.push(view)
    @nestEntries()

  nestEntries: ->
    directionToPad = if isRTL() then 'right' else 'left'
    $('.entry-content[data-should-position]').each ->
      $el    = $(this)
      level = $el.parents('li.entry').length
      offset = (level - 1) * 30
      $el.css("padding-#{directionToPad}", offset).removeAttr('data-should-position')
      $el.find('.discussion-title').attr
        'role': 'heading'
        'aria-level': level + 1

  addNewView: (view) ->
    view.model.set 'new', false
    @list.append view.el
    @nestEntries()
    if not @options.root
      @$window.scrollTo view.$el, 200

      view.$el.hide()
      setTimeout =>
        view.$el.fadeIn()
      , 500

  teardown: ->
    @list.empty()

  afterRender: ->
    super
    @addAll()
    @renderNextLink()

  renderNextLink: ->
    @nextLink?.remove()
    return unless @options.displayShowMore and @unShownChildren() > 0
    stats = @getUnshownStats()
    @nextLink = $ '<div/>'
    showMore = true
    if not @options.threaded
      moreText = I18n.t 'show_all_n_replies',
        one: "Show one reply"
        other: "Show all %{count} replies"
        {count: stats.total + @collection.options.perPage}
    @nextLink.html entryStatsTemplate({stats, moreText, showMore: yes})
    @nextLink.addClass 'showMore loadNext'
    if @options.threaded
      @nextLink.insertAfter @list
    else
      @nextLink.insertBefore @list

  getUnshownStats: ->
    start = @collection.length
    end = @collection.fullCollection.length
    unshown = @collection.fullCollection.toJSON().slice start, end
    total = 0
    unread = 0
    # No need to recursively traverse unshown here as
    # the collection has already been flattened. Using
    # undefined as the prop prevents the recursive walk
    walk unshown, undefined, (entry) ->
      total++
      unread++ if entry.read_state is 'unread'
    {total, unread}

  unShownChildren: ->
    @collection.fullCollection.length - @collection.length

  loadNextFromEvent: (event) ->
    event.stopPropagation()
    event.preventDefault()
    @loadNext()

  loadNext: ->
    if @options.threaded
      @collection.add @collection.fullCollection.getPage 'next'
    else
      @collection.reset @collection.fullCollection.toArray()
    @renderNextLink()

  filter: @::afterRender
