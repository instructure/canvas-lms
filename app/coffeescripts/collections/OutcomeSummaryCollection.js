#
# Copyright (C) 2014 - present Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'Backbone'
  '../models/grade_summary/Section'
  '../models/grade_summary/Group'
  '../models/grade_summary/Outcome'
  '../collections/PaginatedCollection'
  '../collections/WrappedCollection'
  '../util/natcompare'
], ($, _, {Collection}, Section, Group, Outcome, PaginatedCollection, WrappedCollection, natcompare) ->
  class GroupCollection extends PaginatedCollection
    @optionProperty 'course_id'
    model: Group
    url: -> "/api/v1/courses/#{@course_id}/outcome_groups"

  class LinkCollection extends PaginatedCollection
    @optionProperty 'course_id'
    url: -> "/api/v1/courses/#{@course_id}/outcome_group_links?outcome_style=full"

  class RollupCollection extends WrappedCollection
    @optionProperty 'course_id'
    @optionProperty 'user_id'
    key: 'rollups'
    url: -> "/api/v1/courses/#{@course_id}/outcome_rollups?user_ids[]=#{@user_id}"

  class OutcomeSummaryCollection extends Collection
    @optionProperty 'course_id'
    @optionProperty 'user_id'

    comparator: natcompare.byGet('path')

    initialize: ->
      super
      @rawCollections =
        groups: new GroupCollection([], course_id: @course_id)
        links: new LinkCollection([], course_id: @course_id)
        rollups: new RollupCollection([], course_id: @course_id, user_id: @user_id)
      @outcomeCache = new Collection()

    fetch: ->
      dfd = $.Deferred()
      requests = _.values(@rawCollections).map (collection) -> collection.loadAll = true; collection.fetch()
      $.when.apply($, requests).done(=> @processCollections(dfd))
      dfd

    rollups: ->
      studentRollups = @rawCollections.rollups.at(0).get('scores')
      pairs = studentRollups.map((x) -> [x.links.outcome, x])
      _.object(pairs)

    populateGroupOutcomes: ->
      rollups = @rollups()
      @outcomeCache.reset()
      @rawCollections.links.each (link) =>
        outcome = new Outcome(link.get('outcome'))
        parent = @rawCollections.groups.get(link.get('outcome_group').id)
        rollup = rollups[outcome.id]
        outcome.set('score', rollup?.score)
        outcome.set('result_title', rollup?.title)
        outcome.set('submission_time', rollup?.submitted_at)
        outcome.set('count', rollup?.count || 0)
        outcome.group = parent
        parent.get('outcomes').add(outcome)
        @outcomeCache.add(outcome)

    populateSectionGroups: ->
      tmp = new Collection()
      @rawCollections.groups.each (group) =>
        return unless group.get('outcomes').length
        parentObj = group.get('parent_outcome_group')
        parentId = if parentObj then parentObj.id else group.id
        unless parent = tmp.get(parentId)
          parent = tmp.add(new Section(id: parentId, path: @getPath(parentId)))
        parent.get('groups').add(group)
      @reset(tmp.models)

    processCollections: (dfd) =>
      @populateGroupOutcomes()
      @populateSectionGroups()
      dfd.resolve(@models)

    getPath: (id) ->
      group = @rawCollections.groups.get(id)
      parent = group.get('parent_outcome_group')
      return '' unless parent
      parentPath = @getPath(parent.id)
      (if parentPath then parentPath + ': ' else '') + group.get('title')
