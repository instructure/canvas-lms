define [
  'compiled/models/Submission'
], (Submission) ->

  QUnit.module "Submission"

  QUnit.module "Submission#isGraded"

  test "returns false if grade is null", ->
    submission = new Submission grade: null
    deepEqual submission.isGraded(), false

  test "returns true if grade is present", ->
    submission = new Submission grade: 'A'
    deepEqual submission.isGraded(), true

  QUnit.module "Submission#hasSubmission"

  test "returns false if submission type is null", ->
    submission = new Submission submission_type: null
    deepEqual submission.hasSubmission(), false

  test "returns true if submission has a submission type", ->
    submission = new Submission submission_type: 'online'
    deepEqual submission.hasSubmission(), true
