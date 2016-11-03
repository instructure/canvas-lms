define([
  'jsx/grading/quizzesNextSpeedGrading'
], (quizzesNextSpeedGrading) => {

  let postMessageStub = sinon.stub()
  let fakeIframeHolder = {
    children: sinon.stub().returns([
      {
        contentWindow: {
          postMessage: postMessageStub
        }
      }
    ])
  }

  let registerCbStub = sinon.stub()
  let refreshGradesCbStub = sinon.stub()
  let addEventListenerStub = sinon.stub()
  let speedGraderWindow = {
    addEventListener: addEventListenerStub
  }

  let refreshSubmissionsToViewStub = sinon.stub()
  let showGradeStub = sinon.stub()
  let showDiscussionStub = sinon.stub()
  let showRubricStub = sinon.stub()
  let updateStatsInHeaderStub = sinon.stub()
  let refreshFullRubricStub = sinon.stub()
  let setGradeReadOnlStub = sinon.stub()

  let fakeEG = {
    refreshSubmissionsToView: refreshSubmissionsToViewStub,
    showGrade: showGradeStub,
    showDiscussion: showDiscussionStub,
    showRubric: showRubricStub,
    updateStatsInHeader: updateStatsInHeaderStub,
    refreshFullRubric: refreshFullRubricStub,
    setGradeReadOnly: setGradeReadOnlStub
  }

  let resetStubs = function () {
    registerCbStub.reset()
    refreshGradesCbStub.reset()
    addEventListenerStub.reset()
    refreshSubmissionsToViewStub.reset()
    showGradeStub.reset()
    showDiscussionStub.reset()
    showRubricStub.reset()
    updateStatsInHeaderStub.reset()
    refreshFullRubricStub.reset()
    setGradeReadOnlStub.reset()
  }

  module("quizzesNextSpeedGrading", {
    teardown: function () {
      resetStubs();
    }
  });

  test("adds a message event listener to window", function() {
    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    ok(addEventListenerStub.calledWith('message'))
  });

  test("sets grade to read only with a quizzesNext.register message", function() {
    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    fns.onMessage({data: {subject: 'quizzesNext.register'}})
    ok(fakeEG.setGradeReadOnly.calledWith(true))
  });

  test("calls the registerCallback with a quizzesNext.register message", function() {
    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    fns.onMessage({data: {subject: 'quizzesNext.register'}})
    ok(registerCbStub.calledWith(fns.postChangeSubmissionMessage))
  });

  test("calls the refreshGradesCb with a quizzesNext.submissionUpdate message", function() {
    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    fns.onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
    ok(refreshGradesCbStub.calledWith(fns.quizzesNextChange))
  });

  test("calls the correct functions on EG", function() {
    let fnsToCallOnEG = [
      'refreshSubmissionsToView',
      'showGrade',
      'showDiscussion',
      'showRubric',
      'updateStatsInHeader',
      'refreshFullRubric',
      'setGradeReadOnly'
    ]

    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    let fakeSubmissionData = {}
    fns.quizzesNextChange(fakeSubmissionData)

    fnsToCallOnEG.forEach(function (egFunction) {
      ok(fakeEG[egFunction].called)
    })
  });

  test("postChangeSubmissionMessage postMessage with the submission data", function() {
    let fns = quizzesNextSpeedGrading(fakeEG, fakeIframeHolder, registerCbStub, refreshGradesCbStub, speedGraderWindow)
    let arbitrarySubmissionData = {}
    fns.postChangeSubmissionMessage(arbitrarySubmissionData)
    ok(postMessageStub.calledWith({
      submission: arbitrarySubmissionData,
      subject: 'canvas.speedGraderSubmissionChange'
    }))
  });
});
