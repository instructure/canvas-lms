// this is called by speed grader to enable communication
// between quizzesNext LTI tool and speed grader
// and modify normal speedGrader behavior to be more compatible
// with our LTI tool

// it sets up event listeners for postMessage communication
// from the LTI tool

// registerCb replaces the base speedgrader submissionChange callback
// with whatever callback is passed in as an argument

// refreshGradesCb executes the normal speedGrader refresh grades
// actions, plus whatever callback is passed in as an argument

define([], function() {
  function quizzesNextSpeedGrading (EG, $iframe_holder, registerCb, refreshGradesCb, speedGraderWindow = window) {
    function quizzesNextChange (submission) {
      EG.refreshSubmissionsToView();
      if (submission && submission.submission_history) {
        let lastIndex = submission.submission_history.length - 1;
        // set submission to selected in dropdown
        $("#submission_to_view option:eq(" + lastIndex + ")").attr("selected", "selected");
      }
      EG.showGrade();
      EG.showDiscussion();
      EG.showRubric();
      EG.updateStatsInHeader();
      EG.refreshFullRubric();
      EG.setGradeReadOnly(true);
    }

    // gets the submission from the speed_grader.js
    // function that will call this
    function postChangeSubmissionMessage (submission) {
      var frame = $iframe_holder.children()[0];
      if (frame && frame.contentWindow) {
        frame.contentWindow.postMessage(
          {
            submission,
            subject: 'canvas.speedGraderSubmissionChange'
          }, '*'
        );
      }
      quizzesNextChange(submission);
    }

    function onMessage (e) {
      var message = e.data;
      switch (message.subject) {
        case 'quizzesNext.register':
          EG.setGradeReadOnly(true);
          registerCb(postChangeSubmissionMessage);
          break;
        case 'quizzesNext.submissionUpdate':
          refreshGradesCb(quizzesNextChange);
          break;
      }
    }

    speedGraderWindow.addEventListener('message', onMessage);

    // expose for testing
    return {
      onMessage: onMessage,
      postChangeSubmissionMessage: postChangeSubmissionMessage,
      quizzesNextChange: quizzesNextChange
    };
  }

  return quizzesNextSpeedGrading;
});
