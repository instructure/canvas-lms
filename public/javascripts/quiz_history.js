define([
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* fragmentChange */,
  'jquery.templateData' /* getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'compiled/behaviors/quiz_selectmenu'
], function($) {

  var parentWindow = {
    exists: function(){
      return (window.parent && window.parent.INST);
    },

    respondsTo: function(funcName){
      return (parentWindow.exists() && $.isFunction(window.parent.INST[funcName]));
    },

    hasProperty: function(propName){
      return (parentWindow.exists() && window.parent.INST[propName]);
    },

    set: function(propName, value){
      if(parentWindow.exists()){
        window.parent.INST[propName] = value;
      }
    },

    get: function(propName){
      if(parentWindow.hasProperty(propName)){
        return window.parent.INST[propName];
      }
    }
  };
  // end parentWindow object

  var data = $("#submission_details").getTemplateData({textValues: ['version_number', 'user_id']});

  var scoringSnapshot = {
    snapshot: {
      user_id: parseInt(data.user_id, 10) || null,
      version_number: data.version_number,
      last_question_touched: null,
      question_updates: {},
      fudge_points: 0
    },

    $quizBody: null,

    jumpPosition: function(question_id) {
      return $("#question_" + question_id).offset().top - 110;
    },

    checkQuizBody: function() {
      if(scoringSnapshot.$quizBody === null){
        scoringSnapshot.$quizBody = $('html,body');
      }
    },

    // Animates scrolling to question if there is no page reload
    jumpToQuestion: function(question_id) {
      var top = scoringSnapshot.jumpPosition(question_id);
      scoringSnapshot.checkQuizBody();
      scoringSnapshot.$quizBody.stop();
      scoringSnapshot.$quizBody.clearQueue();
      scoringSnapshot.$quizBody.animate({scrollTop: top}, 500);
    },

    // Jumps directly to question upon a page reload
    jumpDirectlyToQuestion: function(question_id) {
      var top = scoringSnapshot.jumpPosition(question_id);
      scoringSnapshot.checkQuizBody();
      scoringSnapshot.$quizBody.scrollTop(top);
    },

    externallySet: false,

    setSnapshot: function(data, cancelIfAlreadyExternallySet) {
      if(data) {
        if(cancelIfAlreadyExternallySet && scoringSnapshot.externallySet) { return; }
        scoringSnapshot.externallySet = true;
        scoringSnapshot.snapshot = data;
        for(var idx in data.question_updates) {
          var question = data.question_updates[idx];
          var $question = $("#question_" + idx);
          if (!ENV.GRADE_BY_QUESTION) {
            $question.addClass('modified_but_not_saved');
          }
          $question.find(".user_points :text").val(question.points).end()
            .find(".question_neutral_comment .question_comment_text textarea").val(question.comments);
        }
        if(parentWindow.hasProperty('lastQuestionTouched') && !ENV.GRADE_BY_QUESTION) {
          scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched);
        } else if(scoringSnapshot.snapshot.last_question_touched && !ENV.GRADE_BY_QUESTION) {
          scoringSnapshot.jumpToQuestion(scoringSnapshot.snapshot.last_question_touched);
        }
      } else if(cancelIfAlreadyExternallySet) {
        if(parentWindow.hasProperty('lastQuestionTouched') && !ENV.GRADE_BY_QUESTION) {
          scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched);
        }
      }
      if(scoringSnapshot.externallySet || cancelIfAlreadyExternallySet) {
        $("#feel_free_to_toggle_message").show();
      }
      if(parentWindow.respondsTo('refreshQuizSubmissionSnapshot')) {
        window.parent.INST.refreshQuizSubmissionSnapshot(scoringSnapshot.snapshot);
      }
    },

    update: function(question_id, data){
      scoringSnapshot.snapshot.question_updates[question_id] = data;
      scoringSnapshot.snapshot.last_question_touched = question_id;
      scoringSnapshot.setSnapshot();
    }
  }
  //end of scoringSnapshot object

  var gradingForm = {
    ensureSelectEventsFire: function(){
      $("input[type=text]").focus(function() {
        $(this).select();
      });
    },

    scrollToUpdatedQuestion: function(event, hash) {
      if(hash.indexOf("#question") == 0) {
        var id = hash.substring(10);
        scoringSnapshot.jumpToQuestion(id);
      }
    },

    updateSnapshotFor: function($question){
      var question_id = parseInt($question.attr('id').substring(9), 10) || null;
      if(question_id) {
        var data = {};
        if (!ENV.GRADE_BY_QUESTION) {
          $question.addClass('modified_but_not_saved');
        }
        data.points = parseFloat($question.find(".user_points :text").val(), 10);
        data.comments = $question.find(".question_neutral_comment .question_comment_text textarea").val() || "";
        scoringSnapshot.update(question_id, data);
      }
      $(document).triggerHandler('score_changed');
    },

    addFudgePoints: function(points){
      if(points || points === 0) {
        scoringSnapshot.snapshot.fudge_points = points;
        scoringSnapshot.setSnapshot();
      }
      $(document).triggerHandler('score_changed');
    },

    setInitialSnapshot: function(data){
      $("#feel_free_to_toggle_message").show();
      if(data) {
        scoringSnapshot.setSnapshot(data);
      } else {
        scoringSnapshot.setSnapshot(null, true);
      }
    },

    onScoreChanged: function(){
      var $total = $("#after_fudge_points_total");
      var total = 0;
      $(".display_question .user_points:visible").each(function() {
        var points = parseFloat($(this).find(":text:first").val(), 10) || 0;
        points = Math.round(points * 100.0) / 100.0;
        total = total + points;
      });
      var fudge = (parseFloat($("#fudge_points_entry").val(), 10) || 0);
      fudge = Math.round(fudge * 100.0) / 100.0;
      total = total + fudge;
      $total.text(total || "0");
    },

    questions: function(){
      return $('.question_holder').map(function(index, el) {
        return $(el).position().top - 320;
      }).toArray();
    },

    onScroll: function(){
      var qNum = quizNavBar.activateCorrectLink();
      quizNavBar.toggleDropShadow();
    },

    onWindowResize: function(){
      //Add padding to the bottom of the last question
      var winHeight = $(window).innerHeight();
      var lastHeight = $('div.question_holder:last-child').outerHeight();
      var fixedButtonHeight = $('#speed_update_scores_container').outerHeight();
      var paddingHeight = Math.max(winHeight - lastHeight - 150, fixedButtonHeight);
      $('#update_history_form .quiz-submission.headless').css('marginBottom', paddingHeight + 'px');
    }

  };
  //end of gradingForm object

  var quizNavBar = {
    index: 0,
    windowSize: 10,
    minWidth: 66,
    startingLeftPos: 32,
    navItemWidth: 34,

    initialize: function(){
      $('.user_points > .question_input').each(function(index){
        quizNavBar.updateStatusFor($(this));
      });

      if (ENV.GRADE_BY_QUESTION) {
        var questionId = parseInt(parentWindow.get('active_question_id'));
        if(!isNaN(questionId)){
          scoringSnapshot.jumpDirectlyToQuestion(questionId);
        }
      }

      quizNavBar.updateWindowSize();
      quizNavBar.setScrollWindowPosition(0);
    },

    size: function(){
      return $('.question-nav-link').length;
    },

    tooBig: function(){
      return quizNavBar.size() > quizNavBar.windowSize;
    },

    updateWindowSize: function(){
      var fullWidth = $('.quiz-nav, .quiz-nav-fullpage').width();
      var minPadding = 10;
      var maxWidth = fullWidth - (minPadding * 2);
      var itemCount = Math.floor((maxWidth - quizNavBar.minWidth) / quizNavBar.navItemWidth);
      quizNavBar.windowSize = itemCount;
      var actualWidth = (itemCount * quizNavBar.navItemWidth) + quizNavBar.minWidth;
      $('.quiz-nav .nav, .quiz-nav-fullpage .nav').animate({width: actualWidth + 'px'}, 10);
    },

    navArrowCache: null,

    $navArrows: function(){
      if(quizNavBar.navArrowCache === null){
        quizNavBar.navArrowCache = $('.quiz-nav .nav-arrow, .quiz-nav-fullpage .nav-arrow');
      }
      return quizNavBar.navArrowCache;
    },

    navWrapperCache: null,

    $navWrapper: function(){
      if(quizNavBar.navWrapperCache === null){
        quizNavBar.navWrapperCache = $('#quiz-nav-inner-wrapper');
      }
      return quizNavBar.navWrapperCache;
    },

    updateArrows: function(){
      if(quizNavBar.tooBig()){
        quizNavBar.$navArrows().show();
        quizNavBar.$navWrapper().css({position: 'absolute'});
      } else {
        quizNavBar.$navArrows().hide();
        quizNavBar.$navWrapper().css({position: 'relative'});
      }
    },

    toggleDropShadow: function(){
      //Add shadow to top bar
      $('.quiz-nav').toggleClass('drshadow', ($(document).scrollTop() > 0));
    },

    updateStatusFor: function($scoreInput){
      try{
        var questionId = $scoreInput.attr('name').split('_')[2];
        var scoreValue = $scoreInput.val();
        $('#quiz_nav_' + questionId).toggleClass('complete', (!isNaN(parseFloat(scoreValue))));
      } catch(err) {
        // do nothing; if there's no status to update, continue with other execution
      }
    },

    activateLink: function(index){
      $('.quiz-nav li').removeClass('active');
      $('.q' + index).addClass('active');
    },

    activateCorrectLink: function(){
      var qNum = 1;
      var qArray = gradingForm.questions();
      var docScroll = $(document).scrollTop();
      var maxScroll = $(document).height() - $('body').height();
      if (docScroll >= maxScroll) {
        qNum = qArray.length;
        quizNavBar.activateLink(qNum);
      } else {
        $questions = $('.question')
        for(var t = 0; t <= qArray.length; t++) {
          $question = $($questions[t])
          if ( (docScroll > qArray[t] && docScroll < qArray[t+1])  || ( t == (qArray.length - 1) && docScroll > qArray[t])) {
            qNum = t + 1;
            var questionId = $question.attr('id');
            if(questionId !== undefined){
              questionId = questionId.split('_')[1];
              parentWindow.set('active_question_id', questionId);
              quizNavBar.activateLink(qNum);
              $question.addClass('selected_single_question');
            }
          } else {
            $('.q'+ (t + 1)).removeClass('active');
            $question.removeClass('selected_single_question');
          }
        }
      }
      quizNavBar.setScrollWindowPosition(qNum);
      return qNum;
    },

    showQuestionsInWindow: function(startingIndex, endingIndex){
      var $navWrapper = $('#quiz-nav-inner-wrapper');
      var leftPosition = quizNavBar.startingLeftPos - (startingIndex * quizNavBar.navItemWidth);
      var newPos = '' + leftPosition + 'px';
      var currentPos = $navWrapper.css('left');
      if(newPos !== currentPos){
        $navWrapper.stop();
        $navWrapper.clearQueue();
        $navWrapper.animate({left: leftPosition + 'px'}, 300);
      }
    },

    windowScrollLength: function(){
      return Math.floor(quizNavBar.windowSize/2.0);
    },

    setScrollWindowPosition: function(currentIndex){
      if(isNaN(currentIndex)){
        currentIndex = 0;
      }
      quizNavBar.index = currentIndex;
      quizNavBar.updateArrows();
      if(quizNavBar.tooBig()){
        var startingIndex = currentIndex - quizNavBar.windowScrollLength();
        var maxStartingIndex = quizNavBar.size() - quizNavBar.windowSize;

        if(startingIndex < 0){
          startingIndex = 0;
          quizNavBar.index = 0;
        }else if(startingIndex > maxStartingIndex){
          startingIndex = maxStartingIndex;
          quizNavBar.index = maxStartingIndex + quizNavBar.windowScrollLength();
        }

        endingIndex = startingIndex + quizNavBar.windowSize - 1;
        quizNavBar.showQuestionsInWindow(startingIndex, endingIndex);
      }
    },

    previousQuestionBlock: function(){
      quizNavBar.setScrollWindowPosition(quizNavBar.index - quizNavBar.windowSize);
    },

    nextQuestionBlock: function(){
      quizNavBar.setScrollWindowPosition(quizNavBar.index + quizNavBar.windowSize);
    }
  };
  //End of quizNavBar object


  $(document).ready(function() {
    gradingForm.ensureSelectEventsFire();

    if (ENV.GRADE_BY_QUESTION) {
      $(document).scroll(gradingForm.onScroll);
      gradingForm.onWindowResize();

      $('.question_holder').click(function() {
        $('.quiz-nav li').removeClass('active');
        $('.question').removeClass('selected_single_question');
        $question = $(this).find('.question');
        var qId = $question.attr('id').split('_')[1];
        parentWindow.set('active_question_id', qId);
        $('#quiz_nav_' + qId).addClass('active');
        $question.addClass('selected_single_question');
      });
    }

    quizNavBar.initialize();

    $(document).fragmentChange(gradingForm.scrollToUpdatedQuestion);

    if(parentWindow.respondsTo('getQuizSubmissionSnapshot')) {
      var data = window.parent.INST.getQuizSubmissionSnapshot(scoringSnapshot.snapshot.user_id, scoringSnapshot.snapshot.version_number);
      gradingForm.setInitialSnapshot(data);
    }

    $(".question_holder .user_points :text,.question_holder .question_neutral_comment .question_comment_text textarea").change(function() {
      var $question = $(this).parents(".display_question");
      var questionId = $question.attr('id');
      gradingForm.updateSnapshotFor($question);
      if($(this).hasClass('question_input')){
        quizNavBar.updateStatusFor($(this));
      }
    });

    $("#fudge_points_entry").change(function() {
      var points = parseFloat($(this).val(), 10);
      gradingForm.addFudgePoints(points);
    });

    $(document).bind('score_changed', gradingForm.onScoreChanged);

    $('.question-nav-link').click(function(e) {
      e.preventDefault();
      var questionId = $(this).attr('data-id');
      scoringSnapshot.jumpToQuestion(questionId);
    });

    $('#nav-prev').click(function(e){
      e.preventDefault();
      quizNavBar.previousQuestionBlock();
    });

    $('#nav-next').click(function(e){
      e.preventDefault();
      quizNavBar.nextQuestionBlock();
    });

    $(window).resize(function () {
      quizNavBar.updateWindowSize();
      quizNavBar.setScrollWindowPosition(quizNavBar.index);
      gradingForm.onWindowResize();
    });
  });

  if (ENV.SCORE_UPDATED) {
    $(document).ready(function() {
      if(parentWindow.respondsTo('refreshGrades')) {
        window.parent.INST.refreshGrades();
      }
      if(parentWindow.respondsTo('clearQuizSubmissionSnapshot')) {
        window.parent.INST.clearQuizSubmissionSnapshot(scoringSnapshot.snapshot);
      }
    });
  }

});

