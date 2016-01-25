define [
  'underscore'
  'jsx/gradebook/grid/helpers/submissionsHelper'
], (_, SubmissionsHelper) ->

  defaultSubmissionGroups = ->
    {
      2: [{
          user_id: 2,
          section_id: 1,
          submissions: [
            { id: 16, assignment_id: 6, user_id: 2 },
            { id: 19, assignment_id: 7, user_id: 2 }
          ]
        }],
      7: [{
          user_id: 7,
          section_id: 1,
          submissions: [
            { id: 22, assignment_id: 6, user_id: 7 },
            { id: 24, assignment_id: 7, user_id: 7 }
          ]
        }]
    }

  module 'SubmissionsHelper#extractSubmissions'

  test 'returns an object with a key for each assignment', ->
    submissionGroups = defaultSubmissionGroups()
    submissions = SubmissionsHelper.extractSubmissions(submissionGroups)

    propEqual _.keys(submissions), ['6', '7']

  test 'returns submissions indexed by their respective assignment ids', ->
    submissionGroups = defaultSubmissionGroups()
    submissions = SubmissionsHelper.extractSubmissions(submissionGroups)

    propEqual _.pluck(submissions[6], 'id'), [16, 22]
    propEqual _.pluck(submissions[7], 'id'), [19, 24]


  module 'SubmissionsHelper#submissionsForAssignment'

  test 'returns all submissions for an assignment indexed by user id, if any exist', ->
    submissionGroups = defaultSubmissionGroups()
    assignment = { id: 6 }
    submissions = SubmissionsHelper.submissionsForAssignment(submissionGroups, assignment)

    propEqual _.keys(submissions), ['2', '7']
    deepEqual submissions[2].id, 16
    deepEqual submissions[7].id, 22

  test 'returns an empty object if there are no submissions for the assignment', ->
    submissionGroups = defaultSubmissionGroups()
    assignment = { id: 9 }
    submissions = SubmissionsHelper.submissionsForAssignment(submissionGroups, assignment)

    propEqual submissions, {}
