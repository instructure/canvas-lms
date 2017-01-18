define [
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/collections/OutcomeResultCollection'
  'compiled/models/grade_summary/Outcome'
  'compiled/models/grade_summary/Group'
  'compiled/views/grade_summary/OutcomeDetailView'
  'helpers/fakeENV'
], (_, Backbone, CollectionView, OutcomeResultCollection, Outcome, Group, OutcomeDetailView, fakeENV) ->

  module 'OutcomeDetailViewSpec',
    setup: ->
      @course_id = 1
      @user_id = 6
      fakeENV.setup()
      ENV.context_asset_string = "course_#{@course_id}"
      ENV.current_user = {display_name: 'Student One'}
      ENV.student_id = @user_id
      @outcome = new Outcome({
        id: 2
        mastery_points: 3
        points_possible: 5
      })
      @outcome.group = new Group({
        title: "Outcome Group Title"
      })
      @url = "/api/v1/courses/#{@course_id}/outcome_results?user_ids[]=#{@user_id}&outcome_ids[]=#{@outcome.id}&include[]=alignments"
      @outcomeDetailView = new OutcomeDetailView({
        course_id: @course_id
        user_id: @user_id
      })
      @server = sinon.fakeServer.create()
      @response = '{\"outcome_results\":[{\"id\":\"10\",\"score\":1,\"submitted_or_assessed_at\":\"2015-03-13T16:23:26Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_1\"}},{\"id\":\"11\",\"score\":2,\"submitted_or_assessed_at\":\"2015-03-13T16:23:46Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_15\"}},{\"id\":\"12\",\"score\":3,\"submitted_or_assessed_at\":\"2015-03-13T16:24:02Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_16\"}},{\"id\":\"13\",\"score\":4,\"submitted_or_assessed_at\":\"2015-03-13T16:24:13Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_17\"}},{\"id\":\"14\",\"score\":5,\"submitted_or_assessed_at\":\"2015-03-13T16:24:27Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_18\"}},{\"id\":\"15\",\"score\":4,\"submitted_or_assessed_at\":\"2015-03-13T16:25:20Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_19\"}},{\"id\":\"16\",\"score\":3,\"submitted_or_assessed_at\":\"2015-03-13T16:25:34Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_30\"}},{\"id\":\"17\",\"score\":3,\"submitted_or_assessed_at\":\"2015-03-13T17:00:58Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_55\"}},{\"id\":\"18\",\"score\":2,\"submitted_or_assessed_at\":\"2015-03-13T17:01:13Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_56\"}},{\"id\":\"19\",\"score\":1,\"submitted_or_assessed_at\":\"2015-03-13T17:01:38Z\",\"links\":{\"user\":\"6\",\"learning_outcome\":\"2\",\"alignment\":\"assignment_57\"}}],\"linked\":{\"alignments\":[{\"id\":\"assignment_19\",\"name\":\"New assignment for peer reviews.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/19\"},{\"id\":\"assignment_30\",\"name\":\"Assignment to multi-grade.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/30\"},{\"id\":\"assignment_16\",\"name\":\"We are just overloaded with assignments now, aren\'t we?\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/16\"},{\"id\":\"assignment_17\",\"name\":\"More assignments. \",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/17\"},{\"id\":\"assignment_18\",\"name\":\"So many assignments, yes.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/18\"},{\"id\":\"assignment_1\",\"name\":\"This is the first assignment.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/1\"},{\"id\":\"assignment_55\",\"name\":\"An 8th assignment.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/55\"},{\"id\":\"assignment_56\",\"name\":\"A 9th assignment, ladies and gentlemen.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/56\"},{\"id\":\"assignment_15\",\"name\":\"A third, super, great, assignment.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/15\"},{\"id\":\"assignment_57\",\"name\":\"A 10th assignment.\",\"html_url\":\"http:\/\/localhost:3000\/courses\/1\/assignments\/57\"}]}}'

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test '#initialize', ->
    ok @outcomeDetailView.alignmentsForView instanceof Backbone.Collection,
      'alignmentsForView should be an instance of Backbone.Collection'
    ok @outcomeDetailView.alignmentsView instanceof CollectionView,
      'alignmentsView should be an instance of CollectionView'

  test '#render', ->
    @server.respondWith('GET', @url, [ 200, {
      'Content-Type': 'application/json'
    }, @response ])

    @outcomeDetailView.show @outcome
    @outcomeDetailView.render()
    @server.respond()

    ok @outcomeDetailView.allAlignments instanceof OutcomeResultCollection,
      'should assign allAlignments collection'

    equal JSON.parse(@response).linked.alignments.length, 10, 'precondition; response should have 10 records'
    equal @outcomeDetailView.$('.alignment').length, 8, 'should only render last 8 alignments'
    @outcomeDetailView.close()

