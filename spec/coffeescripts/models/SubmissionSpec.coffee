define [
  'compiled/models/Submission'
], (Submission) ->

  module "Submission"

  module "Submission#isGraded"

  test "returns false if grade is null", ->
    submission = new Submission grade: null
    deepEqual submission.isGraded(), false

  test "returns true if grade is present", ->
    submission = new Submission grade: 'A'
    deepEqual submission.isGraded(), true

  module "Submission#hasSubmission"

  test "returns false if submission type is null", ->
    submission = new Submission submission_type: null
    deepEqual submission.hasSubmission(), false

  test "returns true if submission has a submission type", ->
    submission = new Submission submission_type: 'online'
    deepEqual submission.hasSubmission(), true
