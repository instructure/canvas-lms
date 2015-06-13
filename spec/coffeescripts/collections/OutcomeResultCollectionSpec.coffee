define [
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/OutcomeResultCollection'
  'helpers/fakeENV'
], (Backbone, Outcome, OutcomeResultCollection, fakeENV) ->
  module 'OutcomeResultCollectionSpec',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = 'course_1'
      ENV.student_id = '1'
      @outcome = new Outcome({
        mastery_points: 8
        points_possible: 10
      })
      @outcomeResultCollection = new OutcomeResultCollection([], {
        outcome: @outcome
      })
      @alignmentName = 'First Alignment Name'
      @response = {
        outcome_results: [{
          submitted_or_assessed_at: '2015-04-24T19:27:54Z'
          links: {
            alignment: 'alignment_1'
          }
        }],
        linked: {
          alignments: [{
            id: 'alignment_1'
            name: @alignmentName
          }]
        }
      }
    teardown: ->
      fakeENV.teardown()

  test '#parse', ->
    ok !@outcomeResultCollection.alignments, 'precondition'

    ok @outcomeResultCollection.parse(@response)

    ok @outcomeResultCollection.alignments instanceof Backbone.Collection
    ok @outcomeResultCollection.alignments.length, 1


  test '#handleAdd', ->
    equal @outcomeResultCollection.length, 0, 'precondition'

    @outcomeResultCollection.alignments = new Backbone.Collection(
      @response['linked']['alignments']
    )
    ok @outcomeResultCollection.add(
      @response['outcome_results'][0]
    )

    ok @outcomeResultCollection.length, 1
    equal @outcome.get('mastery_points'),
      @outcomeResultCollection.first().get('mastery_points')
    equal @outcome.get('points_possible'),
      @outcomeResultCollection.first().get('points_possible')
    equal @alignmentName, @outcomeResultCollection.first().get('alignment_name')

