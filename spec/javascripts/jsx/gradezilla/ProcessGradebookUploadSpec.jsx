define([
  'underscore',
  'jquery',
  'compiled/userSettings',
  'jsx/gradezilla/uploads/process_gradebook_upload',
  'helpers/fakeENV',
  'timezone'
], (_, $, userSettings, ProcessGradebookUpload, fakeENV) => {
  const assignmentOld1 = {id: 1, title: 'Old Assignment 1', points_possible: 25, published: true};

  const submissionOld1NoChange = {assignment_id: 1, grade: '20', original_grade: '20'};
  const submissionOld1Change = {assignment_id: 1, grade: '20', original_grade: '25'};
  const submissionOld1Excused = {assignment_id: 1, grade: 'EX', original_grade: '20'};

  const assignmentOld2 = {id: 2, title: 'Old Assignment 2', points_possible: 25, published: true};

  const assignmentOld2NoChange = {assignment_id: 2, grade: '20', original_grade: '20'};
  const submissionOld2Change = {assignment_id: 2, grade: '20', original_grade: '25'};
  const submissionOld2Excused = {assignment_id: 2, grade: 'EX', original_grade: '20'};

  const assignmentNew1 = {id: 0, title: 'New Assignment 1', points_possible: 25, published: true};

  const submissionNew1NoChange = {assignment_id: 0, grade: '20', original_grade: '20'};
  const submissionNew1Change = {assignment_id: 0, grade: '20', original_grade: '25'};
  const submissionNew1Excused = {assignment_id: 0, grade: 'EX', original_grade: '20'};

  const assignmentNew2 = {id: -1, title: 'New Assignment 2', points_possible: 25, published: true};

  const submissionNew2NoChange = {assignment_id: -1, grade: '20', original_grade: '20'};
  const submissionNew2Change = {assignment_id: -1, grade: '20', original_grade: '25'};
  const submissionNew2Excused = {assignment_id: -1, grade: 'EX', original_grade: '20'};

  const submissionIgnored = {assignment_id: -2, grade: '25', original_grade: '25'};

  const createAssignmentResponse1 = {id: 3};
  const createAssignmentResponse2 = {id: 4};

  const progressQueued = {id: 1, workflow_state: 'queued'};
  const progressCompleted = {id: 1, workflow_state: 'completed'};
  const progressFailed = {id: 1, workflow_state: 'failed'};

  let assignmentMap = [];
  assignmentMap[0] = 3;
  assignmentMap[-1] = 4;

  let xhr;
  let requests;

  let goToGradebookStub;

  let clock;

  function equalAssignment(assignment1, assignment2) {
    equal(assignment1.name, assignment2.title);
    equal(assignment1.points_possible, assignment2.points_possible);
    equal(assignment1.published, assignment2.published);
  }

  module('ProcessGradebookUpload#getNewAssignmentsFromGradebook');

  test('returns an empty array if the gradebook given has a single assignment with no id', () => {
    const gradebook = {assignments: [{key: 'value'}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 0);
  });

  test('returns an empty array if the gradebook given has a single assignment with a null id', () => {
    const gradebook = {assignments: [{id: null, key: 'value'}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 0);
  });

  test('returns an empty array if the gradebook given has a single assignment with positive id', () => {
    const gradebook = {assignments: [{id: 1}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 0);
  });

  test('returns an array with one assignment if gradebook given has a single assignment with zero id', () => {
    const gradebook = {assignments: [{id: 0}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 1);
    equal(assignments[0].id, 0);
  });

  test('returns an array with one assignment if the gradebook given has a single assignment with negative id', () => {
    const gradebook = {assignments: [{id: -1}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 1);
    equal(assignments[0].id, -1);
  });

  test("returns an array with only the assignments with non positive ids if the gradebook given has all ids", () => {
    const gradebook = {assignments: [{id: -1}, {id: 0}, {id: 1}]};
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook);

    equal(assignments.length, 2);
    ok(assignments[0].id < 1);
    ok(assignments[1].id < 1);
  });

  module('ProcessGradebookUpload#createIndividualAssignment', {
    setup: function() {
      xhr = sinon.useFakeXMLHttpRequest();
      requests = [];

      xhr.onCreate = function (xhr) {
        requests.push(xhr);
      };

      fakeENV.setup();
      ENV.create_assignment_path = '/create_assignment_path/url';
    },
    teardown: function() {
      xhr.restore();

      fakeENV.teardown();
    }
  });

  test('properly creates a new assignment', () => {
    const response = ProcessGradebookUpload.createIndividualAssignment(assignmentOld1);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentOld1);
  });

  module('ProcessGradebookUpload#createAssignments', {
    setup: function() {
      xhr = sinon.useFakeXMLHttpRequest();
      requests = [];

      xhr.onCreate = function (xhr) {
        requests.push(xhr);
      };

      fakeENV.setup();
      ENV.create_assignment_path = '/create_assignment_path/url';
    },
    teardown: function() {
      xhr.restore();

      fakeENV.teardown();
    }
  });

  test('sends no data to server and returns an empty array if given no assignments', () => {
    const gradebook = {assignments: []};
    const responses = ProcessGradebookUpload.createAssignments(gradebook);

    equal(requests.length, 0);
    equal(responses.length, 0);
  });

  test('properly filters and creates multiple assignments', () => {
    const gradebook = {assignments: [
      assignmentOld1,
      assignmentOld2,
      assignmentNew1,
      assignmentNew2
    ]};
    const responses = ProcessGradebookUpload.createAssignments(gradebook);

    equal(requests.length, 2);

    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest1.assignment, assignmentNew1);

    equal(requests[1].url, '/create_assignment_path/url');
    equal(requests[1].method, 'POST');

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody);
    equalAssignment(createAssignmentRequest2.assignment, assignmentNew2);
  });

  module('ProcessGradebookUpload#mapLocalAssignmentsToDatabaseAssignments');

  test('properly pairs if length is 1 and responses is not an array of arrays', () => {
    const gradebook = {assignments: [assignmentNew1]};
    const responses = [{id: 3}];
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses);

    equal(assignmentMap[assignmentNew1.id], responses[0].id);
  });

  test('properly pairs if length is not 1 and responses is an array of arrays', () => {
    const gradebook = {assignments: [assignmentNew1, assignmentNew2]};
    const responses = [[{id: 3}], [{id: 4}]];
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses);

    equal(assignmentMap[assignmentNew1.id], responses[0][0].id);
    equal(assignmentMap[assignmentNew2.id], responses[1][0].id);
  });

  test('does not attempt to pair assignments that do not have a negative id', () => {
    const gradebook = {assignments: [assignmentNew1, assignmentOld1, assignmentOld2, assignmentNew2]};
    const responses = [[{id: 3}], [{id: 4}]];
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses);

    equal(assignmentMap[assignmentNew1.id], responses[0][0].id);
    equal(assignmentMap[assignmentNew2.id], responses[1][0].id);
  });

  module('ProcessGradebookUpload#populateGradeDataPerSubmission');

  test('rejects an unrecognized or ignored assignment', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionIgnored, 0, [], gradeData);

    ok(_.isEmpty(gradeData));
  });

  test('does not alter a grade that requires no change', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1NoChange, 0, [], gradeData);

    ok(_.isEmpty(gradeData));
  });

  test('alters a grade on a new assignment', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionNew1Change, 0, assignmentMap, gradeData);

    equal(gradeData[assignmentMap[submissionNew1Change.assignment_id]][0].posted_grade, submissionNew1Change.grade);
  });

  test('alters a grade to excused on a new assignment', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionNew1Excused, 0, assignmentMap, gradeData);

    equal(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][0].excuse, true);
  });

  test('alters a grade on an existing assignment', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Change, 0, [], gradeData);

    equal(gradeData[submissionOld1Change.assignment_id][0].posted_grade, submissionOld1Change.grade);
  });

  test('alters a grade to excused on an existing assignment', () => {
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Excused, 0, [], gradeData);

    equal(gradeData[submissionOld1Excused.assignment_id][0].excuse, true);
  });

  module('ProcessGradebookUpload#populateGradeDataPerStudent');

  test('does not modify grade data if student submissions is an empty array', () => {
    const student = {previous_id: 1, submissions: []};
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData);

    ok(_.isEmpty(gradeData));
  });

  test('properly populates grade data for a student', () => {
    const student = {previous_id: 1, submissions: [
      submissionOld1Change,
      submissionOld2Excused,
      submissionNew1Excused,
      submissionNew2Change
    ]};
    let gradeData = {};
    ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData);

    equal(gradeData[submissionOld1Change.assignment_id][student.previous_id].posted_grade, submissionOld1Change.grade);
    equal(gradeData[submissionOld2Excused.assignment_id][student.previous_id].excuse, true);
    equal(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][student.previous_id].excuse, true);
    equal(gradeData[assignmentMap[submissionNew2Change.assignment_id]][student.previous_id].posted_grade, submissionNew2Change.grade);
  });

  module('ProcessGradebookUpload#populateGradeData');

  test('properly populates grade data', () => {
    const student_1 = {previous_id: 1, submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change]};
    const student_2 = {previous_id: 2, submissions: [submissionOld2Excused, submissionNew1Change, submissionNew2Excused]};
    const student_3 = {previous_id: 3, submissions: [submissionOld1Excused, submissionOld2Change, submissionNew2Change]};
    const gradebook = {students: [student_1, student_2, student_3], assignments: [assignmentOld1, assignmentOld2, assignmentNew1, assignmentNew2]};
    const responses = [[createAssignmentResponse1], [createAssignmentResponse2]];
    const gradeData = ProcessGradebookUpload.populateGradeData(gradebook, responses);

    equal(gradeData[submissionOld1Change.assignment_id][student_1.previous_id].posted_grade, submissionOld1Change.grade);
    equal(gradeData[createAssignmentResponse1.id][student_1.previous_id].excuse, true);
    equal(gradeData[createAssignmentResponse2.id][student_1.previous_id].posted_grade, submissionNew2Change.grade);
    equal(gradeData[submissionOld2Excused.assignment_id][student_2.previous_id].excuse, true);
    equal(gradeData[createAssignmentResponse1.id][student_2.previous_id].posted_grade, submissionNew2Change.grade);
    equal(gradeData[createAssignmentResponse2.id][student_2.previous_id].excuse, true);
    equal(gradeData[submissionOld1Excused.assignment_id][student_3.previous_id].excuse, true);
    equal(gradeData[submissionOld2Change.assignment_id][student_3.previous_id].posted_grade, submissionOld2Change.grade);
    equal(gradeData[createAssignmentResponse2.id][student_3.previous_id].posted_grade, submissionNew2Change.grade);
  });

  module('ProcessGradebookUpload#submitGradeData', {
    setup: function() {
      xhr = sinon.useFakeXMLHttpRequest();
      requests = [];

      xhr.onCreate = function (xhr) {
        requests.push(xhr);
      };

      fakeENV.setup();
      ENV.bulk_update_path = '/bulk_update_path/url';
    },
    teardown: function() {
      xhr.restore();

      fakeENV.teardown();
    }
  });

  test('properly submits grade data', () => {
    const gradeData = {
      '1': {
        '1': {posted_grade: '20'}, '2': {excuse: true}
      },
      '2': {
        '1': {posted_grade: '25'}, '2': {posted_grade: '15'}
      },
      '3': {
        '1': {excuse: true}, '2': {excuse: true}
      }
    };
    ProcessGradebookUpload.submitGradeData(gradeData);

    equal(requests.length, 1);
    equal(requests[0].url, '/bulk_update_path/url');
    equal(requests[0].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody);
    equal(bulkUpdateRequest.grade_data[1][1].posted_grade, 20);
    equal(bulkUpdateRequest.grade_data[1][2].excuse, true);
    equal(bulkUpdateRequest.grade_data[2][1].posted_grade, 25);
    equal(bulkUpdateRequest.grade_data[2][2].posted_grade, 15);
    equal(bulkUpdateRequest.grade_data[3][1].excuse, true);
    equal(bulkUpdateRequest.grade_data[3][2].excuse, true);
  });

  module('ProcessGradebookUpload#checkProgress and monitorProgress', {
    setup: function() {
      xhr = sinon.useFakeXMLHttpRequest();
      requests = [];

      xhr.onCreate = function (xhr) {
        requests.push(xhr);
      };

      goToGradebookStub = sinon.stub(ProcessGradebookUpload, "goToGradebook");

      clock = sinon.useFakeTimers();

      userSettings.contextSet('gradebookUploadComplete', false);
    },
    teardown: function() {
      xhr.restore();

      ProcessGradebookUpload.goToGradebook.restore();

      clock.restore();
    }
  });

  test('handles a successful grade data submission', () => {
    ProcessGradebookUpload.monitorProgress(progressCompleted);

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('handles a failed grade data submission', () => {
    ProcessGradebookUpload.monitorProgress(progressFailed);

    ok(!userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('properly checks progress', () => {
    ProcessGradebookUpload.monitorProgress(progressQueued);

    clock.tick(2000);

    equal(requests.length, 1);

    equal(requests[0].url, '/api/v1/progress/1');
    equal(requests[0].method, 'GET');

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('does not conclude until progress is complete or failed', () => {
    ProcessGradebookUpload.monitorProgress(progressQueued);

    clock.tick(2000);

    for(let i = 0; i <= 10; i++) {
      equal(requests.length, i + 1);
      equal(requests[i].url, '/api/v1/progress/1');
      equal(requests[i].method, 'GET');

      requests[i].respond(200, {}, JSON.stringify(progressQueued));

      clock.tick(2000);
    }

    equal(requests.length, 12);
    equal(requests[11].url, '/api/v1/progress/1');
    equal(requests[11].method, 'GET');

    requests[11].respond(200, {}, JSON.stringify(progressCompleted));

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  module('ProcessGradebookUpload#upload', {
    setup: function() {
      xhr = sinon.useFakeXMLHttpRequest();
      requests = [];

      xhr.onCreate = function (xhr) {
        requests.push(xhr);
      };

      goToGradebookStub = sinon.stub(ProcessGradebookUpload, "goToGradebook");

      clock = sinon.useFakeTimers();

      fakeENV.setup();
      ENV.create_assignment_path = '/create_assignment_path/url';
      ENV.bulk_update_path = '/bulk_update_path/url';

      userSettings.contextSet('gradebookUploadComplete', false);
    },
    teardown: function() {
      xhr.restore();

      ProcessGradebookUpload.goToGradebook.restore();

      clock.restore();

      fakeENV.teardown();
    }
  });

  test('sends no data to server if given null', () => {
    ProcessGradebookUpload.upload(null);
    equal(requests.length, 0);
  });

  test('sends no data to server if given an empty object', () => {
    ProcessGradebookUpload.upload({});
    equal(requests.length, 0);
  });

  test('sends no data to server if given a single existing assignment with no submissions', () => {
    const student = {previous_id: 1, submissions: []};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 0);
  });

  test('sends no data to server if given a single existing assignment that requires no change', () => {
    const student = {previous_id: 1, submissions: [submissionOld1NoChange]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 0);
  });

  test('handles a grade change to a single existing assignment', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/bulk_update_path/url');
    equal(requests[0].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student.previous_id].posted_grade, submissionOld1Change.grade);

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles a change to excused to a single existing assignment', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Excused]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/bulk_update_path/url');
    equal(requests[0].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student.previous_id].excuse, true);

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles multiple students changing a single existing assignment', () => {
    const student_1 = {previous_id: 1, submissions: [submissionOld1Change]};
    const student_2 = {previous_id: 2, submissions: [submissionOld1Excused]};
    const gradebook = {students: [student_1, student_2], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/bulk_update_path/url');
    equal(requests[0].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_1.previous_id].posted_grade, submissionOld1Change.grade);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_2.previous_id].excuse, true);

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles multiple students changing multiple existing assignments', () => {
    const student_1 = {previous_id: 1, submissions: [submissionOld1Change, submissionOld2Excused]};
    const student_2 = {previous_id: 2, submissions: [submissionOld1Excused, submissionOld2Change]};
    const gradebook = {students: [student_1, student_2], assignments: [assignmentOld1, assignmentOld2]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/bulk_update_path/url');
    equal(requests[0].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_1.previous_id].posted_grade, submissionOld1Change.grade);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_2.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[assignmentOld2.id][student_1.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[assignmentOld2.id][student_2.previous_id].posted_grade, submissionOld2Change.grade);

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles a creation of a new assignment with no submissions', () => {
    const student = {previous_id: 1, submissions: []};
    const gradebook = {students: [student], assignments: [assignmentNew1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    ok(goToGradebookStub.called);
  });

  test('handles the creation of several new assignments with no submissions', () => {
    const student = {previous_id: 1, submissions: []};
    const gradebook = {students: [student], assignments: [assignmentNew1, assignmentNew2]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 2);

    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest1.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests[1].url, '/create_assignment_path/url');
    equal(requests[1].method, 'POST');

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody);
    equalAssignment(createAssignmentRequest2.assignment, assignmentNew2);

    requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2));

    ok(goToGradebookStub.called);
  });

  test('handles a creation of a new assignment with no grade change', () => {
    const student = {previous_id: 1, submissions: [submissionNew1NoChange]};
    const gradebook = {students: [student], assignments: [assignmentNew1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    ok(goToGradebookStub.called);
  });

  test('handles creation of a new assignment with a grade change', () => {
    const student = {previous_id: 1, submissions: [submissionNew1Change]};
    const gradebook = {students: [student], assignments: [assignmentNew1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests.length, 2);
    equal(requests[1].url, '/bulk_update_path/url');
    equal(requests[1].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].posted_grade, submissionNew1Change.grade);

    requests[1].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles creation of a new assignment with a change to excused', () => {
    const student = {previous_id: 1, submissions: [submissionNew1Excused]};
    const gradebook = {students: [student], assignments: [assignmentNew1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests.length, 2);
    equal(requests[1].url, '/bulk_update_path/url');
    equal(requests[1].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].excuse, true);

    requests[1].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles multiple students changing a single new assignment', () => {
    const student_1 = {previous_id: 1, submissions: [submissionNew1Change]};
    const student_2 = {previous_id: 2, submissions: [submissionNew1Excused]};
    const gradebook = {students: [student_1, student_2], assignments: [assignmentNew1]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 1);
    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests.length, 2);
    equal(requests[1].url, '/bulk_update_path/url');
    equal(requests[1].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_1.previous_id].posted_grade, submissionNew1Change.grade);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_2.previous_id].excuse, true);

    requests[1].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles multiple students changing multiple new assignments', () => {
    const student_1 = {previous_id: 1, submissions: [submissionNew1Change, submissionNew2Excused]};
    const student_2 = {previous_id: 2, submissions: [submissionNew1Excused, submissionNew2Change]};
    const gradebook = {students: [student_1, student_2], assignments: [assignmentNew1, assignmentNew2]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 2);

    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest1.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests[1].url, '/create_assignment_path/url');
    equal(requests[1].method, 'POST');

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody);
    equalAssignment(createAssignmentRequest2.assignment, assignmentNew2);

    requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2));

    equal(requests.length, 3);
    equal(requests[2].url, '/bulk_update_path/url');
    equal(requests[2].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[2].requestBody);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_1.previous_id].posted_grade, submissionNew1Change.grade);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_2.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student_1.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student_2.previous_id].posted_grade, submissionNew2Change.grade);

    requests[2].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles multiple students changing multiple new and existing assignments', () => {
    const student_1 = {previous_id: 1, submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change]};
    const student_2 = {previous_id: 2, submissions: [submissionOld2Excused, submissionNew1Change, submissionNew2Excused]};
    const student_3 = {previous_id: 3, submissions: [submissionOld1Excused, submissionOld2Change, submissionNew2Change]};
    const gradebook = {students: [student_1, student_2, student_3], assignments: [assignmentOld1, assignmentOld2, assignmentNew1, assignmentNew2]};
    ProcessGradebookUpload.upload(gradebook);

    equal(requests.length, 2);

    equal(requests[0].url, '/create_assignment_path/url');
    equal(requests[0].method, 'POST');

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody);
    equalAssignment(createAssignmentRequest1.assignment, assignmentNew1);

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1));

    equal(requests[1].url, '/create_assignment_path/url');
    equal(requests[1].method, 'POST');

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody);
    equalAssignment(createAssignmentRequest2.assignment, assignmentNew2);

    requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2));

    equal(requests.length, 3);
    equal(requests[2].url, '/bulk_update_path/url');
    equal(requests[2].method, 'POST');

    const bulkUpdateRequest = JSON.parse(requests[2].requestBody);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_1.previous_id].posted_grade, submissionOld1Change.grade);
    equal(bulkUpdateRequest.grade_data[assignmentOld1.id][student_3.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[assignmentOld2.id][student_2.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[assignmentOld2.id][student_3.previous_id].posted_grade, submissionOld2Change.grade);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_1.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student_2.previous_id].posted_grade, submissionNew1Change.grade);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student_1.previous_id].posted_grade, submissionNew2Change.grade);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student_2.previous_id].excuse, true);
    equal(bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student_3.previous_id].posted_grade, submissionNew2Change.grade);

    requests[2].respond(200, {}, JSON.stringify(progressCompleted));

    ok(goToGradebookStub.called);
  });

  test('handles a successful grade data submission', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    requests[0].respond(200, {}, JSON.stringify(progressCompleted));

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('handles a failed grade data submission', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    requests[0].respond(200, {}, JSON.stringify(progressFailed));

    ok(!userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('properly checks progress of the grade data submission', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    requests[0].respond(200, {}, JSON.stringify(progressQueued));

    equal(requests.length, 1);

    clock.tick(2000);

    equal(requests.length, 2);
    equal(requests[1].url, '/api/v1/progress/1');
    equal(requests[1].method, 'GET');

    requests[1].respond(200, {}, JSON.stringify(progressCompleted));

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });

  test('does not conclude until progress is complete or failed', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]};
    const gradebook = {students: [student], assignments: [assignmentOld1]};
    ProcessGradebookUpload.upload(gradebook);

    requests[0].respond(200, {}, JSON.stringify(progressQueued));

    equal(requests.length, 1);

    clock.tick(2000);

    for(let i = 1; i <= 10; i++) {
      equal(requests.length, i + 1);
      equal(requests[i].url, '/api/v1/progress/1');
      equal(requests[i].method, 'GET');

      requests[i].respond(200, {}, JSON.stringify(progressQueued));

      clock.tick(2000);
    }

    equal(requests.length, 12);
    equal(requests[11].url, '/api/v1/progress/1');
    equal(requests[11].method, 'GET');

    requests[11].respond(200, {}, JSON.stringify(progressCompleted));

    ok(userSettings.contextGet('gradebookUploadComplete'));
    ok(goToGradebookStub.called);
  });
});
