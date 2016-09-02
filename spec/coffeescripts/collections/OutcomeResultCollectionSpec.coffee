define [
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/OutcomeResultCollection'
  'helpers/fakeENV'
  'timezone'
], (Backbone, Outcome, OutcomeResultCollection, fakeENV, tz) ->
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
      @alignmentName2 = 'Second Alignment Name'
      @alignmentName3 = 'Third Alignment Name'
      @response = {
        outcome_results: [{
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z')
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
      @response2 = {
        outcome_results: [{
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z')
          links: {
            alignment: 'alignment_1'
          }
        },{
          submitted_or_assessed_at: tz.parse('2015-04-23T19:27:54Z')
          links: {
            alignment: 'alignment_2'
          }
        },{
          submitted_or_assessed_at: tz.parse('2015-04-25T19:27:54Z')
          links: {
            alignment: 'alignment_3'
          }
        }],
        linked: {
          alignments: [{
            id: 'alignment_1'
            name: @alignmentName
          },{
            id: 'alignment_2'
            name: @alignmentName2
          },{
            id: 'alignment_3'
            name: @alignmentName3
          }]
        }
      }
    teardown: ->
      fakeENV.teardown()

  test 'default params reflect aligned outcome', ->
    collectionModel = new @outcomeResultCollection.model()
    deepEqual collectionModel.get("mastery_points"), 8
    deepEqual collectionModel.get("points_possible"), 10

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
    equal @alignmentName, @outcomeResultCollection.first().get('alignment_name')

  test '#handleSort', ->
    equal @outcomeResultCollection.length, 0, 'precondition'

    @outcomeResultCollection.alignments = new Backbone.Collection(
      @response2['linked']['alignments']
    )
    ok @outcomeResultCollection.add(
      @response2['outcome_results'][0]
    )
    ok @outcomeResultCollection.add(
      @response2['outcome_results'][1]
    )
    ok @outcomeResultCollection.add(
      @response2['outcome_results'][2]
    )

    ok @outcomeResultCollection.length, 3
    equal @alignmentName3, @outcomeResultCollection.at(0).get('alignment_name')
    equal @alignmentName, @outcomeResultCollection.at(1).get('alignment_name')
    equal @alignmentName2, @outcomeResultCollection.at(2).get('alignment_name')
