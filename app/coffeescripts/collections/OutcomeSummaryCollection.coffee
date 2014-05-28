define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Section'
  'compiled/models/grade_summary/Group'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/PaginatedCollection'
  'compiled/collections/WrappedCollection'
  'compiled/util/natcompare'
], ($, _, {Collection}, Section, Group, Outcome, PaginatedCollection, WrappedCollection, natcompare) ->
  class GroupCollection extends PaginatedCollection
    @optionProperty 'course_id'
    model: Group
    url: -> "/api/v1/courses/#{@course_id}/outcome_groups"

  class LinkCollection extends PaginatedCollection
    @optionProperty 'course_id'
    url: -> "/api/v1/courses/#{@course_id}/outcome_group_links?outcome_style=full"

  class ResultCollection extends WrappedCollection
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
        results: new ResultCollection([], course_id: @course_id, user_id: @user_id)

    fetch: ->
      dfd = $.Deferred()
      requests = _.values(@rawCollections).map (collection) -> collection.loadAll = true; collection.fetch()
      $.when.apply($, requests).done(=> @processCollections(dfd))
      dfd

    scores: ->
      studentResults = @rawCollections.results.at(0).get('scores')
      pairs = studentResults.map((x) -> [x.links.outcome, x.score])
      _.object(pairs)

    populateGroupOutcomes: ->
      scores = @scores()
      @rawCollections.links.each (link) =>
        outcome = new Outcome(link.get('outcome'))
        outcome.set('score', scores[outcome.id])
        parent = @rawCollections.groups.get(link.get('outcome_group').id)
        parent.get('outcomes').add(outcome)

    populateSectionGroups: ->
      tmp = new Collection()
      @rawCollections.groups.each (group) =>
        return unless group.get('outcomes').length
        parentObj = group.get('parent_outcome_group')
        parentId = if parentObj then parentObj.id else group
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
