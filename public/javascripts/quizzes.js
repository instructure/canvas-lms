/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// xsslint jqueryObject.function makeFormAnswer makeDisplayAnswer
// xsslint jqueryObject.property sortable placeholder
// xsslint safeString.property question_text
define([
  'jst/quiz/regrade',
  'i18n!quizzes',
  'underscore',
  'jquery' /* $ */,
  'calcCmd',
  'str/htmlEscape',
  'str/pluralize',
  'compiled/handlebars_helpers',
  'compiled/views/assignments/DueDateOverride',
  'compiled/models/Quiz',
  'compiled/models/DueDateList',
  'compiled/views/quizzes/QuizRegradeView',
  'compiled/collections/SectionCollection',
  'compiled/views/calendar/MissingDateDialogView',
  'compiled/editor/MultipleChoiceToggle',
  'compiled/editor/EditorToggle',
  'compiled/str/TextHelper',
  'compiled/views/editor/KeyboardShortcuts',
  'INST', // safari sniffing for VO workarounds
  'quiz_formula_solution',
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/conditional_release/ConditionalRelease',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors, errorBox */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar, /\$\.underscore/ */,
  'jquery.instructure_misc_plugins' /* .dim, confirmDelete, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'supercalc' /* superCalc */,
  'vendor/jquery.placeholder' /* /\.placeholder/ */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(regradeTemplate, I18n,_,$,calcCmd, htmlEscape, pluralize,
            Handlebars, DueDateOverrideView, Quiz,
            DueDateList, QuizRegradeView, SectionList,
            MissingDateDialog,MultipleChoiceToggle,EditorToggle,TextHelper,
            RCEKeyboardShortcuts, INST, QuizFormulaSolution, RichContentEditor,
            ConditionalRelease){

  var dueDateList, overrideView, quizModel, sectionList, correctAnswerVisibility,
      scoreValidation;

  RichContentEditor.preloadRemoteModule();

  function adjustOverridesForFormParams(overrides){
    var idx = 0;
    var overridesLength = overrides.length;
    var _override = null;
    var dates = [ 'due_at', 'lock_at', 'unlock_at' ];
    // make sure we don't send the literal string "null" to the server.
    for (idx;idx< overridesLength;idx++){
      _override = overrides[idx]
      for (var date in dates) {
        var _date = dates[date];
        if (!dates.hasOwnProperty(date)) continue;
        if (_override[_date]) {
          if(_override[_date].toUTCString){
            _override[_date] = _override[_date].toUTCString();
          }
        } else {
          _override[_date] = "";
        }
      }
      // TODO: let the quiz API handle this.
      // The AssignmentOverride model can take care of these values.
      // See the automatically defined methods via self.override
      // in app/models/assignment_override.rb
      delete _override.unlock_at_overridden;
      delete _override.lock_at_overridden;
      delete _override.all_day_date;
      delete _override.due_at_overridden;
      delete _override.all_day;
    }
  }

  var isShowingResults = function() {
    return $('#never_hide_results').prop('checked');
  };

  var isShowingResultsJustOnce = function() {
    return $('#quiz_one_time_results').prop('checked');
  };

  var renderDueDates = function(){
    if (ENV.QUIZ && ENV.ASSIGNMENT_OVERRIDES != null) {

      ENV.QUIZ.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES;
      quizModel = new Quiz(ENV.QUIZ);

      sectionList = new SectionList(ENV.SECTION_LIST);

      dueDateList = new DueDateList(quizModel.get('assignment_overrides'),
                                    sectionList, quizModel);

      overrideView = window.overrideView = new DueDateOverrideView({
        el: '.js-assignment-overrides',
        model: dueDateList,
        views: {}
      });
      overrideView.render()
    }
  }.bind(this);

  var clickSetCorrect = I18n.t('titles.click_to_set_as_correct', "Click to set this answer as correct"),
      isSetCorrect = I18n.t('titles.set_as_correct', "This answer is set as correct"),
      clickUnsetCorrect = I18n.t('titles.click_to_unset_as_correct', "Click to unset this answer as correct"),
      correctAnswerLabel = I18n.t('labels.correct_answer', "Correct Answer"),
      possibleAnswerLabel = I18n.t('labels.possible_answer', "Possible Answer");

  function togglePossibleCorrectAnswerLabel($answers) {
    if(!$("#questions").hasClass('survey_quiz')){
      $answers.find('.select_answer label').text(possibleAnswerLabel);
      $answers.find('.select_answer input[name=answer_text]').attr("aria-label", possibleAnswerLabel);
      $answers.filter('.correct_answer').find(".select_answer label").text(correctAnswerLabel);
      $answers.filter('.correct_answer').find(".select_answer  input[name=answer_text]").attr("aria-label", correctAnswerLabel);
    }
  }

  function toggleSelectAnswerAltText($answers,type) {
    if (type != "multiple_answer") {
      $answers.find('.select_answer_link')
        .attr('title', clickSetCorrect)
        .find('img').attr('alt', clickSetCorrect);
      $answers.filter('.correct_answer').find('.select_answer_link')
        .attr('title', isSetCorrect)
        .find('img').attr('alt', isSetCorrect);
    } else {
      $answers.filter(".correct_answer").find('.select_answer_link')
        .attr('title', clickUnsetCorrect)
        .find('img').attr('alt', clickUnsetCorrect);
      $answers.filter(":not(.correct_answer)").find('.select_answer_link')
        .attr('title', clickSetCorrect)
        .find('img').attr('alt', clickSetCorrect);
    }
  }

  // TODO: refactor this... it's not going to be horrible, but it will
  // take a little bit of work.  I just wrapped it in a closure for now
  // to not pollute the global namespace, but it could use more.
  var quiz = window.quiz = {};
  quiz = {
    uniqueLocalIDStore: {},

    // Should cache any elements used throughout the object here
    init: function () {
      this.$questions = $('#questions');
      this.$showDetailsWrap = $('#show_question_details_wrap').hide();

      return this;
    },

    // Determines whether or not to show the "show question details" link.
    checkShowDetails: function() {
      var hasQuestions = this.$questions.find('div.display_question:not(.essay_question, .file_upload_question, .text_only_question)').length;
      this.$showDetailsWrap[hasQuestions ? 'show' : 'hide'](200);
    },

    generateUniqueLocalID: function($obj) {
      var className = "object";
      if ($obj.attr('class')) {
        if ($obj.attr('class').indexOf(' ') != -1) {
          className = $obj.attr('class').split(' ')[0];
        } else {
          className = $obj.attr('class');
        }
      }
      var number = Math.floor(Math.random() * 99999);
      var id = className + "_" + number;
      while(quiz.uniqueLocalIDStore[id]) {
        number = Math.floor(Math.random() * 99999);
        id = className + "_" + number;
      }
      quiz.uniqueLocalIDStore[id] = true;
      return id;
    },

    // Updates answer when the question's type changes
    updateFormAnswer: function($answer, data, ignoreCurrent) {
      var question_type = data.question_type;
      var currentData = ignoreCurrent ? {} : $answer.getFormData();
      var answer = $.extend({}, quiz.defaultAnswerData, currentData, data);

      $answer.find(".answer_type").hide().filter("." + answer.answer_type).show();
      answer.answer_weight = parseFloat(answer.answer_weight);

      if (isNaN(answer.answer_weight)) {
        answer.answer_weight = 0;
      }

      $answer.fillFormData(answer, {call_change: false});
      $answer.find('.select_answer input').showIf(!answer.answer_html);
      $answer.find('.matching_answer .answer_match_left').showIf(!answer.answer_match_left_html);
      $answer.find('.matching_answer .answer_match_left_html').showIf(answer.answer_match_left_html);

      if (answer.answer_comment || answer.answer_comment_html) {
        $answer.find(".answer_comments").removeClass('empty')
      }
      answer.answer_selection_type = answer.answer_selection_type || quiz.answerSelectionType(answer.question_type);

      var $answers = $answer.parent().find(".answer");
      if (answer.answer_selection_type == "any_answer") {
        $answer.addClass('correct_answer');
      } else if (answer.answer_selection_type == "matching") {
        $answer.removeClass('correct_answer');
      } else if (answer.answer_selection_type != "multiple_answer") {
        $answers.find(".answer").filter(".correct_answer").not(":first").removeClass('correct_answer');
        if ($answers.filter(".correct_answer").length === 0) {
          $answers.filter(":first").addClass('correct_answer');
        }
        toggleSelectAnswerAltText($answers,answer.answer_selection_type);
        togglePossibleCorrectAnswerLabel($answers);
      } else {
        toggleSelectAnswerAltText($answers,answer.answer_selection_type);
        togglePossibleCorrectAnswerLabel($answers);
      }

      numericalAnswerTypeChange($answer.find(".numerical_answer_type"))

      var templateData = {
        answer_text: answer.answer_text,
        id: answer.id,
        match_id: answer.match_id
      };
      templateData.comments_header = I18n.beforeLabel(I18n.t('labels.comments_on_answer', "Comments, if the user chooses this answer"));
      templateData.short_answer_header = I18n.beforeLabel(I18n.t('labels.possible_answer', "Possible Answer"));

      $answer.find(".comment_focus").attr('title', I18n.t('titles.click_to_enter_comments_on_answer', 'Click to enter comments for the student if they choose this answer'));

      if (question_type == "essay_question" || question_type == "file_upload_question") {
        templateData.comments_header = I18n.beforeLabel(I18n.t('labels.comments_on_question', "Comments for this question"));
      } else if (question_type == "matching_question") {
        templateData.answer_match_left_html = answer.answer_match_left_html;
        templateData.comments_header = I18n.beforeLabel(I18n.t('labels.comments_on_wrong_match', "Comments if the user gets this match wrong"));
        $answer.find(".comment_focus").attr('title', I18n.t('titles.click_to_enter_comments_on_wrong_match', 'Click to enter comments for the student if they miss this match'));
      } else if (question_type == "missing_word_question") {
        templateData.short_answer_header = I18n.beforeLabel(I18n.t('labels.answer_text', "Answer text"));
      } else if (question_type == "multiple_choice_question") {
        templateData.answer_html = answer.answer_html;
      } else if (question_type == "multiple_answers_question") {
        templateData.answer_html = answer.answer_html;
        templateData.short_answer_header = I18n.beforeLabel(I18n.t('labels.answer_text', "Answer text"));
      } else if (question_type == "fill_in_multiple_blanks_question") {
        templateData.blank_id = answer.blank_id;
      } else if (question_type == "multiple_dropdowns_question") {
        templateData.short_answer_header = I18n.t('answer_text', "Answer text");
        templateData.blank_id = answer.blank_id;
      }

      if (answer.blank_id && answer.blank_id != '0') {
        $answer.addClass('answer_for_' + answer.blank_id);
      }

      if (answer.blank_index >= 0) {
        $answer.addClass('answer_idx_' + answer.blank_index);
      }

      $answer.fillTemplateData({
        data: templateData,
        htmlValues: ['answer_html', 'answer_match_left_html']
      });

      addHTMLFeedback($answer.find('.answer_comments'), answer, 'answer_comment');

      if (answer.answer_weight > 0) {
        $answer.addClass('correct_answer');
        if (answer.answer_selection_type == "multiple_answer") {
          $answer.find('.select_answer_link')
            .attr('title', clickUnsetCorrect)
            .find('img').attr('alt', clickUnsetCorrect);
        }
      } else if (answer.answer_weight < 0) {
        $answer.addClass('negative_answer');
      }

      if (question_type == "matching_question") {
        $answer.removeClass('correct_answer');
      }

      // won't exist if they've never clicked the edit button
      var htmlToggle = $answer.find('.edit_html').data('editorToggle')

      var supportsHTMLAnswers = question_type === 'multiple_choice_question' || question_type === 'multiple_answers_question'
      if (htmlToggle && supportsHTMLAnswers) {
        // some answer types share the same text fields, so we show it
        htmlToggle.showAnswerText();
      } else if (htmlToggle) {
        // call display so the editor gets closed and we display the HTML next
        // time we're editing an answer type that supports HTML answers
        htmlToggle.display();
      }
    },

    questionContentCounter: 0,

    showFormQuestion: function($form) {
      if (!$form.attr('id')) {
        // we show and then hide the form so that the layout for the editor is computed correctly
        $form.show();
        $form.find(".question_content").attr('id', 'question_content_' + quiz.questionContentCounter++);
        RichContentEditor.loadNewEditor($form.find(".question_content"), {
          tinyOptions: {
            aria_label: I18n.t('label.question.instructions', 'Question instructions, rich text area')
          }
        })
        $form.find(".text_after_answers").attr('id', 'text_after_answers_' + quiz.questionContentCounter++);
        RichContentEditor.loadNewEditor($form.find(".text_after_answers"))
        $form.hide();
      }
      return $form.show();
    },

    answerTypeDetails: function(qt) {
      var answer_type, question_type, n_correct = "one";
      if (qt == 'multiple_choice_question') {
        answer_type = "select_answer";
        question_type = "multiple_choice_question";
      } else if (qt == 'true_false_question') {
        answer_type = "select_answer";
        question_type = "true_false_question";
      } else if (qt == 'short_answer_question') {
        answer_type = "short_answer";
        question_type = "short_answer_question";
        n_correct = "all";
      } else if (qt == 'fill_in_multiple_blanks_question') {
        answer_type = "short_answer";
        question_type = "fill_in_multiple_blanks_question";
        n_correct = "all";
      } else if (qt == 'essay_question') {
        answer_type = "comment";
        question_type = "essay_question";
        n_correct = "none";
      } else if (qt == 'file_upload_question') {
        answer_type = "comment";
        question_type = "file_upload_question";
        n_correct = "none";
      } else if (qt == 'matching_question') {
        answer_type = "matching_answer";
        question_type = "matching_question";
        n_correct = "all";
      } else if (qt == 'missing_word_question') {
        answer_type = "select_answer";
        question_type = "missing_word_question";
      } else if (qt == 'multiple_dropdowns_question') {
        answer_type = "select_answer";
        question_type = "multiple_dropdowns_question";
        n_correct = "multiple";
      } else if (qt == 'numerical_question') {
        answer_type = "numerical_answer";
        question_type = "numerical_question";
        n_correct = "all";
      } else if (qt == 'multiple_answers_question') {
        answer_type = "select_answer";
        question_type = "multiple_answers_question";
        n_correct = "multiple";
      } else if (qt == 'calculated_question') {
        answer_type = "numerical_answer";
        question_type = "question_question";
      }
      return {
        question_type: question_type,
        answer_type: answer_type,
        n_correct: n_correct
      };
    },

    answerSelectionType: function(question_type) {
      var result = "single_answer";
      if (question_type == 'multiple_choice_question') {
      } else if (question_type == 'true_false_question') {
      } else if (question_type == 'short_answer_question') {
        result = "any_answer";
      } else if (question_type == 'essay_question') {
        result = "none";
      } else if (question_type == 'file_upload_question') {
        result = "none";
      } else if (question_type == 'matching_question') {
        result = "matching";
      } else if (question_type == 'missing_word_question') {
      } else if (question_type == 'numerical_question') {
        result = "any_answer";
      } else if (question_type == 'calculated_question') {
        result = "any_answer";
      } else if (question_type == 'multiple_dropdowns_question') {
      } else if (question_type == 'fill_in_multiple_blanks_question') {
        result = "any_answer";
      } else if (question_type == 'multiple_answers_question') {
        result = "multiple_answer";
      } else if (question_type == "text_only_question") {
        result = "none";
      }
      return result;
    },

    addExistingQuestion: function(question) {
      var $group = $("#group_top_" + question.quiz_group_id);
      var $bottom = null;
      if ($group.length > 0) {
        $bottom = $group.next();
        while($bottom.length> 0 && !$bottom.hasClass('group_bottom')) {
          $bottom = $bottom.next();
        }
        if ($bottom.length == 0) { $bottom = null; }
      }
      $.extend(question, question.question_data);
      var $question = makeQuestion(question);
      $("#unpublished_changes_message").slideDown();
      if ($bottom) {
        $bottom.before($question);
      } else {
        $("#questions").append($question);
      }
      quiz.updateDisplayQuestion($question.find(".question:first"), question, true);
    },

    updateDisplayQuestion: function($question, question, escaped) {

      fillArgs = {
        data: question,
        except: ['answers'],
        htmlValues: ['correct_comments_html', 'incorrect_comments_html', 'neutral_comments_html']
      };

      if (escaped) {
        fillArgs['htmlValues'].push('question_text');
      } else {
        fillArgs['except'].push('question_text');
      }

      $question.fillTemplateData(fillArgs);
      $question.find(".original_question_text").fillFormData(question);
      $question.find(".answers").empty();
      $question.find(".equation_combinations").empty();
      $question.find(".equation_combinations_holder_holder").css('display', 'none');
      $question.find(".multiple_answer_sets_holder").css('display', 'none');
      $question.find(".variable_definitions_holder").css('display', 'none').find("tbody").empty();
      $question.find(".formulas_holder").css('display', 'none').find(".formulas_list").empty();
      $question.find('.question_points').text(question.points_possible);
      var details = quiz.answerTypeDetails(question.question_type);
      var answer_type = details.answer_type,
          question_type = details.question_type,
          n_correct = details.n_correct;

      $question.attr('class', 'question display_question').addClass(question_type || 'text_only_question');

      if (question.question_type == 'fill_in_multiple_blanks_question') {
        $question.find(".multiple_answer_sets_holder").css('display', '');
      } else if (question.question_type == 'multiple_dropdowns_question') {
        $question.find(".multiple_answer_sets_holder").css('display', '');
      }
      var $select = $(document.createElement("select")).addClass('answer_select');
      var hadOne = false;
      if (question.question_type == 'calculated_question') {
        $.each(question.variables, function(i, variable) {
          var $tr = $("<tr/>");
          var $td = $("<td class='name'/>");
          $td.text(variable.name);
          $tr.append($td);
          $td = $("<td class='min'/>");
          $td.text(variable.min);
          $tr.append($td);
          $td = $("<td class='max'/>");
          $td.text(variable.max);
          $tr.append($td);
          $td = $("<td class='scale'/>");
          $td.text(variable.scale);
          $tr.append($td);
          $question.find(".variable_definitions_holder").css('display', '');
          $question.find(".variable_definitions tbody").append($tr);
        });
        $.each(question.formulas, function(i, formula) {
          var $div = $("<div/>");
          $div.text(formula.formula);
          $question.find(".formulas_holder").css('display', '').find(".formulas_list").append($div);
        });
        $question.find(".formula_decimal_places").text(question.formula_decimal_places);
        if (question.answers.length > 0) {
          $question.find(".equation_combinations").append($("<thead/>"));
          $question.find(".equation_combinations").append($("<tbody/>"));
          var $tr = $("<tr/>");
          for(var idx in question.answers[0].variables) {
            var $th = $("<th/>");
            $th.text(question.answers[0].variables[idx].name);
            $tr.append($th);
          }
          var $th = $("<th/>");
          $th.text(I18n.t('final_answer', "Final Answer"));
          $tr.append($th);
          $question.find(".equation_combinations_holder_holder").css('display', '');
          $question.find(".equation_combinations thead").append($tr).show();
          $.each(question.answers, function(i, data) {
            var $tr = $("<tr/>");
            for(var idx in data.variables) {
              var $td = $("<td/>");
              $td.text(data.variables[idx].value);
              $tr.append($td);
            }
            var $td = $("<td class='final_answer'/>");
            var answerHtml = data.answer;
            if (question.answerDecimalPoints || question.answer_tolerance) {
              var tolerance = parseFloatOrPercentage(question.answer_tolerance);
              tolerance = tolerance || Math.pow(0.1, question.answerDecimalPoints);
              answerHtml = answerHtml + " <span style='font-size: 0.8em;'>+/-</span> " + htmlEscape(tolerance);
              $question.find(".answer_tolerance").text(tolerance);
            }
            $td.html(answerHtml);
            $tr.append($td);
            $question.find(".equation_combinations tbody").append($tr);
          });
        }
      } else {
        var $option = $(document.createElement('option'));
        $option.val("").text(I18n.t('choose_option', "[ Choose ]"));
        $select.append($option);
        $.each(question.answers, function(i, data) {
          data.answer_type = answer_type;
          if (n_correct == "all") {
            data.answer_weight = 100;
          } else if (n_correct == "one" && hadOne) {
            data.answer_weight = 0;
          } else if (n_correct == "none") {
            data.answer_weight = 0;
          }
          if (data.answer_weight > 0) { hadOne = true; }
          var $displayAnswer = makeDisplayAnswer(data, escaped);
          // must use > in selector
          $question.find(".text > .answers").append($displayAnswer);
          var $option = $(document.createElement("option"));
          $option.val("option_" + i).text(data.answer_text);
          $select.append($option);
        });
      }

      $question.find(".blank_id_select").empty();
      if (question.question_type == 'missing_word_question') {
        var $text = $question.find(".question_text");
        $text.html("<span class='text_before_answers'>" + $.raw(question.question_text) + "</span> ");
        $text.append($select);
        $text.append(" <span class='text_after_answers'>" + $.raw(question.text_after_answers) + "</span>");
      } else if (question.question_type == 'multiple_dropdowns_question' || question.question_type == 'fill_in_multiple_blanks_question') {
        var variables = {}
        $.each(question.answers, function(i, data) {
          variables[data.blank_id] = true;
        });
        $question.find(".blank_id_select").empty();
        for(var idx in variables) {
          var variable = idx;
          if (variable && variables[idx]) {
            var $option = $("<option/>");
            $option.val(variable).text(variable);
            $question.find(".blank_id_select").append($option);
          }
        }
      }
      $question.find(".after_answers").empty();
      if (question.question_type == 'matching_question') {
        var $text = $question.find(".after_answers");
        var split = [];
        if (question.matches && question.answers) {
          var correct_ids = {};
          for(var idx in question.answers) {
            correct_ids[question.answers[idx].match_id] = true;
          }
          for(var idx in question.matches) {
            if (!correct_ids[question.matches[idx].match_id]) {
              split.push(question.matches[idx].text);
            }
          }
        } else {
          var split = (question.matching_answer_incorrect_matches || "");
          if (typeof(split) == 'string') {
            split = split.split("\n");
          }
        }
        var codeHtml = "";
        for(var cdx in split) {
          if(split[cdx]) {
            codeHtml = codeHtml + "<li>" + htmlEscape(split[cdx]) + "</li>";
          }
        }

        if (codeHtml) {
          $text.append(htmlEscape(I18n.beforeLabel(I18n.t('labels.other_incorrect_matches', "Other Incorrect Match Options"))) + "<ul class='matching_answer_incorrect_matches_list'>" + codeHtml + "</ul>");
        }
      }
      $question.find(".blank_id_select").change();
      $question.fillTemplateData({
        question_type: question_type,
        answer_selection_type: answer_type
      });

      $question.show();
      var isNew = $question.attr('id') == "question_new";
      if (isNew) {
        if (question_type != "text_only_question") {
          quiz.defaultQuestionData.question_type = question_type;
          quiz.defaultQuestionData.answer_count = Math.min($question.find(".answers .answer").length, 4);
        }
      }
      $("html,body").scrollTo({top: $question.offset().top - 10, left: 0});
      $question.find(".question_points_holder").showIf(!$question.closest(".question_holder").hasClass('group') && question.question_type != 'text_only_question');
      $question.find(".unsupported_question_type_message").remove();
      quiz.updateDisplayComments();
      if (question.id) {
        var answers = question.answers;

        $question.fillTemplateData({
          data: {id: question.id},
          id: 'question_' + question.id,
          hrefValues: ['id']
        });

        $question.find(".original_question_text").fillFormData(question)
        quiz.updateDisplayComments();

        // We have to do the operations below to solve the problem of answer ids being overwritten by fillTemplateData
        if (answers) {
          $question.find('.answers .answer .hidden.id').each(function(index, answerEl){
            $(answerEl).text(answers[index].id);
          });

          $question.find('.answers .answer .id:not(.hidden)').each(function(index, answerEl){
            $(answerEl).text(answers[index].id);
          });
        }
      };
    },

    // Updates the question's form when the type changes
    updateFormQuestion: function($form) {
      var $formQuestion = $form.find(".question");
      var question_type = $formQuestion.find(":input[name='question_type']").val();
      var result = {};
      result.answer_type = "select_answer";
      result.answer_selection_type = quiz.answerSelectionType(question_type);
      result.textValues = ['answer_weight', 'answer_text', 'answer_comment', 'blank_id', 'id', 'match_id'];
      result.htmlValues = ['answer_html', 'answer_match_left_html', 'answer_comment_html'];
      result.question_type = question_type;

      var is_survey_quiz = $("#questions").hasClass('survey_quiz');
      if (is_survey_quiz && $formQuestion.find("." + question_type + "_survey_quiz_explanation").length > 0) {
        $formQuestion.find(".explanation").hide().filter("." + question_type + "_survey_quiz_explanation").show();
      } else {
        $formQuestion.find(".explanation").hide().filter("." + question_type + "_explanation").show();
      }

      $formQuestion.attr('class', 'question').addClass('selectable');
      $formQuestion.find(".missing_word_after_answer").hide().end()
        .find(".matching_answer_incorrect_matches_holder").hide().end()
        .find(".question_comment").css('display', '').end();
      if (is_survey_quiz) {
        $formQuestion.find(".question_comment").css('display', 'none').end()
          .find(".question_neutral_comment").css('display', '');
      }
      $formQuestion.find(".question_header").text(I18n.t('question_colon', "Question:"));
      $formQuestion.addClass(question_type);
        $formQuestion.find(".question_points_holder").showIf(!$formQuestion.closest(".question_holder").hasClass('group') && question_type != 'text_only_question');

      var options = {
        addable: true
      };

      limitTextInputFor($formQuestion, question_type);

      if (question_type == 'multiple_choice_question') {
      } else if (question_type == 'true_false_question') {
        options.addable = false;
        var $answers = $formQuestion.find(".form_answers .answer");
        if ($answers.length < 2) {
          for(var i = 0; i < 2 - $answers.length; i++) {
            var $answer = makeFormAnswer({ answer_type: "fixed_answer", question_type: "true_false_question" });
            $formQuestion.find(".form_answers").append($answer);
          }
        } else if ($answers.length > 2) {
          for(var i = 2; i < $answers.length; i++) {
            $answers.eq(i).remove();
          }
        }
        var answerOptions = {
          question_type: "true_false_question",
          answer_type: "fixed_answer",
          answer_text: I18n.t('true', "True")
        };
        quiz.updateFormAnswer($formQuestion.find(".answer:first"), answerOptions);
        answerOptions.answer_text = I18n.t('false', "False");
        quiz.updateFormAnswer($formQuestion.find(".answer:last"), answerOptions);
        result.answer_type = "fixed_answer";
      } else if (question_type == 'short_answer_question') {
        $formQuestion.removeClass('selectable');
        result.answer_type = "short_answer";
      } else if (question_type == 'essay_question' || question_type == 'file_upload_question') {
        $formQuestion.find(".answer").remove();
        $formQuestion.removeClass('selectable');
        $formQuestion.find(".answers_header").hide().end()
          .find(".question_comment").css('display', 'none').end()
          .find(".question_neutral_comment").css('display', '').end();
        options.addable = false;
        result.answer_type = "none";
        result.textValues = [];
        result.htmlValues = [];
      } else if (question_type == 'matching_question') {
        $formQuestion.removeClass('selectable');
        $form.find(".matching_answer_incorrect_matches_holder").show();
        result.answer_type = "matching_answer";
        result.textValues = ['answer_match_left', 'answer_match_right', 'answer_comment'];
      } else if (question_type == 'missing_word_question') {
        $form.find(".missing_word_after_answer").show();
        $form.find(".question_header").text("Text to go before answers:");
        result.answer_type = "select_answer";
      } else if (question_type == 'numerical_question') {
        $formQuestion.removeClass('selectable');
        result.answer_type = "numerical_answer";
        result.textValues = ['numerical_answer_type', 'answer_exact', 'answer_error_margin', 'answer_range_start', 'answer_range_end', 'answer_approximate', 'answer_precision'];
        result.html_values = [];
      } else if (question_type == 'calculated_question') {
        $formQuestion.removeClass('selectable');
        result.answer_type = "numerical_answer";
        result.textValues = ['answer_combinations'];
        result.html_values = [];
        $formQuestion.formulaQuestion();
      } else if (question_type == 'multiple_dropdowns_question') {
        result.answer_type = "select_answer";
        $formQuestion.multipleAnswerSetsQuestion();
      } else if (question_type == 'fill_in_multiple_blanks_question') {
        result.answer_type = "short_answer";
        $formQuestion.multipleAnswerSetsQuestion();
      } else if (question_type == 'multiple_answers_question') {
      } else if (question_type == "text_only_question") {
        options.addable = false;
        $formQuestion.find(".answer").remove();
        $formQuestion.removeClass('selectable');
        $formQuestion.find(".answers_header").hide().end()
          .find(".question_comment").css('display', 'none');
        $formQuestion.find(".question_header").text(I18n.beforeLabel(I18n.t('labels.message_text', "Message Text")));
        $form.find(":input[name='question_points']").val(0);
        result.answer_type = "none";
        result.textValues = [];
        result.htmlValues = [];
      }
      $formQuestion.find(".answer.hidden").remove();
      $form.find("input[name='answer_selection_type']").val(result.answer_selection_type).change();
      $form.find(".add_answer_link").showIf(options.addable);
      var $answers = $formQuestion.find(".form_answers .answer");
      if ($answers.length === 0 && result.answer_type != "none") {
        $formQuestion.find(".form_answers").append(makeFormAnswer({answer_type: result.answer_type, question_type: question_type}));
        $formQuestion.find(".form_answers").append(makeFormAnswer({answer_type: result.answer_type, question_type: question_type}));
        $answers = $formQuestion.find(".form_answers .answer");
      }
      if (result.answer_selection_type == "any_answer") {
        if (question_type == "short_answer_question") {
          $answers.addClass('fill_in_blank_answer');
        }
        $answers.addClass('correct_answer');
      } else if (result.answer_selection_type == "matching") {
        $answers.removeClass('correct_answer');
      } else if (result.answer_selection_type != "multiple_answer") {
        $answers.filter(".correct_answer").not(":first").removeClass('correct_answer');
        if ($answers.filter(".correct_answer").length === 0) {
          $answers.filter(":first").addClass('correct_answer');
        }
      }
      $form.find(".answer").each(function() {
        var weight = 0;
        if ($(this).hasClass('correct_answer')) {
          weight = 100;
        }
        $(this).find(".answer_weight").text(weight);
        quiz.updateFormAnswer($(this), result);
      });
      $form.find(".answer_type").hide().filter("." + result.answer_type).show();
      return result;
    },

    updateDisplayComments: function() {
      this.checkShowDetails();
      $(".question_holder > .question > .question_comment").each(function() {
        var val = $.trim($(this).find(".question_comment_text").html());
        $(this).css('display', '').toggleClass('empty', !val);
      });
      $(".question_holder .answer_comment_holder").each(function() {
        var val = $.trim($(this).find(".answer_comment").html());
        $(this).css('display', '').toggleClass('empty', !val);
      });
      var tally = 0;
      $("#questions .question_holder:not(.group) .question:not(#question_new)").each(function() {
        var val = parseFloat($(this).find(".question_points,.question_points.hidden").text());
        if (isNaN(val) || val < 0) { val = 0; }
        tally += val;
      });
      $("#questions .group_top:not(#group_top_new)").each(function(){
        var val = parseFloat($(this).find(".question_points").text());
        if (isNaN(val) || val < 0) { val = 0; }
        var pickCount = parseInt($(this).find(".pick_count").text(), 10);
        if (isNaN(pickCount)) { pickCount = 0; }
        var groupId = this.id.replace("group_top_","")
        questionCount = $(this.parentElement).find("[data-group-id='" + groupId + "']").length

        var $warning = $('#insufficient_count_warning_' + groupId);
        if (pickCount > ($(this).data('bank_question_count') || questionCount)) {
          $warning.show();
        } else {
          $warning.hide();
        }

        // unless it is a question bank, make sure
        // enough questions are in the group
        if(!$(this).hasClass("question_bank_top")){
          pickCount = Math.min(pickCount, questionCount)
        }

        tally += val * pickCount;
      });
      tally = Math.round(tally * 100.0) / 100.0;
      $(".points_possible").text(tally);
    },

    findContainerGroup: function($obj) {
      $obj = $obj.prev();
      while($obj.length > 0) {
        if ($obj.hasClass('group_top')) {
          return $obj;
        } else if ($obj.hasClass('group_bottom')) {
          return null;
        }
        $obj = $obj.prev();
      }
      return null;
    },

    parseInput: function($input, type) {
      if ($input.val() == "") { return; }

      var val = $input.val().replace(/,/g, '');

      if (type == "int") {
        val = parseInt(val, 10);
        if (isNaN(val)) { val = 0; }
      } else if (type == "float") {
        val = Math.round(parseFloat(val) * 100.0) / 100.0;
        if (isNaN(val)) { val = 0.0; }
      } else if (type == "float_long") {
        val = Math.round(parseFloat(val) * 10000.0) / 10000.0;
        if (isNaN(val)) { val = 0.0; }
      } else if (type == "precision") {
        // Parse value and force NaN to 0
        val = parseFloat(val)
        if (isNaN(val)) { val = 0.0; }

        // Round to precision 16 to handle floating point error
        val = val.toPrecision(16);

        // Truncate to specified precision
        var precision = arguments[2] || 10;
        if (precision < 16) {
          var precision_shift = Math.pow(10, precision - Math.floor(Math.log(val) / Math.LN10) - 1);
          val = Math.floor(val * precision_shift) / precision_shift;

          // Format
          val = val.toPrecision(precision)
        }
      }

      $input.val(val);
    },

    /*****
      Wrap parseInput with inforced range.

      Value of $input must be between min and max inclusive, if value falls out
      of the range it will be replaced with min or max respectively
    *****/
    parseInputRange: function($input, type, min, max) {
      this.parseInput($input, type);
      var val = $input.val();
      if (val < min) {
        $input.val(min);
      }
      if (val > max) {
        $input.val(max);
      }
    },

    validateAnswerTolerance: function($input) {
      var val = $input.val();
      if (val == "") { return; }
      $input.val( parseFloatOrPercentage(val) );
    },

    defaultQuestionData: {
      question_type: "multiple_choice_question",
      question_text: "",
      question_points: 1,
      question_name: I18n.t('default_question_name', "Question"),
      answer_count: 4
    },

    defaultAnswerData: {
      answer_type: "select_answer",
      answer_comment: "",
      answer_weight: 0,
      numerical_answer_type: "exact_answer",
      answer_exact: "",
      answer_error_margin: "",
      answer_range_start: "",
      answer_range_end: "",
      answer_approximate: "",
      answer_precision: "10"
    }
  };

  scoreValidation = {
    init: function() {
      this.initValidators.apply(this);

      $('#quiz_options_form').on('xhrError', this.onFormError);
    },

    initValidators: function() {
      $('input#quiz_points_possible')
        .on('invalid:not_a_number', function(e) {
          $(this).errorBox(I18n.t('errors.quiz_score_not_a_number', 'Score must be a number between 0 and 2,000,000,000.'));
        })
        .on('invalid:greater_than', function(e) {
          $(this).errorBox(I18n.t('errors.quiz_score_too_short', 'Score must be greater than 0.'));
        })
        .on('invalid:less_than', function(e) {
          $(this).errorBox(I18n.t('errors.quiz_score_too_long', 'Score must be less than 2,000,000,000.'));
        });
      $("input#quiz_points_possible").change(this.validatePoints);
    },

    validatePoints: function() {
      var value  = $("input#quiz_points_possible").val();
      var numVal = parseInt(value);

      if (value && isNaN(numVal)) {
        $("input#quiz_points_possible").trigger("invalid:not_a_number");
        valid = false;
      } else if (numVal > 2000000000) {
        $("input#quiz_points_possible").trigger("invalid:less_than");
        valid = false;
      } else if (numVal < 0) {
        $("input#quiz_points_possible").trigger("invalid:greater_than");
        valid = false;
      }
    },

    // Delegate the handling of "points_possible" errors
    onFormError: function(e, resp) {
      if (resp && resp.points_possible) {
        $("input#quiz_points_possible").triggerHandler("invalid:not_a_number");

        // Prevent $.fn.formErrors from giving error box with cryptic message.
        delete resp.points_possible;
      }
    }
  }

  ipFilterValidation = {
    init: function() {
      this.initValidators.apply(this);
      $('#quiz_options_form').on('xhrError', this.onFormError);
    },

    initValidators: function() {
      $('#quiz_ip_filter').on('invalid:ip_filter', function(e) {
        $(this).errorBox(I18n.t('IP filter is not valid.'));
      });
    },

    onFormError: function(e, resp) {
      if (resp && resp.invalid_ip_filter) {
        var event = 'invalid:ip_filter'
        $("#quiz_ip_filter").triggerHandler(event);
      }
      // Prevent $.fn.formErrors from giving error box with cryptic message.
      delete resp.invalid_ip_filter;
     }
  }


  correctAnswerVisibility = {
    $toggler: $(),
    $options: $(),
    $pickers: $(),

    /**
     * Build date pickers, and install handlers for show_correct_answers stuff when:
     *  - form is being serialized
     *  - form errors are thrown
     *  - related date fields change
     */
    init: function() {
      var that = correctAnswerVisibility;
      var $toggler = that.$toggler = $('#quiz_show_correct_answers');
      var $options = that.$options = $('#quiz_show_correct_answers_options');
      var $pickers = that.$pickers = $options.find('.date_field');

      $pickers.each(function() {
        var $field = $(this);
        var formattedDate = Handlebars.helpers.datetimeFormatted($field.val() || '');

        $field.val(formattedDate);
        $field.datetime_field();
      });

      $('#quiz_options_form')
        .on('xhrError', that.onFormError)
        .on('serializing', that.serialize);

      that.installValidators();
    },

    isOn: function() {
      return correctAnswerVisibility.$toggler.prop('checked');
    },

    /**
     * Install handlers for validating show_correct_answers (and related fields)
     * values, as well as error handlers for bad values that show friendly
     * error boxes.
     */
    installValidators: function() {
      var that = correctAnswerVisibility;

      that.$toggler.on('invalid:bad_range', function() {
        $('#quiz_hide_correct_answers_at').errorBox(
          I18n.t('errors.invalid_show_correct_answers_range',
          'Hide date cannot be before show date.'));

        return true;
      });

      that.$pickers.on('change', that.validateRange);
    },

    /**
     * Ensure that if both show_at and hide_at dates are specified, they form
     * a valid time range.
     *
     * @fires invalid:bad_range
     * @delegate #quiz_show_correct_answers
     */
    validateRange: function() {
      var that = correctAnswerVisibility;

      var $hide_at = that.$options.find('#quiz_hide_correct_answers_at');
      var $show_at = that.$options.find('#quiz_show_correct_answers_at');

      // Clear any existing error boxes
      that.$pickers.each(function() {
        var $errorBox = $(this).data('associated_error_box');

        if ($errorBox) {
          $errorBox.remove();
        }
      });

      if ($show_at.val().length && $hide_at.val().length) {
        if ($show_at.data().date >= $hide_at.data().date) {
          that.$toggler.triggerHandler('invalid:bad_range');
        }
      }
    },

    /**
     * Handle remote show_correct_answers errors by triggering the corresponding
     * events so the error handlers can pick them up.
     *
     * Side-effects:
     *
     * - `show_correct_answers` key will be deleted from the XHR response to prevent
     *   $.fn.formErrors from handling it.
     *
     * @param {jQuery} e XHR event.
     * @param {Object} resp XHR response.
     *
     * @fires invalid:bad_range
     * @delegate #quiz_show_correct_answers
     */
    onFormError: function(e, resp) {
      var that = correctAnswerVisibility;
      var i, errorEntry, event;

      // Delegate the handling of "show_correct_answers" errors to the handlers bound
      // to #quiz_show_correct_answers.
      if (resp && resp.show_correct_answers) {
        for (i = 0; i < resp.show_correct_answers.length; ++i) {
          errorEntry = resp.show_correct_answers[i];
          event = 'invalid:' + errorEntry.type.toLowerCase().replace(/\s/, '_');

          that.$toggler.triggerHandler(event);
        }

        // Prevent $.fn.formErrors from generating an error box with the API's
        // cryptic error message.
        delete resp.show_correct_answers;
      }
    },

    /**
     * Serialize the dates set for the visibility duration, if specified and
     * `hide_results` is enabled. If that's not enabled, nullify the values.
     *
     * @param  {jQuery} e     A jQuery event
     * @param  {Object} data  The form/XHR data.
     */
    serialize: function(e, data) {
      var showResults, showCorrectAnswers, showResultsOnce;
      var resetField = function(key, value) {
        data['quiz[' + key + ']'] = value || '';
      };
      var serializeField = function(key) {
        var $field = $('#quiz_' + key);
        var date;

        if ($field.val().length) {
          date = $field.data().date;
          data['quiz[' + key + ']'] = $.unfudgeDateForProfileTimezone(date).toISOString();
        } else {
          resetField(key);
        }
      };

      showResults = data['quiz[hide_results][never]'] != '0';
      showCorrectAnswers = data['quiz[show_correct_answers]'] == '1';
      showResultsOnce = data['quiz[one_time_results]'] == '1';

      if (showResults && showCorrectAnswers) {
        serializeField('show_correct_answers_at');
        serializeField('hide_correct_answers_at');
      } else {
        resetField('show_correct_answers', '0');
      }

      // Discard the showAt / hideAt dates if we're showing results only once,
      // or not at all:
      if (!showResults || !showCorrectAnswers || showResultsOnce) {
        resetField('show_correct_answers_at');
        resetField('hide_correct_answers_at');
      }

      // One time results doesn't apply if results are hidden in the first
      // place:
      if (!showResults) {
        resetField('one_time_results', '0');
      }
    },

    disable: function() {
      var that = correctAnswerVisibility;

      that.$toggler.prop('checked', false);
      that.showDatePickers(false);
    },

    // Totally show or hide the showAt/hideAt date pickers
    showDatePickers: function(isVisible) {
      correctAnswerVisibility.$options.toggle(isVisible);
    },

    // Keep the pickers visible, but enable or disable them
    enableDatePickers: function(isEnabled) {
      correctAnswerVisibility.$options
        .find('input.date_field, button.date_field')
        .prop('disabled', !isEnabled);
    }
  };

  function makeQuestion(data) {
    var idx = $(".question_holder:visible").length + 1;
    var question = $.extend({}, quiz.defaultQuestionData, {question_name: I18n.t('default_quesiton_name', "Question")}, data);
    var $question = $("#question_template").clone(true);
    $question.attr('id', '').find('.question').attr('id', 'question_new');
    $question.fillTemplateData({ data: question, except: ['answers'] });
    $question.find(".original_question_text").fillFormData(question);
    if (question.answers) {
      question.answer_count = question.answers.length;
      data.answer_type = question.answer_type;
      question.anwer_type = quiz.answerTypeDetails(question.question_type);
    }
    for(var i = 0; i < question.answer_count; i++) {
      var weight = i == 0 ? 100 : 0;
      var answer = { answer_weight: weight };
      if (question.answers && question.answers[i]) {
        $.extend(answer, question.answers[i]);
      }
      $question.find(".answers").append(makeDisplayAnswer(answer));
    }
    $question.toggleClass('group', !!(data && data.quiz_group_id));
    $question.show();
    return $question;
  }

  function makeDisplayAnswer(data, escaped) {
    data.answer_weight = data.weight || data.answer_weight;
    data.answer_comment = data.comments || data.answer_comment;
    data.answer_text = data.text || data.answer_text;
    data.answer_html = data.html || data.answer_html;
    data.answer_comment_html = data.comments_html || data.answer_comment_html;
    data.answer_match_left = data.left || data.answer_match_left;
    data.answer_match_left_html = data.left_html || data.answer_match_left_html;
    data.answer_match_right = data.right || data.answer_match_right;
    data.answer_exact = data.exact === undefined ? data.answer_exact : data.exact;
    data.answer_error_margin = data.answer_error_margin || data.margin;
    data.answer_range_start = data.start || data.answer_range_start;
    data.answer_range_end = data.end || data.answer_range_end;
    data.answer_approximate = data.approximate || data.answer_approximate;
    data.answer_precision = data.precision || data.answer_precision;

    var answer = $.extend({}, quiz.defaultAnswerData, data);
    var $answer = $("#answer_template").clone(true).attr('id', '');
    var answer_class = answer.answer_type;
    if (answer_class == "numerical_answer") {
      answer_class = "numerical_" + answer.numerical_answer_type;
    }
    $answer.addClass('answer_for_' + data.blank_id);
    $answer.find(".answer_type").hide().filter("." + answer_class).show();
    $answer.find('div.answer_text').showIf(!data.answer_html);
    $answer.find('div.answer_match_left').showIf(!data.answer_match_left_html);
    $answer.find('div.answer_match_left_html').showIf(data.answer_match_left_html);
    delete answer['answer_type'];
    answer.answer_weight = parseFloat(answer.answer_weight);
    if (isNaN(answer.answer_weight)) { answer.answer_weight = 0; }

    $answer.fillFormData({answer_text: answer.answer_text});
    $answer.fillTemplateData({data: answer, htmlValues: ['answer_html', 'answer_match_left_html', 'answer_comment_html']});

    if (!answer.answer_comment || answer.answer_comment == "" || answer.answer_comment == I18n.t('answer_comments', "Answer comments")) {
      $answer.find(".answer_comment_holder").hide();
    }

    if (answer.answer_weight == 100) {
      $answer.addClass('correct_answer');
    } else if (answer.answer_weight > 0) {
      $answer.addClass('correct_answer');
    } else if (answer.answer_weight < 0) {
      $answer.addClass('negative_answer');
    }

    $answer.show();
    return $answer;
  }

  function makeFormAnswer(data) {
    var answer = $.extend({}, quiz.defaultAnswerData, data);
    var $answer = $("#form_answer_template").clone(true).attr('id', '');
    $answer.find(".answer_type").hide().filter("." + answer.answer_type).show();
    answer.answer_weight = parseFloat(answer.answer_weight);

    if (isNaN(answer.answer_weight)) { answer.answer_weight = 0; }
    quiz.updateFormAnswer($answer, answer, true);
    $answer.find('input[placeholder]').placeholder();
    $answer.show();
    return $answer;
  }

  var REGRADE_DATA = {};
  var REGRADE_OPTIONS = ENV.REGRADE_OPTIONS || {};

  function quizData($question) {
    var $quiz = $("#questions");
    var quiz = {
      questions: [],
      points_possible: 0
    };
    var $list = $quiz.find(".question");
    if ($question) { $list = $question; }
    $list.each(function(i) {
      var $question = $(this);
      var questionData = $question.getTemplateData({
        textValues: ['question_name', 'question_points', 'question_type', 'answer_selection_type', 'assessment_question_id', 'correct_comments', 'incorrect_comments', 'neutral_comments', 'matching_answer_incorrect_matches', 'equation_combinations', 'equation_formulas', 'regrade_option'],
        htmlValues: ['question_text', 'text_before_answers', 'text_after_answers', 'correct_comments_html', 'incorrect_comments_html', 'neutral_comments_html']
      });
      questionData = $.extend(questionData, $question.find(".original_question_text").getFormData());
      questionData.assessment_question_bank_id = $(".question_bank_id").text() || "";
      if (questionData.text_before_answers) {
        questionData.question_text = questionData.text_before_answers;
      }
      var matches = [];
      $question.find(".matching_answer_incorrect_matches_list li").each(function() {
        matches.push($(this).text());
      });
      questionData.matching_answer_incorrect_matches = matches.join("\n");
      var question = $.extend({}, quiz.defaultQuestionData, questionData);
      question.answers = [];
      var blank_ids_hash = {};
      var only_add_for_blank_ids = false;
      if (question.question_type == "multiple_dropdowns_question" || question.question_type == "fill_in_multiple_blanks_question") {
        only_add_for_blank_ids = true;
        $question.find(".blank_id_select option").each(function() {
          blank_ids_hash[$(this).text()] = true;
        });
      }
      if (question.question_type != 'calculated_question') {
        // must use > in selector
        $question.find(".text > .answers .answer").each(function() {
          var $answer = $(this);
          var answerData = $answer.getTemplateData({
            textValues: ['answer_exact', 'answer_error_margin', 'answer_range_start', 'answer_range_end', 'answer_approximate', 'answer_precision', 'answer_weight', 'numerical_answer_type', 'blank_id', 'id', 'match_id', 'answer_text', 'answer_match_left', 'answer_match_right', 'answer_comment'],
            htmlValues: ['answer_html', 'answer_match_left_html', 'answer_comment_html']
          });
          var answer = $.extend({}, quiz.defaultAnswerData, answerData);
          if (only_add_for_blank_ids && answer.blank_id && !blank_ids_hash[answer.blank_id]) {
            return;
          }
          question.answers.push(answer);
        });
      } else {
        question.formulas = [];
        $question.find(".formulas_holder .formulas_list > div").each(function() {
          question.formulas.push($.trim($(this).text()));
        });
        question.variables = [];
        $question.find(".variable_definitions_holder .variable_definitions tbody tr").each(function() {
          var data = $(this).getTemplateData({textValues: ['name', 'min', 'max', 'scale']});
          question.variables.push(data);
        });
        question.answers = [];
        $question.find(".equation_combinations tbody tr").each(function() {
          var data = {};
          data.variables = [];
          $(this).find("td:not(.final_answer)").each(function(i) {
            var variable = {};
            variable.name = question.variables[i].name;
            variable.value = parseFloat($(this).text(), 10) || 0;
            data.variables.push(variable);
          });
          data.answer_text = parseFloat($(this).find(".final_answer").text(), 10) || 0;
          question.answers.push(data);
        });
        question.formula_decimal_places = parseInt($question.find(".formula_decimal_places").text(), 10) || 0;
        question.answer_tolerance = parseFloatOrPercentage($question.find(".answer_tolerance").text(), 10) || 0;
      }
      question.position = i;
      question.question_points = parseFloat(question.question_points);
      if (isNaN(question.question_points) || question.question_points < 0) {
        question.question_points = 0;
      }
      quiz.points_possible += question.question_points;
      quiz.questions.push(question);
    });
    return quiz;
  }

  function generateFormQuizQuestion(formQuiz) {
    var data = {};
    var quiz = formQuiz;
    if(quiz.questions.length > 0) {
      data["question"] = quiz.questions[0];
    }

    return data;
  }

  function generateFormQuiz(quiz) {
    var data = {
      quiz: {},
      questions: []
    };

    if (ENV.ASSIGNMENT_ID) {
      data.quiz.assignment_id = ENV.ASSIGNMENT_ID;
    }

    data.quiz.title = quiz.quiz_name;
    quiz.questions.forEach(function(question) {
      var q = {};
      q.question_name = question.question_name;
      q.assessment_question_id = question.assessment_question_id;
      q.question_type = question.question_type;
      q.points_possible = question.question_points;
      q.correct_comments_html = question.correct_comments_html;
      q.incorrect_comments_html = question.incorrect_comments_html;
      q.neutral_comments_html = question.neutral_comments_html;
      q.question_text = question.question_text;
      q.regrade_option = question.regrade_option;
      q.position = question.position;
      q.text_after_answers = question.text_after_answers;
      q.matching_answer_incorrect_matches = question.matching_answer_incorrect_matches;
      q.formulas = question.formulas;
      q.variables = question.variables;
      q.answer_tolerance = question.answer_tolerance;
      q.formula_decimal_places = question.formula_decimal_places;

      q.answers = question.answers;
      data.questions.push(q);
    });

    return data;

  }

  function addHTMLFeedback($container, question_data, name) {
    html = question_data[name+'_html'];
    if (!html || html.length == 0) {
      html = htmlEscape(question_data[name]);
      question_data[name+'_html'] = html;
    }
    if (html && html.length > 0) {
      $container.find('.'+name+'_html').html(html);
      $container.find('input[type="hidden"]').val(html);
      $container.removeClass('empty');
    }
  }

  var QUESTION_LIMIT = 1000;
  function questionLimitReached(inclusiveLimit) {
    if (!ENV.QUIZZES || !ENV.QUIZZES.QUIZ) return false; // quizzes have a limit, question banks do not

    var numQuestions = $('#questions .question_holder').not('.group').length;
    $('#questions .group_top').find('input[name="quiz_group[pick_count]"]').each(function() {
      numQuestions += parseInt(this.value);
    });
    if (inclusiveLimit ? (numQuestions > QUESTION_LIMIT) : (numQuestions >= QUESTION_LIMIT)) {
      setTimeout(function() {
        alert(I18n.t('question_limit_reached', 'You have reached the maximum number of questions allowed for a quiz (%{count}/%{limit}).\n\nAs a workaround, consider spreading the material across multiple quizzes.', {count: numQuestions, limit: QUESTION_LIMIT}))
      });
      return true;
    }
    return false;
  }

  function limitTextInputFor(form, question_type) {
    // Add character limit class
    if (question_type == 'missing_word_question' ||
        question_type == 'fill_in_multiple_blanks_question' ||
        question_type == 'short_answer_question')  {
      form.find("input[name='answer_text']").addClass("limit_text");
    } else {
      form.find("input[name='answer_text']").removeClass("limit_text");
    }
  }

  function parseFloatOrPercentage(val) {
    if (val == "") { return val; }
    var result;

    // percentage value
    if ((val + "").indexOf('%') === val.length - 1) {
      var number = val.replace("%", "");
      result = (Math.round(parseFloat(number) * 10000.0) / 10000.0) + "%";

    // point value
    } else if (!isNaN(val)) {
      result = Math.round(parseFloat(val) * 10000.0) / 10000.0;
      if (isNaN(result)) { result = 0.0; }

    } else {
      result = 0.0;
    }
    return result;
  }

  function toggleConditionalReleaseTab(quizType) {
    if (ENV['CONDITIONAL_RELEASE_SERVICE_ENABLED']) {
      if (quizType == "assignment") {
        $('#quiz_tabs').tabs("option", "disabled", false);
      } else {
        $('#quiz_tabs').tabs("option", "disabled", [2]);
      }
    }
  }

  $(document).ready(function() {
    quiz.init().updateDisplayComments();
    correctAnswerVisibility.init();
    scoreValidation.init();
    ipFilterValidation.init();
    renderDueDates();

    $('#quiz_tabs').tabs();
    $('#editor_tabs').show();

    var $quiz_options_form = $("#quiz_options_form");
    var $quiz_edit_wrapper = $("#quiz_edit_wrapper");
    $.scrollSidebar();
    $(".datetime_field").datetime_field();
    $("#questions").delegate('.group_top,.question,.answer_select,.comment', 'mouseover', function(event) {
      $(this).addClass('hover');
    }).delegate('.group_top,.question,.answer_select,.comment', 'mouseout', function(event) {
      $(this).removeClass('hover');
    });

    $("#questions").delegate('.answer', 'mouseover', function(event) {
      $("#questions .answer.hover").removeClass('hover');
      $(this).addClass('hover');
    });

    $quiz_options_form.find("#extend_due_at").change(function() {
      $("#quiz_lock_after").showIf($(this).attr('checked'));
    }).change();

    $quiz_options_form.find("#multiple_attempts_option").change(function(event) {
      $("#multiple_attempts_suboptions").showIf($(this).attr('checked'));
      var $text = $("#multiple_attempts_suboptions #quiz_allowed_attempts");

      if ($text.val() == '-1') {
        $text.val('1');
      }
    }).triggerHandler('change');

    $quiz_options_form.find("#time_limit_option").change(function(event, noFocus) {
      if (!$(this).attr('checked')) {
        $("#quiz_time_limit").val("");
      } else if (!noFocus) {
        $("#quiz_time_limit").focus();
      }
    }).triggerHandler('change', [true]);

    $("#limit_attempts_option").change(function(event, noFocus) {
      var $item = $("#quiz_allowed_attempts");
      if ($(this).attr('checked')) {
        var val = parseInt($item.data('saved_value') || $item.val() || "2", 10);
        if (val == -1 || isNaN(val)) {
          val = 1;
        }
        $item.val(val);
        if (!noFocus) { $item.focus(); }
      } else {
        $item.data('saved_value', $(this).val());
        $item.val('--');
      }
    }).triggerHandler('change', [true]);

    $('#enable_quiz_ip_filter, #enable_quiz_access_code').on('change', function() {
      var $checkbox = $(this);
      var $optionGroup = $checkbox.closest('.option-group');
      var checked = $checkbox.prop('checked');

      // All of this magic here is so that VoiceOver will properly navigate to
      // the inputs after they are shown.
      var $foundOptions = $optionGroup.find('> .options');
      if (checked) {
        $foundOptions.removeClass('screenreader-only');
        // We have to do this bit so keyboard only users aren't confused
        // when their focus goes to something shown offscreen.
        $foundOptions.find('[tabindex="-1"]').each(function (k,v) {
          $(v).attr('tabindex', 0);
        });
      } else {
        $foundOptions.addClass('screenreader-only');
        // Same as above
        $foundOptions.find('[tabindex="0"]').each(function (k,v) {
          $(v).attr('tabindex', -1);
        });
      }




      if (!checked) {
        $optionGroup
          .find('[type="text"]')
            .val('');
      }
    }).each(function() {
      $(this).triggerHandler('change');
    });

    $quiz_options_form.on('serializing', function(e, data) {
      var erratic = false;

      if ($('#enable_quiz_ip_filter').is(':checked')) {
        if (!data['quiz[ip_filter]']) {
          erratic = true;
          $('#quiz_ip_filter').errorBox(
            I18n.t('errors.missing_ip_filter', 'You must enter a valid IP Address')
          );
        }
      }

      if ($('#enable_quiz_access_code').is(':checked')) {
        if (!data['quiz[access_code]']) {
          erratic = true;
          $('#quiz_access_code').errorBox(
            I18n.t('errors.missing_access_code', 'You must enter an access code')
          );
        }
      }

      if (erratic) {
        e.preventDefault();
      }
    });

    $("#quiz_require_lockdown_browser").change(function() {
      $("#lockdown_browser_suboptions").showIf($(this).attr('checked'));
      $("#quiz_require_lockdown_browser_for_results").attr('checked', true).change();
    });

    $("#lockdown_browser_suboptions").showIf($("#quiz_require_lockdown_browser").attr('checked'));

    $("#ip_filters_dialog").delegate('.ip_filter', 'click', function(event) {
      event.preventDefault();
      var filter = $(this).getTemplateData({textValues: ['filter']}).filter;
      $("#protect_quiz").attr('checked', true).triggerHandler('change');
      $("#ip_filter").attr('checked', true).triggerHandler('change');
      $("#quiz_ip_filter").val(filter);
      $("#ip_filters_dialog").dialog('close');
    });

    $(".ip_filtering_link").click(function(event) {
      event.preventDefault();
      var $dialog = $("#ip_filters_dialog");
      $dialog.dialog({
        width: 400,
        title: I18n.t('titles.ip_address_filtering', "IP Address Filtering")
      });
      if (!$dialog.hasClass('loaded')) {
        $dialog.find(".searching_message").text(I18n.t('retrieving_filters', "Retrieving Filters..."));
        var url = ENV.QUIZ_IP_FILTERS_URL;
        $.ajaxJSON(url, 'GET', {}, function(data) {
          var ip_filters = data.quiz_ip_filters;
          var idx, filter, $filter;

          $dialog.addClass('loaded');

          if (ip_filters.length) {
            for (idx = 0; idx < ip_filters.length; ++idx) {
              filter = ip_filters[idx];
              $filter = $dialog.find(".ip_filter.blank:first").clone(true).removeClass('blank');
              $filter.fillTemplateData({data: filter});
              $dialog.find(".filters tbody").append($filter.show());
            }
            $dialog.find(".searching_message").hide().end()
              .find(".filters").show();
          } else {
            $dialog.find(".searching_message").text(I18n.t('no_filters_found', "No filters found"));
          }
        }, function(data) {
          $dialog.find(".searching_message").text(I18n.t('errors.retrieving_filters_failed', "Retrieving Filters Failed"));
        });
      }
    });

    $("#quiz_one_question_at_a_time").change(function() {
      var $this = $(this);
      $("#one_question_at_a_time_options").showIf($this.attr('checked'));
      if (!$this.attr('checked')) {
        $("#quiz_cant_go_back").attr('checked', false);
      }
    }).triggerHandler('change');

    $(".question").on("change", ".limit_text", function() {
      var answerValue = $(this).val();
      var textLength = answerValue.length;
      if(textLength > 80) {
        alert(I18n.t('quiz_short_answer_length_error', 'Answers for fill in the blank questions must be under 80 characters long'));
        $(this).val(answerValue.substring(0, 80));
      }
    });

    $("#multiple_attempts_option,#limit_attempts_option,#quiz_allowed_attempts").change(function() {
      var checked = $("#multiple_attempts_option").prop('checked') && $("#limit_attempts_option").prop('checked');
      if (checked) {
          $("#hide_results_only_after_last_holder").show();
          var $attempts = $('#quiz_allowed_attempts');
          var $attemptsVal = $attempts.val();
          if(isNaN($attemptsVal)) {
              alert(I18n.t('quiz_attempts_nan_error', 'Quiz attempts can only be specified in numbers'));
              $attempts.val("");
          } else if($attemptsVal.length > 3) {
              alert(I18n.t('quiz_attempts_length_error', 'Quiz attempts are limited to 3 digits, if you would like to give your students unlimited attempts, do not check Allow Multiple Attempts box to the left'));
              $attempts.val("");
          }
      } else {
        $("#hide_results_only_after_last").attr('checked', false);
        $("#hide_results_only_after_last_holder").hide();
      }
    }).triggerHandler('change');

    var hasCheckedOverrides = false;

    $quiz_options_form.formSubmit({
      object_name: "quiz",

      processData: function(data) {
        $(this).attr('method', 'PUT');
        var quiz_title = $("#quiz_title").val();
        if (quiz_title.length == 0) {
          var offset = $("#quiz_title").errorBox(I18n.t('errors.field_is_required', "This field is required")).offset();
          $('html,body').scrollTo({top: offset.top, left:0});
          return false;
        }
        data['quiz[title]'] = quiz_title;
        data['quiz[description]'] = RichContentEditor.callOnRCE($("#quiz_description"), 'get_code');
        if ($("#quiz_notify_of_update").is(':checked')) {
          data['quiz[notify_of_update]'] = $("#quiz_notify_of_update").val();
        }
        var attempts = 1;
        if (data.multiple_attempts) {
          attempts = parseInt(data.allowed_attempts, 10);
          if (isNaN(attempts) || !data.limit_attempts) { attempts = -1; }
        }
        data.allowed_attempts = attempts;
        data['quiz[allowed_attempts]'] = attempts;
        var overrides = overrideView.getOverrides();
        data['quiz[only_visible_to_overrides]'] = overrideView.containsSectionsWithoutOverrides();
        var validationData = {
          assignment_overrides: overrideView.getAllDates()
        };
        var errs = overrideView.validateBeforeSave(validationData,{});
        if (_.keys(errs).length > 0) {
          return false;
        }
        else if (overrideView.containsSectionsWithoutOverrides() && !hasCheckedOverrides) {
          sections = overrideView.sectionsWithoutOverrides();
          var missingDateView = new MissingDateDialog({
            validationFn: function(){ return sections },
            labelFn: function( section ) { return section.get('name')},
            success: function(){
              missingDateView.$dialog.dialog('close').remove();
              missingDateView.remove();
              hasCheckedOverrides = true;
              $quiz_options_form.trigger('submit');
            }
          });
          missingDateView.cancel = function() {
            missingDateView.$dialog.dialog('close').remove();
          };
          missingDateView.render();
          return false;
        } else {
          var finalQuiz = overrideView.getDefaultDueDate();
          if (finalQuiz) {
            finalQuiz = finalQuiz.toJSON().assignment_override;
            adjustOverridesForFormParams([finalQuiz]);
            data['quiz[due_at]'] = finalQuiz.due_at || ""
            data['quiz[unlock_at]'] = finalQuiz.unlock_at || "";
            data['quiz[lock_at]'] = finalQuiz.lock_at || "";
          }
          else {
            data['quiz[due_at]'] = "";
            data['quiz[unlock_at]'] = "";
            data['quiz[lock_at]'] = "";
          }
          adjustOverridesForFormParams(overrides);
          if (overrides.length === 0) { overrides = false; }
          data['quiz[assignment_overrides]'] = overrides;
        }

        var serializingEvent = $.Event('serializing');

        $(this).trigger(serializingEvent, data);

        if (serializingEvent.isDefaultPrevented()) {
          return false;
        }

        return data;
      },

      beforeSubmit: function(data) {
        $quiz_edit_wrapper.find(".btn.save_quiz_button").attr('disabled', true);
        $quiz_edit_wrapper.find(".btn.save_and_publish").attr('disabled', true);
      },

      success: function(data) {
        var $form = $(this);
        $quiz_edit_wrapper
          .find(".btn.saving")
          .text(I18n.t('buttons.saved', "Saved!"));
        if (data.quiz.assignment) {
          var assignment = data.quiz.assignment;
          if ($("#assignment_option_" + assignment.id).length === 0) {
            if (assignment.assignment_group && $("#assignment_group_optgroup_" + assignment.assignment_group_id).length === 0) {
              var assignment_group = assignment.assignment_group;
              var $optgroup = $(document.createElement('optgroup'));
              $optgroup.attr('label', assignment_group.name).attr('id', 'assignment_group_optgroup_' + assignment_group.id);
            }
            var $group = $("#assignment_group_optgroup_" + assignment.assignment_group_id);
            var $option = $(document.createElement('option'));
            $option.attr('id', 'assignment_option_' + assignment.id).val(assignment.id).text(assignment.title);
            $group.append($option);
          }
        }
        $(".show_rubric_link").showIf(data.quiz.assignment);
        $("#quiz_assignment_id").val(data.quiz.quiz_type || "practice_quiz").change();
        location.href = $(this).attr('action');
        quiz.updateDisplayComments();
      },
      error: function(data) {
        $("#quiz_edit_wrapper")
          .find(".btn.save_quiz_button")
          .attr('disabled', false)
          .removeClass("saving")
          .text(I18n.t('buttons.save', "Save"));
        $("#quiz_edit_wrapper")
          .find(".btn.save_and_publish")
          .attr('disabled', false)
          .removeClass("saving")
          .text(I18n.t('buttons.save_and_publish', "Save & Publish"));
        $("#quiz_edit_wrapper")
          .find('input[name="publish"]')
          .remove();

        $(this).trigger('xhrError', data);
        $(this).formErrors(data);
      }
    });

    $quiz_edit_wrapper.find(".save_quiz_button").click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      $quiz_edit_wrapper
        .find(".btn.save_quiz_button")
        .addClass("saving")
        .text(I18n.t('buttons.saving', "Saving..."));
      $quiz_options_form.data('submit_type', 'save_only').submit();
    }).end();

    $quiz_edit_wrapper.find(".save_and_publish").click(function(event) {
      event.preventDefault();
      event.stopPropagation();

      var $publish_input = $(document.createElement('input'));
      $publish_input.attr('type', 'hidden').attr('name', 'publish').attr('value', 'true');
      $quiz_options_form.append($publish_input);

      $quiz_edit_wrapper
        .find(".btn.save_and_publish")
        .addClass("saving")
        .text(I18n.t('buttons.saving', "Saving..."));
      $quiz_options_form.data('submit_type', 'save_only').submit();
    }).end();

    $("#show_question_details").change(function(event) {
      $("#questions").toggleClass('brief', !$(this).attr('checked'));
    }).triggerHandler('change');

    $(".start_over_link").click(function(event) {
      event.preventDefault();
      var result = confirm(I18n.t('confirms.scrap_and_restart', "Scrap this quiz and start from scratch?"));
      if (result) {
        location.href = location.href + "?fresh=1";
      }
    });

    $("#quiz_assignment_id").change(function(event) {
      var previousData = $("#quiz_options").getTemplateData({textValues: ['assignment_id', 'title']});
      var assignment_id = $("#quiz_assignment_id").val();
      var quiz_title = $("#quiz_title_input").val();
      if (assignment_id) {
        var select = $("#quiz_assignment_id")[0];
        quiz_title = $(select.options[select.selectedIndex]).text();
      } else if (previousData.assignment_id) {
        quiz_title = I18n.t('default_quiz_title', "Quiz");
      }
      var data = {
        'quiz[assignment_id]': assignment_id,
        'quiz[title]': quiz_title
      };
      $("#quiz_title").showIf(true);
      var gradedQuiz = event.target.value === "assignment" ||
                       event.target.value === "graded_survey";
      $("#post_to_sis_option").showIf(gradedQuiz);
      $("#quiz_options_form .quiz_survey_setting").showIf(assignment_id && assignment_id.match(/survey/));
      $("#quiz_points_possible").showIf(assignment_id == 'graded_survey');
      $("#survey_instructions").showIf(assignment_id == 'survey' || assignment_id == 'graded_survey');
      $("#quiz_assignment_group_id").closest('.control-group').showIf(assignment_id == 'assignment' || assignment_id == 'graded_survey');
      $("#questions").toggleClass('survey_quiz', assignment_id == 'survey' || assignment_id == 'graded_survey');
      $("#quiz_display_points_possible").showIf(assignment_id != 'survey' && assignment_id != 'graded_survey');
      $("#quiz_options_holder").toggleClass('survey_quiz', assignment_id == 'survey' || assignment_id == 'graded_survey');
      var url = $("#quiz_urls .update_quiz_url").attr('href');
      $("#quiz_title_input").val(quiz_title);
      $("#quiz_title_text").text(quiz_title);

      if (ENV['CONDITIONAL_RELEASE_SERVICE_ENABLED']) {
        toggleConditionalReleaseTab(event.target.value);
      }
    }).change();

    $(".question_form :input").keycodes("esc", function(event) {
      $(this).parents("form").find("input[value='" + I18n.t('#buttons.cancel', "Cancel") + "']").click();
    });

    $(document).delegate('.blank_id_select', 'change', function() {
      var variable = $(this).val();
      var idx = $(this)[0].selectedIndex;
      $(this).closest(".question").find(".answer").css('display', 'none');
      if (variable) {
        if (variable != '0') {
          $(this).closest(".question").find(".answer.answer_idx_" + idx).filter(":not(.answer_for_" + variable + ")").each(function() {
            $(this).attr('class', $(this).attr('class').replace(/answer_for_[A-Za-z0-9]+/g, ""));
            $(this).addClass('answer_for_' + variable);
          });
        }
        $(this).closest(".question").find(".answer.answer_for_" + variable).css('display', '');
      } else {
        $(this).closest(".question").find(".answer").css('display', '');
        $(this).closest(".question").find(".answer.answer_idx_" + idx).css('display', '');
      }
    });

    $(".blank_id_select").change();

    $(document).delegate(".delete_question_link", 'click', function(event) {
      event.preventDefault();
      $(this).parents(".question_holder").confirmDelete({
        url: $(this).parents(".question_holder").find(".update_question_url").attr('href'),
        message: I18n.t('confirms.delete_question', "Are you sure you want to delete this question?"),
        success: function(data) {
          $(this).remove();
          quiz.updateDisplayComments();
        }
      });
    });

    $(document).delegate(".edit_question_link", 'click', function(event) {
      event.preventDefault();
      var $question = $(this).parents(".question");
      setQuestionID($question);
      var questionID = $question.data("questionID")
      var question = $question.getTemplateData({
        textValues: ['question_type', 'correct_comments', 'incorrect_comments', 'neutral_comments',
                     'question_name', 'question_points', 'answer_selection_type', 'blank_id',
                     'matching_answer_incorrect_matches', 'regrade_option', 'regrade_disabled'],
        htmlValues: ['question_text', 'correct_comments_html', 'incorrect_comments_html', 'neutral_comments_html']
      });
      question.question_text = $question.find("textarea[name='question_text']").val();
      var matches = [];
      $question.find(".matching_answer_incorrect_matches_list li").each(function() {
        matches.push($(this).text());
      });

      question.matching_answer_incorrect_matches = matches.join("\n");
      question.question_points = parseFloat(question.question_points, 10);
      if (isNaN(question.question_points) || question.question_points < 0) { question.question_points = 0; }
      var $form = $("#question_form_template").clone(true).attr('id', '');
      var $formQuestion = $form.find(".question");
      $formQuestion.addClass('initialLoad');
      $form.fillFormData(question);
      $formQuestion.removeClass('initialLoad');
      addHTMLFeedback($form.find(".question_correct_comment"), question, 'correct_comments');
      addHTMLFeedback($form.find(".question_incorrect_comment"), question, 'incorrect_comments');
      addHTMLFeedback($form.find(".question_neutral_comment"), question, 'neutral_comments');

      $formQuestion.addClass('selectable');
      $form.find(".answer_selection_type").change().show();
      if (question.question_type != 'missing_word_question') { $form.find("option.missing_word").remove(); }

      if ($question.hasClass('missing_word_question') || question.question_type == 'missing_word_question') {
        question = $question.getTemplateData({textValues: ['text_before_answers', 'text_after_answers']});
        answer_data = $question.find(".original_question_text").getFormData();
        question.text_before_answers = answer_data.question_text;
        question.text_after_answers = answer_data.text_after_answers;
        question.question_text = question.text_before_answers;
        $form.fillFormData(question);
      }

      var data = quiz.updateFormQuestion($form);
      $form.find(".form_answers").empty();
      if (data.question_type == 'calculated_question') {
        var question = quizData($question).questions[0];
        $form.find(".combinations_holder .combinations thead tr").empty();
        for(var idx in question.variables) {
          var $var = $($form.find(".variables .variable." + question.variables[idx].name));
          if (question.variables[idx].name == 'variable') {
            $var = $($form.find(".variables .variable").get(idx));
          }
          if ($var && $var.length > 0) {
            $var.find(".min").val(question.variables[idx].min);
            $var.find(".max").val(question.variables[idx].max);
            $var.find(".round").val(question.variables[idx].scale);
          }
          var $th = $("<th/>");
          $th.text(question.variables[idx].name);
          $th.attr('id', 'possible_solution_' + question.variables[idx].name);
          $form.find(".combinations_holder .combinations thead tr").append($th);
        }
        var $th = $("<th class='final_answer'/>");
        $th.text(I18n.t('final_answer', "Final Answer"));
        $th.attr('id', 'possible_solution_final');
        $form.find(".combinations_holder .combinations thead tr").append($th);
        for(var idx in question.formulas) {
          $form.find(".supercalc").val(question.formulas[idx]);
          $form.find(".decimal_places .round").val(question.formula_decimal_places);
          $form.find(".save_formula_button").click();
        }
        if (question.answer_tolerance) {
          $form.find(".combination_answer_tolerance").val(question.answer_tolerance);
        }
        $form.find(".combination_count").val(question.answers.length);
        for(var idx in question.answers) {
          var $tr = $("<tr/>");
          for(var jdx in question.answers[idx].variables) {
            var $td = $("<td/>");
            $td.text(question.answers[idx].variables[jdx].value);
            $td.attr('aria-labelledby', 'possible_solution_' + question.answers[idx].variables[jdx].name);
            $tr.append($td);
          }
          var html = question.answers[idx].answer_text;
          if (question.answer_tolerance) {
            html = html + " <span style='font-size: 0.8em;'>+/-</span> " + htmlEscape(question.answer_tolerance);
          }
          var $td = $("<td class='final_answer'/>");
          $td.html(html);
          $td.attr('aria-labelledby', 'possible_solution_final');
          $tr.append($td);
          $form.find(".combinations tbody").append($tr);
          $form.find(".combinations_holder").show();
        }
        $form.triggerHandler('settings_change', false);
        $formQuestion.triggerHandler('recompute_variables', true);
      } else {
        // must use > in selector
        $question.find(".text > .answers .answer").each(function() {
          var answer = $(this).getTemplateData({
            textValues: data.textValues,
            htmlValues: data.htmlValues
          });
          answer.answer_type = data.answer_type;
          answer.question_type = data.question_type;
          var $answer = makeFormAnswer(answer);
          $form.find(".form_answers").append($answer);
        });
      }
      if ($question.hasClass('essay_question') || $question.hasClass('file_upload')) {
        $formQuestion.find(".comments_header").text(I18n.beforeLabel(I18n.t('labels.comments_on_question', "Comments for this question")));
      }

      limitTextInputFor($form, question.question_type);

      $question.hide().after($form);
      quiz.showFormQuestion($form);
      $form.attr('action', $question.find(".update_question_url").attr('href'))
        .attr('method', 'POST')
        .find('.submit_button').text(I18n.t('buttons.update_question', 'Update Question'));
      $form.find(":input:visible:first").focus().select();
      $("html,body").scrollTo({top: $form.offset().top - 10, left: 0});
      setTimeout(function() {
        $formQuestion.find(".question_content").triggerHandler('change');
        $formQuestion.addClass('ready');
      }, 100);

      // show regrade options if question was changed but quiz not saved
      var $question  = $form.find(".question");
      setQuestionID($question)
      var questionID = $question.data("questionID")

      if (REGRADE_OPTIONS[questionID]) {
        var regradeOption = $(QuizRegradeView.prototype.template()).find('input[value='+REGRADE_OPTIONS[questionID]+']')
        var newAnswer = $form.find('.correct_answer')
        toggleAnswer($question, {regradeOption: regradeOption, newAnswer: newAnswer})
      }
      toggleSelectAnswerAltText($(".form_answers .answer"), quiz.answerSelectionType(question.question_type))
      togglePossibleCorrectAnswerLabel($(".form_answers .answer"));
    });

    $(".question_form :input[name='question_type']").change(function() {
      quiz.updateFormQuestion($(this).parents(".question_form"));

      // is this the initial loado of the question type
      var loading = $(this).parents(".question.initialLoad").length > 0;
      var holder = $(this).parents('.question_holder');
      var isNew = $(holder).find("#question_new").length > 0;
      if ($("#student_submissions_warning").length > 0 && !loading && !isNew) {
        disableRegrade(holder);
      }
    });

    $("#question_form_template .cancel_link").click(function(event) {
      event.preventDefault();
      var $displayQuestion = $(this).parents("form").prev();

      var isNew = $displayQuestion.attr('id') == 'question_new';
      if (!isNew) {
        $(this).parents("form").remove();
      }
      $displayQuestion.show();
      $("html,body").scrollTo({top: $displayQuestion.offset().top - 10, left: 0});
      if (isNew) {
        $displayQuestion.parent().remove();
        quiz.updateDisplayComments();
      }
      quiz.updateDisplayComments();
    });

    $(document).delegate("a.comment_focus", 'click', function(event) {
      event.preventDefault();
      var $link = $(this);
      var $comment = $link.closest('.question_comment, .answer_comments');
      var $comment_html = $comment.find('.comment_html');

      var toggler = $comment.data('editorToggle');

      // create toggler instance on the first click
      if (!toggler) {
        var inputColumn = $comment.parents().find('.answer_type:visible')[0]

        var rightMargin = parseInt($comment.css('marginRight')) || 0
        var leftMargin = parseInt($comment.css('marginLeft')) || 0
        var commentMargin = rightMargin + leftMargin

        var rceWidth = inputColumn.offsetWidth - commentMargin

        toggler = new EditorToggle($comment_html, {
          editorBoxLabel: $link.title,
          tinyOptions: {width: rceWidth}
        });

        toggler.editButton = $link;
        toggler.on('display', function() {

          $comment.removeClass('editing');

          var html = $comment_html.html();
          $comment.find('input[type="hidden"]').val(html);
          if (html == '') {
            $comment.addClass('empty');
          }
        });
        $comment.data('editorToggle', toggler);
      }

      if (!toggler.editing) {
        $comment.removeClass('empty');
        $comment.addClass('editing');
        toggler.edit();
      }

    });

    $(document).delegate(".numerical_answer_type", 'change', function(){
      numericalAnswerTypeChange($(this))
    }).change();

    $(document).delegate(".select_answer_link", 'click', function(event) {
      event.preventDefault();

      var $question = $(this).parents(".question");
      if (!$question.hasClass('selectable')) { return; }
      setQuestionID($question)
      var questionID = $question.data("questionID")

      if (!REGRADE_DATA[questionID]){
        REGRADE_DATA[questionID] = correctAnswerIDs($question);
      }

      updateAnswers($question, $(this).parents('.answer'));
    });

    function updateAnswers($question, newAnswer) {
      var holder = $question.parents('.question_holder');
      var isNew = holder.find("#question_new").length > 0;
      if(isNew ||
        !canRegradeQuestion($question) ||
        !$("#student_submissions_warning").length > 0) {
        toggleAnswer($question, {newAnswer: newAnswer, regradeOption: null});
      }
      else {
        var isDisabled = holder.find('input[name="regrade_disabled"]').val() == '1';
        var questionType = $question.find(".question_type").val();
        var regradeOptions = new QuizRegradeView({
          question: $question,
          regradeDisabled: isDisabled,
          regradeOption: REGRADE_OPTIONS[$question.data("questionID")],
          multipleAnswer: questionType === "multiple_answers_question"
        });
        regradeOptions.on('update', function(regradeOption){
          newAnswerData = {regradeOption: regradeOption, newAnswer: newAnswer}
          toggleAnswer($question, newAnswerData)
        })
      }
    }

    function toggleAnswer($question, newAnswerData) {
      $answer = $(newAnswerData.newAnswer);
      $answers = $answer.parent().find(".answer");

      if ($question.find(":input[name='question_type']").val() != "multiple_answers_question") {
        $question.find(".answer:visible").removeClass('correct_answer')
          .find('.select_answer_link').attr('title', clickSetCorrect)
          .find('img').attr('alt', clickSetCorrect)
        setAnswerText(newAnswerData.newAnswer, isSetCorrect);
        $answer.addClass('correct_answer');
        togglePossibleCorrectAnswerLabel($answers);
      }
      else {
        $answer.toggleClass('correct_answer');
        var answerText = $answer.hasClass('correct_answer') ? clickUnsetCorrect : clickSetCorrect;
        setAnswerText(newAnswerData.newAnswer, answerText);
        togglePossibleCorrectAnswerLabel($answers);
      }
      if(!newAnswerData.regradeOption) { return; }
      updateRegradeOption($question, newAnswerData)
    }

    function updateRegradeOption($question, newAnswerData) {
      var option = newAnswerData.regradeOption
      var optionText = option.next('span');
      REGRADE_OPTIONS[$question.data("questionID")] = option.val();
      $question.find("."+optionText.attr('class')).remove();
      $(newAnswerData.newAnswer).append(htmlEscape(option.next('span')));
      $(newAnswerData.newAnswer).parents('.answer').append(htmlEscape(optionText));
      option.hide();
      $question.append(htmlEscape(option));
    }

    function setAnswerText(answer, text) {
      $(answer)
        .attr('title', text)
        .find('img').attr('alt', text)
    }

    function setQuestionID(question){
      var questionID = $(question).closest('.question_holder')
                        .find('.display_question').attr('id')
                        .replace("question_", "");
      question.data({"questionID": questionID})
    }

    function canRegradeQuestion($el) {
      var regradeTypes = ["multiple_choice_question",
                          "true_false_question",
                          "multiple_answers_question"];
      return _.find(regradeTypes, function(className) {
        return $el.hasClass(className);
      })
    }

    function disableRegrade(holder) {
      holder.find('.regrade_enabled').hide();
      holder.find('.regrade_disabled').show();
      holder.find('input[name="regrade_option"]').attr('disabled', true);
      holder.find('input[name="regrade_option"]').attr('checked', false);
      holder.find('input[name="regrade_disabled"]').val('1');
    }

    function disableQuestionForm() {
      $('.question_form').find(".submit_button")
        .attr('disabled', true)
        .addClass('disabled')
        .removeClass('button_primary btn-primary');
    }

    function enableQuestionForm() {
      $('.question_form').find(".submit_button")
        .removeClass('disabled')
        .removeAttr('disabled')
        .addClass('button_primary btn-primary');
    }

    function correctAnswerIDs($el){
      var answers = [];
      $el.find('.answer').each(function(index) {
        if ($(this).hasClass('correct_answer')) answers.push(index);
      });
      return answers;
    }

    function answersAreTheSameAsBefore($el) {
      setQuestionID($el);
      var questionID = $el.data("questionID");

      // we don't know 'old answers' if they've updated and returned
      if (REGRADE_OPTIONS[questionID]) {
        return false;

      } else {
        var oldAnswers = REGRADE_DATA[questionID];
        var newAnswers = correctAnswerIDs($el);

        return oldAnswers.length == newAnswers.length &&
               !_.difference(oldAnswers, newAnswers).length;
      }
    }

    $(".question_form :input").change(function() {
      if ($(this).parents(".answer").length > 0) {
        var $answer = $(this).parents(".answer");
        $answer.find(":input[name='" + $(this).attr('name') + "']").val($(this).val());
      }
    });

    $(".question_form select.answer_selection_type").change(function() {
      if ($(this).val() == "single_answer") {
        $(this).parents(".question").removeClass('multiple_answers');
      } else {
        $(this).parents(".question").addClass('multiple_answers');
      }
    }).change();

    $(".delete_answer_link").click(function(event) {
      event.preventDefault();

      var holder = $(this).parents('.question_holder');
      var regradeOpt = holder.find('span.regrade_option');

      // warn they can't regrade if there are submissions
      var disabled = regradeOpt.text() == 'disabled';
      var isNew = holder.find("#question_new").length > 0;
      if ($("#student_submissions_warning").length > 0 && !disabled && !isNew) {
        var msg = I18n.t('confirms.delete_answer',
          "Are you sure? Deleting answers from a question with submissions " +
          "disables the option to regrade this question.")
        if (!confirm(msg)) { return; }

        // disabled regrade if they've chosen already
        disableRegrade(holder);
        enableQuestionForm();
      }

      var $ans = $(this).parents(".answer");
      var $ansHeader = $ans.closest('.question').find('.answers_header');
      $(".errorBox").not("#error_box_template").remove();
      $ans.remove();
      $ansHeader.focus();
    });

    $(".add_question_group_link").click(function(event) {
      event.preventDefault();
      if (questionLimitReached()) return;
      $(".question_form .submit_button:visible,.quiz_group_form .submit_button:visible").each(function() {
        $(this).parents("form").submit();
      });
      var $group_top = $("#group_top_template").clone(true).attr('id', 'group_top_new');
      var $group_bottom = $("#group_bottom_template").clone(true).attr('id', 'group_bottom_new');
      $("#questions").append($group_top.show()).append($group_bottom.show());
      $group_top.find(".edit_group_link").click();
      $group_top.find(".quiz_group_form").attr('action', $("#quiz_urls .add_group_url").attr('href'))
        .attr('method', 'POST');
      $group_top.find(".submit_button").text(I18n.t('buttons.create_group', "Create Group"));
    });

    $(".add_question_link").click(function(event) {
      event.preventDefault();
      if (questionLimitReached()) return;
      $(".question_form:visible,.group_top.editing .quiz_group_form:visible").submit();
      var $question = makeQuestion();
      if ($(this).parents(".group_top").length > 0) {

        groupID = $(this).parents(".group_top")[0].id.replace("group_top_","")
        $($question[0]).attr("data-group-id", groupID)

        var $bottom = $(this).parents(".group_top").next();
        while($bottom.length > 0 && !$bottom.hasClass('group_bottom')) {
          $bottom = $bottom.next();
        }
        $bottom.before($question.addClass('group'));
      } else {
        $("#questions").append($question);
      }
      $question.find(".edit_question_link:first").click();
      var $form = $question.parents(".question_holder").children("form");
      $form.attr('action', $("#quiz_urls .add_question_url,#bank_urls .add_question_url").attr('href'))
        .attr('method', 'POST')
        .find(".submit_button").text(I18n.t('buttons.create_question', "Create Question"));
      $form.find("option.missing_word").remove();
      $question.find(".question_type").change();
      $("html,body").scrollTo({top: $question.offset().top - 10, left: 0});
      $question.find(":input:first").focus().select();
    });

    quiz.$questions.delegate('.group_top input[name="quiz_group[pick_count]"]', {
      focus: function() {
        $(this).data('prev-value', this.value);
      },
      change: function() {
        if (questionLimitReached(true)) {
          this.value = $(this).data('prev-value');
        }
      }
    });

    var $findBankDialog = $("#find_bank_dialog");

    $(".find_bank_link").click(function(event) {
      event.preventDefault();
      var $dialog = $findBankDialog;
      $dialog.data('form', $(this).closest(".quiz_group_form"));
      if (!$dialog.hasClass('loaded')) {
        $dialog.data('banks', {});
        $dialog.find(".find_banks").hide();
        $dialog.find(".message").show().text(I18n.t('loading_question_banks', "Loading Question Banks..."));
        var url = $dialog.find(".find_question_banks_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(banks) {
          $dialog.find(".message").hide();
          $dialog.find(".find_banks").show();
          $dialog.addClass('loaded');
          for(idx in banks) {
            var bank = banks[idx].assessment_question_bank;
            bank.title = TextHelper.truncateText(bank.title)
            var $bank = $dialog.find(".bank.blank:first").clone(true).removeClass('blank');
            $bank.fillTemplateData({data: bank, dataValues: ['id', 'context_type', 'context_id']});
            $dialog.find(".bank_list").append($bank);
            $bank.data('bank_data', bank);
            $bank.show();
          }
        }, function(data) {
          $dialog.find(".message").text(I18n.t('errors.loading_banks_failed', "Question Banks failed to load, please try again"));
        });
      }
      $dialog.find(".bank.selected").removeClass('selected');
      $dialog.find(".submit_button").attr('disabled', true);
      $dialog.dialog({
        title: I18n.t('titles.find_question_bank', "Find Question Bank"),
        width: 600,
        height: 400
      });
    });

    $findBankDialog.delegate('.bank', 'click', function() {
      $findBankDialog.find(".bank.selected").removeClass('selected');
      $(this).addClass('selected');
      $findBankDialog.find(".submit_button").attr('disabled', false);
    }).delegate('.submit_button', 'click', function() {
      var $bank = $findBankDialog.find(".bank.selected:first");
      var bank = $bank.data('bank_data');
      var $form = $findBankDialog.data('form');
      $form.find(".bank_id").val(bank.id);
      bank.bank_name = bank.title;
      var $formBank = $form.closest('.group_top').next(".assessment_question_bank")
      if ($formBank.length == 0) {
        $formBank = $("#group_top_template").next(".assessment_question_bank").clone(true);
        $form.closest('.group_top').after($formBank);
      }
      $formBank.show()
        .fillTemplateData({data: bank}).data('bank_data', bank);
      $findBankDialog.dialog('close');
    }).delegate('.cancel_button', 'click', function() {
      $findBankDialog.dialog('close');
    });

    var $findQuestionDialog = $("#find_question_dialog");

    $(".find_question_link").click(function(event) {
      event.preventDefault();
      var $dialog = $findQuestionDialog;
      if (!$dialog.hasClass('loaded')) {
        $dialog.data('banks', {});
        $dialog.find(".side_tabs_table").hide();
        $dialog.find(".message").show().text(I18n.t('loading_question_banks', "Loading Question Banks..."));
        var url = $dialog.find(".find_question_banks_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(banks) {
          $dialog.find(".message").hide();
          $dialog.find(".side_tabs_table").show();
          $dialog.addClass('loaded');
          for(idx in banks) {
            var bank = banks[idx].assessment_question_bank;
            bank.title = TextHelper.truncateText(bank.title)
            var $bank = $dialog.find(".bank.blank:first").clone(true).removeClass('blank');
            $bank.fillTemplateData({data: bank});
            $dialog.find(".bank_list").append($bank);
            $bank.data('bank_data', bank);
            $bank.show();
          }
          $dialog.find(".bank:not(.blank):first").click();
        }, function(data) {
          $dialog.find(".message").text(I18n.t('errors.loading_banks_failed', "Question Banks failed to load, please try again"));
        });
      }
      $dialog.data('add_source', '');
      $dialog.dialog({
        title: I18n.t('titles.find_quiz_question', "Find Quiz Question"),
        open: function() {
          if ($dialog.find(".selected_side_tab").length == 0) {
            $dialog.find(".bank:not(.blank):first").click();
          }
        },
        width: 600,
        height: 400
      });
    });

    var updateFindQuestionDialogQuizGroups = function(id) {
      var groups = [];
      $findQuestionDialog.find(".quiz_group_select").find("option.group").remove();
      $findQuestionDialog.find(".quiz_group_select_holder").show();
      $("#questions .group_top:visible").each(function() {
        var group = {};
        group.id = $(this).attr('id').substring(10);
        group.name = $(this).getTemplateData({textValues: ['name']}).name;
        var $option = $("<option/>");
        $option.text(TextHelper.truncateText(group.name));
        $option.val(group.id);
        $option.addClass('group');
        $findQuestionDialog.find(".quiz_group_select option.bottom").before($option);
      });
      if (id) {
        $("#quiz_group_select").val(id);
      }
      if ($("#quiz_group_select").val() == "new") {
        $("#quiz_group_select").val("none");
      }
      $("#quiz_group_select").change();
    }

    $("#quiz_group_select").change(function() {
      if ($(this).val() == "new") {
        var $dialog = $("#add_question_group_dialog");
        var question_ids = [];
        $findQuestionDialog.find(".question_list :checkbox:checked").each(function() {
          question_ids.push($(this).parents(".found_question").data('question_data').id);
        });
        $dialog.find(".questions_count").text(question_ids.length);
        $dialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.create_group', "Create Group"));
        $dialog.dialog({
          width: 400
        });
      }
    });

    $("#add_question_group_dialog .submit_button").click(function(event) {
      var $dialog = $("#add_question_group_dialog");
      $dialog.find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('buttons.creating_group', "Creating Group..."));

      var params = $dialog.getFormData();
      var newParams = {};
      _.each(params, function(val, key) {
        newParams[key.replace('quiz_group[', 'quiz_groups[][')] = val;
      });

      var url = $dialog.find(".add_question_group_url").attr('href');
      $.ajaxJSON(url, 'POST', newParams, function(data) {
        $dialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.create_group', "Create Group"));

        var $group_top = $("#group_top_template").clone(true).attr('id', 'group_top_new');
        var $group_bottom = $("#group_bottom_template").clone(true).attr('id', 'group_bottom_new');
        $("#questions").append($group_top.show()).append($group_bottom.show());
        var groups = data.quiz_groups;
        var group = groups[0];
        $group_top.fillTemplateData({
          data: group,
          id: 'group_top_' + group.id,
          hrefValues: ['id']
        });
        $group_top.fillFormData(data, {object_name: 'quiz_group'});
        $("#unpublished_changes_message").slideDown();
        $group_bottom.attr('id', 'group_bottom_' + group.id);
        quiz.updateDisplayComments();

        updateFindQuestionDialogQuizGroups(group.id);
        $dialog.dialog('close');
      }, function(data) {
        $dialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('errors.creating_group_failed', "Create Group Failed, Please Try Again"));
      });
    });

    $("#add_question_group_dialog .cancel_button").click(function(event) {
      $("#add_question_group_dialog").dialog('close');
      $("#quiz_group_select").val("none");
    });

    var showQuestions = function(questionData) {
      var questionList = questionData.questions;
      var $bank = $findQuestionDialog.find(".bank.selected_side_tab");
      var bank = $bank.data('bank_data');
      var bank_data = $findQuestionDialog.data('banks')[bank.id];
      if (!$bank.hasClass('selected_side_tab')) { return; }
      var existingIDs = {};
      $(".display_question:visible").each(function() {
        var id = $(this).getTemplateData({textValues: ['assessment_question_id']}).assessment_question_id;
        if (id) {
          existingIDs[id] = true;
        }
      });
      $findQuestionDialog.find(".page_link").showIf(bank_data.pages && bank_data.last_page && bank_data.pages > bank_data.last_page);
      updateFindQuestionDialogQuizGroups();
      var $div = $("<div/>");
      for(var idx in questionList) {
        var question = questionList[idx].assessment_question;
        if (!existingIDs[question.id] || true) {
          $div.html(question.question_data.question_text);
          question.question_text = TextHelper.truncateText($div.text(), {max: 75});
          question.question_name = question.question_data.question_name;
          var $question = $findQuestionDialog.find(".found_question.blank").clone(true).removeClass('blank');
          $question.toggleClass('already_added', !!existingIDs[question.id]);
          $question.fillTemplateData({data: question});
          $question.find(":checkbox").attr('id', 'find_bank_question_' + question.id);
          $question.find("label").attr('for', 'find_bank_question_' + question.id);
          $question.data('question_data', question);
          $findQuestionDialog.find(".question_list").append($question);
          $question.show();
        }
      }
    };

    $("#find_question_dialog").delegate('.bank', 'click', function(event) {
      event.preventDefault();
      var id = $(this).getTemplateData({textValues: ['id']}).id;
      var data = $findQuestionDialog.data('banks')[id];
      $findQuestionDialog.find(".bank").removeClass('selected');
      $findQuestionDialog.find(".selected_side_tab").removeClass('selected_side_tab');
      $(this).addClass('selected_side_tab');
      $findQuestionDialog.find(".page_link").data('page', 0);
      if (data && data.last_page) {
        $findQuestionDialog.find(".page_link").data('page', data.last_page);
      }
      if (!data) {
        $findQuestionDialog.find(".found_question:visible").remove();
        $findQuestionDialog.find(".page_link").click();
        $findQuestionDialog.find(".question_list_holder").hide();
        $findQuestionDialog.find(".question_message").show().text(I18n.t('loading_questions', "Loading Questions..."));
      } else {
        $findQuestionDialog.find(".found_question:visible").remove();
        showQuestions(data);
      }
    }).delegate('.page_link', 'click', function(event) {
      event.preventDefault();
      var $link = $(this);
      if ($link.hasClass('loading')) { return; }
      $link.addClass('loading');
      $findQuestionDialog.find(".page_link").text(I18n.t('loading_more_questions', "loading more questions..."));
      var $bank = $findQuestionDialog.find(".bank.selected_side_tab");
      var bank = $bank.data('bank_data');
      var url = $findQuestionDialog.find(".question_bank_questions_url").attr('href');
      url = $.replaceTags(url, 'question_bank_id', bank.id);
      var page = ($findQuestionDialog.find(".page_link").data('page') || 0) + 1;
      url += "&page=" + page;
      $.ajaxJSON(url, 'GET', {}, function(data) {
        $link.removeClass('loading');
        $findQuestionDialog.find(".page_link").data('page', page);
        $findQuestionDialog.find(".page_link").text(I18n.t('more_questions', "more questions"));
        var questions = data.questions;
        var banks = $findQuestionDialog.data('banks') || {};
        var bank_data = banks[bank.id] || {};
        bank_data.pages = data.pages;
        bank_data.questions = (bank_data.questions || []).concat(data.questions);
        bank_data.last_page = page;
        banks[bank.id] = bank_data;
        $findQuestionDialog.data('banks', banks);
        $findQuestionDialog.find(".question_message").hide();
        $findQuestionDialog.find(".question_list_holder").show();
        showQuestions(data);
      }, function(data) {
        $link.removeClass('loading');
        $findQuestionDialog.find(".question_message").text(I18n.t('errors.loading_questions_failed', "Questions failed to load, please try again"));
        $findQuestionDialog.find(".page_link").text(I18n.t('errors.loading_more_questions_failed', "loading more questions failed"));
      });
    }).delegate('.select_all_link', 'click', function(event) {
      event.preventDefault();
      $findQuestionDialog.find(".question_list .found_question:not(.blank) :checkbox").attr('checked', true);
    }).delegate('.clear_all_link', 'click', function(event) {
      event.preventDefault();
      $findQuestionDialog.find(".question_list .found_question:not(.blank) :checkbox").attr('checked', false);
    }).delegate('.cancel_button', 'click', function(event) {
      $findQuestionDialog.dialog('close');
    }).delegate('.group_button', 'click', function(event) {
      var $dialog = $("#add_found_questions_as_group_dialog");
      var question_ids = [];
      $findQuestionDialog.find(".question_list :checkbox:checked").each(function() {
        question_ids.push($(this).parents(".found_question").data('question_data').id);
      });
      $dialog.find(".questions_count").text(question_ids.length);
      $dialog.dialog({
        autoOpen: false,
        title: I18n.t('titles.add_questions_as_group', "Add Questions as a Group")
      });
    }).delegate('.submit_button', 'click', function(event) {
      var question_ids = [];
      $findQuestionDialog.find(".question_list :checkbox:checked").each(function() {
        question_ids.push($(this).parents(".found_question").data('question_data').id);
      });
      var params = {};
      params.quiz_group_id = $findQuestionDialog.find(".quiz_group_select").val();
      params.assessment_question_bank_id = $findQuestionDialog.find(".bank.selected_side_tab:first").data('bank_data').id;
      params.assessment_questions_ids = question_ids.join(',');
      params.existing_questions = '1';
      var url = $findQuestionDialog.find(".add_questions_url").attr('href');
      $findQuestionDialog.find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('buttons.adding_questions', "Adding Questions..."));
      $.ajaxJSON(url, 'POST', params, function(question_results) {
        $findQuestionDialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.add_selected_questions', "Add Selected Questions"));
        $findQuestionDialog.find(".selected_side_tab").removeClass('selected_side_tab');
        var counter = 0;
        function nextQuestion() {
          counter++;
          var question = question_results.shift();
          if (question) {
            quiz.addExistingQuestion(question);
            if (counter > 5) {
              setTimeout(nextQuestion, 50);
            } else {
              nextQuestion();
            }
          }
        }
        setTimeout(nextQuestion, 10);
        $findQuestionDialog.dialog('close');
      }, function(data) {
        $findQuestionDialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('errors.adding_questions_failed', "Adding Questions Failed, please try again"));
      });
    });

    $(".add_answer_link").bind('click', function(event, skipFocus) {
      event.preventDefault();
      var $question = $(this).parents(".question");
      var answers = [];
      var answer_type = null, question_type = null, answer_selection_type = "single_answer";
      if ($question.hasClass('multiple_choice_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "select_answer";
        question_type = "multiple_choice_question";
      } else if ($question.hasClass('true_false_question')) {
        return;
      } else if ($question.hasClass('short_answer_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "short_answer";
        question_type = "short_answer_question";
        answer_selection_type = "blanks";
      } else if ($question.hasClass('essay_question')) {
        var answers = [{
          comments: I18n.t('default_response_to_essay', "Response to show student after they submit an answer")
        }];
        answer_type = "comment";
        question_type = "essay_question";
      } else if ($question.hasClass('file_upload_question')) {
        var answers = [{
          comments: I18n.t('default_response_to_file_upload', "Response to show student after they submit an answer")
        }];
        answer_type = "comment";
        question_type = "file_upload_question";
      } else if ($question.hasClass('matching_question')) {
        var answers = [{
          comments: I18n.t('default_comments_on_wrong_match', "Response if the user misses this match")
        }];
        answer_type = "matching_answer";
        question_type = "matching_question";
        answer_selection_type = "matching";
      } else if ($question.hasClass('missing_word_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "short_answer";
        question_type = "missing_word_question";
      } else if ($question.hasClass('numerical_question')) {
        var answers = [{
          numerical_answer_type: "exact_answer",
          answer_exact: "#",
          answer_error_margin: "#",
          answer_precision: "10",
          comments: I18n.t('default_answer_comments_on_match', "Response if the student matches this answer")
        }];
        answer_type = "numerical_answer";
        question_type = "numerical_question";
        answer_selection_type = "any_answer";
      } else if ($question.hasClass('multiple_answers_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "select_answer";
        question_type = "multiple_answers_question";
        answer_selection_type = "multiple_answers";
      } else if ($question.hasClass('multiple_dropdowns_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "select_answer";
        question_type = "multiple_dropdowns_question";
      } else if ($question.hasClass('fill_in_multiple_blanks_question')) {
        var answers = [{
          comments: I18n.t('default_answer_comments', "Response if the student chooses this answer")
        }];
        answer_type = "short_answer";
        question_type = "fill_in_multiple_blanks_question";
        answer_selection_type = "blanks";
      }
      for(var i = 0; i < answers.length; i++) {
        var answer = answers[i];
        answer.answer_type = answer_type;
        answer.question_type = question_type;
        answer.blank_id = $question.find(".blank_id_select").val();
        answer.blank_index = $question.find(".blank_id_select")[0].selectedIndex;
        $answer = makeFormAnswer(answer);
        if (answer_selection_type == "any_answer") {
          $answer.addClass('correct_answer');
        } else if (answer_selection_type == "blanks") {
          $answer.addClass("correct_answer");
          $answer.addClass("fill_in_blank_answer");
        } else if (answer_selection_type == "matching") {
          $answer.removeClass('correct_answer');
        }
        $question.find(".form_answers").append($answer.show());
        if (!skipFocus) {
          $("html,body").scrollTo($answer);
          $answer.find(":text:visible:first").focus().select();
        }
      }
    });

    $(document).delegate(".answer_comment_holder", 'click', function(event) {
      $(this).find(".answer_comment").slideToggle();
    });

    $("#question_form_template").submit(function(event) {
      event.preventDefault();
      event.stopPropagation();
      var $displayQuestion = $(this).prev();
      var $form = $(this);
      $(".errorBox").not("#error_box_template").remove();
      var $answers = $form.find(".answer");
      var $question = $(this).find(".question");
      var answers = [];

      // save any open html answers or comments
      $form.find('.edit_html_done').trigger('click');
      var questionData = $question.getFormData({
        textValues: ['question_type', 'question_name', 'question_points', 'correct_comments', 'incorrect_comments', 'neutral_comments',
          'question_text', 'answer_selection_type', 'text_after_answers', 'matching_answer_incorrect_matches',
          'regrade_option', 'regrade_disabled'],
        htmlValues: ['correct_comments_html', 'incorrect_comments_html', 'neutral_comments_html']
      });

      if (questionData.question_points && questionData.question_points < 0) {
        $form.find("input[name='question_points']").errorBox(I18n.t('question.positive_points', "Must be zero or greater"));
        return;
      }

      questionData.assessment_question_bank_id = $(".question_bank_id").text() || ""
      var error_text = null;
      if (questionData.question_type == 'calculated_question') {
        if ($form.find(".combinations_holder .combinations tbody tr").length === 0) {
          error_text = I18n.t('errors.no_possible_solution', "Please generate at least one possible solution");
        }
      } else if ($answers.length === 0 || $answers.filter(".correct_answer").length === 0) {
        if ($answers.length === 0 && !_.contains(["essay_question", "file_upload_question", "text_only_question"], questionData.question_type)) {
          error_text = I18n.t('errors.no_answer', "Please add at least one answer");
        } else if ($answers.filter(".correct_answer").length === 0 && (questionData.question_type == "multiple_choice_question" || questionData.question_type == "true_false_question" || questionData.question_tyep == "missing_word_question")) {
          error_text = I18n.t('errors.no_correct_answer', "Please choose a correct answer");
        }
      } else if (questionData.question_type == "fill_in_multiple_blanks_question" || questionData.question_type == "short_answer_question") {
        function checkForNotBlanks(elements) {
          return elements.filter(function(i,element) {
            return !!element.value;
          }).length;
        }
        if (questionData.question_type == "fill_in_multiple_blanks_question") {
          var $variables = $form.find(".blank_id_select > option");
          $variables.each(function(i, answer_blank) {
            var blankCount = 0;
            $answers.filter(".answer_idx_" + i).each(function(i, element) {
              var $validInputs = $(element).find( $("input[name='answer_text']")).not(".disabled_answer");
              if (checkForNotBlanks($validInputs) > 0) {blankCount += 1;}
            });
            if (blankCount == 0) {error_text = I18n.t("Please add at least one non-blank answer for each variable.");}
          });
        } else {
          var $validAnswers = $answers.filter("div[class*='answer_for_none'], div[class*='answer_idx_'], div.fill_in_blank_answer");
          var $validInputs = $validAnswers.find( $("input[name='answer_text']")).not(".disabled_answer");
          if (checkForNotBlanks($validInputs) == 0) {
            error_text = I18n.t("Please add at least one non-blank answer.");
          }
        }
      }

      var isNotSurvey = $('#quiz_assignment_id').length == 0 || !$('#quiz_assignment_id').val().match(/survey/i);
      if (isNotSurvey && error_text) {
        $form.find(".answers_header").errorBox(error_text, true);
        return;
      }
      var question = $.extend({}, questionData);
      question.points_possible = parseFloat(question.question_points);
      question.answers = [];

      $displayQuestion.find(".blank_id_select").empty();
      var blank_ids_hash = {};
      var only_add_for_blank_ids = false;
      if (question.question_type == "multiple_dropdowns_question" || question.question_type == "fill_in_multiple_blanks_question") {
        only_add_for_blank_ids = true;
        $question.find(".blank_id_select option").each(function() {
          blank_ids_hash[$(this).text()] = true;
        });
      }

      $question.find(".blank_id_select option").each(function() {
        $displayQuestion.find(".blank_id_select").append($(this).clone());
      });

      var $answers = $question.find(".answer").each(function(i) {
        var $answer = $(this);
        $answer.show();
        var data = $answer.getFormData();
        data.id = $answer.find('.id').text();
        data.blank_id = $answer.find(".blank_id").text();
        data.answer_text = $answer.find("input[name='answer_text']:visible").val();
        data.answer_html = $answer.find(".answer_html").html();
        if (questionData.question_type == "true_false_question") {
          data.answer_text = $answer.find(".fixed_answer .answer_text").text();
          if (data.answer_text.length == 0) {
            data.answer_text = (i == 0) ? I18n.t('true', "True") : I18n.t('false', "False");
          }
        }
        if ($answer.hasClass('correct_answer')) {
          data.answer_weight = 100;
        } else {
          data.answer_weight = 0;
        }
        if (only_add_for_blank_ids && data.blank_id && !blank_ids_hash[data.blank_id]) {
          return;
        }
        question.answers.push(data);
      });
      if ($question.hasClass('calculated_question')) {
        question.answers = [];
        question.variables = [];
        var sorts = {};
        $question.find(".variables .variable").each(function(i) {
          var data = {};
          data.scale = "0";
          data.name = $(this).find(".name").text();
          data.scale = parseFloat($(this).find(".round").val(), 10) || 0;
          data.min = parseFloat($(this).find(".min").val(), 10) || 0;
          data.max = parseFloat($(this).find(".max").val(), 10) || 0;
          sorts[data.name] = i;
          question.variables.push(data);
        });
        question.formulas = [];
        $question.find(".formulas .formula").each(function() {
          var data = {}
          data.formula = $.trim($(this).text());
          question.formulas.push(data);
        });
        question.formula_decimal_places = parseInt($question.find(".decimal_places .round").val(), 10) || 0;
        question.answer_tolerance = parseFloatOrPercentage($question.find(".combination_answer_tolerance").val());
        question.answerDecimalPoints = parseFloat($question.find(".combination_error_margin").val(), 10) || 0;
        var $ths = $question.find(".combinations thead th");
        $question.find(".combinations tbody tr").each(function() {
          var data = {};
          data.variables = [];
          data.answer = parseFloat($(this).find("td.final_answer").text(), 10) || 0;
          $(this).find("td:not(.final_answer)").each(function(i) {
            var variable = {};
            variable.name = $.trim($ths.eq(i).text());
            variable.value = parseFloat($(this).text(), 10) || 0;
            data.variables.push(variable);
          });
          data.variables = data.variables.sort(function(a, b) {
            return sorts[a.name] - sorts[b.name];
          });
          question.answers.push(data);
        });
      }

      quiz.updateDisplayQuestion($displayQuestion, question);

      var details = quiz.answerTypeDetails(question.question_type);
      var answer_type = details.answer_type, question_type = details.question_type, n_correct = details.n_correct;

      $form.remove();
      $("html,body").scrollTo({top: $displayQuestion.offset().top - 10, left: 0});
      var url = $("#quiz_urls .add_question_url,#bank_urls .add_question_url").attr('href');
      var method = 'POST';
      var isNew = $displayQuestion.attr('id') == "question_new";
      if (!isNew) {
        url = $displayQuestion.find(".update_question_url").attr('href');
        method = 'PUT';
      }
      var oldQuestionData = questionData;
      var questionData = quizData($displayQuestion);
      var formData = generateFormQuiz(questionData);
      var questionData = generateFormQuizQuestion(formData);

      var disabled = oldQuestionData.regrade_disabled == '1';
      var regradeOpt = disabled ? 'disabled' : oldQuestionData.regrade_option;
      questionData['question[regrade_option]'] = regradeOpt;

      if ($displayQuestion.parent(".question_holder").hasClass('group')) {
        var $group = quiz.findContainerGroup($displayQuestion.parent(".question_holder"));
        if ($group) {
          questionData['question[quiz_group_id]'] = $group.attr('id').substring(10);
        }
      }
      if ($("#assessment_question_bank_id").length > 0) {
        questionData['assessment_question[assessment_question_bank_id]'] = $("#assessment_question_bank_id").text();
      }
      $displayQuestion.loadingImage();
      quiz.updateDisplayComments();
      $.ajaxJSON(url, method, questionData, function(data) {
        $displayQuestion.loadingImage('remove');
        $displayQuestion.find('.question_name').focus();

        var questionData = data;

        // questionData.assessment_question_id might be null now because
        // question.question_data.assessment_quesiton_id might be null but
        // question.assessment_question_id is the right value. because $.extend
        // overwrites all keys that exist even if they have null values.  this
        // is hacky, the better thing to do is just get the right thing back
        // from the server.  it matters because the form when you click "find
        // questions" uses it to see if the question already exists in this
        // quiz, and is vital to properly move/copy it to another question bank
        questionData.assessment_question_id = questionData.assessment_question_id || question.assessment_question_id || question.id || questionData.id;
        quiz.updateDisplayQuestion($displayQuestion, questionData, true);
        // Trigger a custom 'saved' event for catching and responding to change
        // after save process completed. Used in quizzes_bundle.coffee
        $displayQuestion.trigger('saved');
        $("#unpublished_changes_message").slideDown();
        if (question && questionData && questionData.id) {
          REGRADE_OPTIONS[questionData.id] = question.regrade_option;
          delete REGRADE_DATA['question_' + questionData.id];
        }
      }, function(data) {
        $displayQuestion.formErrors(data);
      });
    });

    $("#sort_questions").sortable({
      revert: false,
      update: function(event, ui) {
        var ids = $(this).sortable('toArray');
        for(var idx in ids) {
          var id = ids[idx];
          if (id && id != "sort_question_blank") {
            $("#" + id.substring(5)).appendTo($("#questions"));
          }
        }
      }
    });

    $(document).delegate("input.float_value", 'keydown', function(event) {
      if (event.keyCode > 57 && event.keyCode < 91 && event.keyCode != 69) {
        event.preventDefault();
      }
    }).delegate('input.float_value', 'change blur focus', function(event) {
      var $el = $(this)

      if ($el.hasClass('long')) {
        quiz.parseInput($el, 'float_long');
      } else if ($el.hasClass('precision')) {
        quiz.parseInput($el, 'precision', $el.siblings('.precision_value').val());
      } else {
        quiz.parseInput($el, 'float');
      }
    });

    $(document).delegate("input.precision_value", 'keydown', function(event) {
      // unless movement key || '0' through '9' || '-' || '+'
      if (event.keyCode > 57 && event.keyCode != 189 && event.keyCode != 187) {
        event.preventDefault();
      }
    }).delegate('input.precision_value', 'change blur focus', function(event) {
      var $el = $(this);
      quiz.parseInputRange($el, 'int', 1, 16);
      $el.siblings('.float_value.precision').change();
    });

    $(document).delegate("input.combination_answer_tolerance", 'keydown', function(event) {
      if (!event.metaKey && event.keyCode > 57 && event.keyCode < 91) {
        event.preventDefault();
      }
    }).delegate('input.combination_answer_tolerance', 'change blur focus', function(event) {
      quiz.validateAnswerTolerance($(this));
    });

    $("#questions").delegate('.question_teaser_link', 'click', function(event) {
      event.preventDefault();
      var $teaser = $(this).parents(".question_teaser");
      var question_data = $teaser.data('question');
      if (!question_data) {
        $teaser.find(".teaser.question_text").text(I18n.t('loading_question', "Loading Question..."));
        $.ajaxJSON($teaser.find(".update_question_url").attr('href'), 'GET', {}, function(question) {
          showQuestion(question);
        }, function() {
          $teaser.find(".teaser.question_text").text(I18n.t('errors.loading_question_failed', "Loading Question Failed..."));
        });
      } else {
        showQuestion(question_data);
      }
      function showQuestion(question_data) {
        var $question = $("#question_template").clone().removeAttr('id');
        var question = question_data;
        var questionData = $.extend({}, question, question.question_data);
        var $questionHeader = $question.find(".display_question .question_name")
        $teaser.after($question);
        $teaser.remove();
        $question.show();
        $question.find(".question_points").text(questionData.points_possible);
        quiz.updateDisplayQuestion($question.find(".display_question"), questionData, true);
        $questionHeader.attr('tabindex', '0');
        $questionHeader.focus();
        if ($teaser.hasClass('to_edit')) {
          // we need to explicity set our quiz variables in the dom
          // or this appears to be adding a new question instead of editing
          var ques = $question.find(".question");
          var link = $question.find("a.update_question_url");
          var qId  = $question.find(".assessment_question_id")
          var href = link.attr('href');

          ques.attr("id", "question_" + question_data.id);
          link.attr("href", href.replace(/ions\/.*/, "ions/" + question_data.id));
          qId.html(question_data.id);

          $question.find(".edit_question_link").click();
        }
      }
    }).delegate('.teaser.question_text', 'click', function(event) {
      event.preventDefault();
      $(this).parents(".question_teaser").find(".question_teaser_link").click();
    }).delegate('.edit_teaser_link', 'click', function(event) {
      event.preventDefault();
      $(this).parents(".question_teaser").addClass('to_edit');
      $(this).parents(".question_teaser").find(".question_teaser_link").click();
    });

    $(".keep_editing_link").click(function(event) {
      event.preventDefault();
      $(".question_generated,.question_preview").hide()
      $(".question_editing").show();
      $("html,body").scrollTo($("#questions"));
    });

    $(".quiz_group_form").formSubmit({
      object_name: 'quiz_group',

      // rewrite the data so that it fits the jsonapi format
      processData: function(data) {
        var quizGroupQuestionPoints = data['quiz_group[question_points]'];
        if (quizGroupQuestionPoints && quizGroupQuestionPoints < 0) {
          $(this).find("input[name='quiz_group[question_points]']").errorBox(I18n.t('question.positive_points', "Must be zero or greater"));
          return false;
        }
        var newData = {};
        _.each(data, function(val, key) {
          newData[key.replace('quiz_group[', 'quiz_groups[][')] = val;
        });
        return newData;
      },
      beforeSubmit: function(formData) {
        var $form = $(this);
        var $group = $form.parents(".group_top");
        $group.fillTemplateData({
          data: formData
        }).removeClass('editing');
        $form.loadingImage();
      },
      success: function(data) {
        var $form = $(this);
        var $group = $form.parents(".group_top");
        var groups = data.quiz_groups;
        var group = groups[0];
        $form.loadingImage('remove');
        $group.removeClass('editing');
        $group.fillTemplateData({
          data: group,
          id: 'group_top_' + group.id,
          hrefValues: ['id']
        });
        $group.toggleClass('question_bank_top', !!group.assessment_question_bank_id);

        var $bank = $group.next('.assessment_question_bank');
        if (!group.assessment_question_bank_id) {
          $bank.remove();
        } else if ($bank.data('bank_data')) {
          var bank = $bank.data('bank_data');
          bank.bank_id = bank.id;
          bank.context_type_string = pluralize($.underscore(bank.context_type));
          $group.data('bank_question_count', bank.assessment_question_count);
          $group.next(".assessment_question_bank").fillTemplateData({data: bank, hrefValues: ['bank_id', 'context_type_string', 'context_id']})
            .find(".bank_name").hide().filter(".bank_name_link").show();
        }

        $group.find(".find_bank_link").hide();
        $group.fillFormData(data, {object_name: 'quiz_group'});
        var $bottom = $group.next();
        while($bottom.length > 0 && !$bottom.hasClass('group_bottom')) {
          $bottom = $bottom.next();
        }

        if ($('#insufficient_count_warning_' + group.id).length == 0) {
          var $warning = $("#insufficient_count_warning_template").clone(true).attr('id', ('insufficient_count_warning_' + group.id));
          $bottom.before($warning);
        }

        $("#unpublished_changes_message").slideDown();
        $bottom.attr('id', 'group_bottom_' + group.id);
        quiz.updateDisplayComments();
      },
      error: function(data) {
        var $form = $(this);
        var $group = $form.parents(".group_top");
        $group.addClass('editing');
        $form.loadingImage('remove');
        $form.formErrors(data);
      }
    });

    // accessible sortables
    var accessibleSortables = {

      init: function(target, questions, form) {
        this.$questions = questions;
        this.$form      = form;

        this.selected   = this.selectedItem(target);
        this.items      = this.sortableItems();
        this.intoGroups = this.findGroups();

        this.buildHeader();
        this.buildGroupMenu();
        this.showDialog();
      },

      selectedItem: function(target) {
        var target = $(target);
        var group  = target.closest(".group_top");
        var holder = target.closest(".question");
        var parent = group.length > 0 ? group : holder;

        return {
          id:   parent.attr('id').replace(/group_top_|question_/, ""),
          type: group.length > 0 ? 'group' : 'question',
          name: parent.find(".name").text(),
          sortable: group.length > 0 ? group : holder.parent()
        }
      },

      sortableItems: function() {
        return this.$questions.children('.quiz_sortable').map(function(i, item) {
          var item = $(item);
          var sortable = item;

          // the group each question belongs to
          var groupId;
          if (item.hasClass('group')) {
            groupId = item.prevAll('.group_top').attr('id').replace(/group_top_/, "")
          }

          // scope down to question to get id
          if (item.hasClass('question_holder')) {
            item = item.find('.question');
          }

          return {
            id: item.attr('id').replace(/group_top_|question_/, ""),
            type: item.hasClass('group_top') ? 'group' : 'question',
            name: item.find('.name').text(),
            group: groupId,
            top: !item.parent().hasClass('group'),
            sortable: sortable
          }
        });
      },

      // we can move item to a group if
      //   1. the selected item is a question
      //   2. there are groups on the quiz
      findGroups: function() {
        var intoGroups = [];
        if (this.selected.type == 'question') {
          intoGroups = $.grep(this.items, function(item) {
            return item.type == 'group';
          });
        }
        return intoGroups;
      },

      buildHeader: function() {
        this.$form.find('.quiz_item_name').text(this.selected.name);
      },

      buildGroupMenu: function() {
        var options = [];
        var moveWrapper = this.$form.find(".move_select_group");
        var moveSelect  = this.$form.find("#move_select_group");

        if (this.intoGroups.length > 0) {
          options = $.map(this.intoGroups, function(g) {
            return '<option value="' + g.id + '">' + htmlEscape(g.name) + '</option>';
          });
          options.unshift('<option value="top">' +
            htmlEscape(I18n.t('top_level', '-- Top level --')) +
          '</option>');

          moveWrapper.show();
        } else {
          moveWrapper.hide();
        }
        moveSelect.html($.raw(options.join('')));

        // trigger building 'place' menu
        moveSelect.change(this.buildPlaceMenu.bind(this));
        moveSelect.trigger('change');
      },

      buildPlaceMenu: function(event) {
        var option = $(event.target).find('option:selected');
        var value = option.length > 0 ? option.attr('value') : 'top';

        // filter by selected
        var filtered = this.itemsInGroup(value);

        // build options
        var options = $.map(filtered, function(item) {
          return '<option value="' + htmlEscape(item.type) + '_' + item.id + '">' +
            htmlEscape(I18n.t('before_quiz_item', "before %{name}", {name: item.name})) +
          '</option>';
        });
        options.push('<option value="last">' +
          htmlEscape(I18n.t('at_the_bottom', "-- at the bottom --")) +
        '</option>');
        this.$form.find('#move_select_question').html($.raw(options.join('')));
      },

      itemsInGroup: function(group) {
        return $.grep(this.items, function(item) {
          return item.id != this.selected.id &&
                 (group == 'top' ? item.top : item.group == group);
        }.bind(this));
      },

      showDialog: function() {
        var displayGroupSelector = this.intoGroups.length > 0;

        var dialog = this.$form.dialog({
          autoOpen: false,
          modal: true,
          width: 400,
          height: displayGroupSelector ? 345: 265,
          close: this.removeEventListeners.bind(this),
          open: this.focusDialog.bind(this)
        }).dialog('open');

        this.$form.find("h2").focus();

        this.$form.find('#move_quiz_item_cancel_btn').on('click keyclick', function() {
          this.$form.filter(":visible").dialog('close');
        }.bind(this));

        this.$form.find('#move_quiz_item_submit_btn').on('click keyclick', this.saveMove.bind(this));
      },

      focusDialog: function() {
        this.$form.find("h2").focus();
      },

      removeEventListeners: function() {
        this.$form.find('#move_quiz_item_cancel_btn').off();
        this.$form.find('#move_quiz_item_submit_btn').off();
        this.$form.find('#move_select_group').off();
      },

      saveMove: function(event) {
        event.preventDefault();

        // get selected values
        var option = this.$form.find("#move_select_group option:selected");
        var group = option.length > 0 ? option.attr('value') : 'top';

        this.reorderDom(group);
        this.ajaxPostReorder(group);

        // close form
        this.$form.filter(":visible").dialog('close');
      },

      reorderDom: function(group) {
        var option = this.$form.find("#move_select_question option:selected");
        var place = option.attr('value');
        var bottom = this.selected.sortable.nextAll('.group_bottom').first();

        // move to bottom of the group
        if (place == 'last') {
          var inGroup =  this.itemsInGroup(group);

          // there is at least 1 item already in the group
          if (inGroup.length > 0) {
            var lastItem = inGroup[inGroup.length - 1].sortable;
            if (lastItem.hasClass('group_top')) {
              lastItem = lastItem.nextAll('.group_bottom');
            }
            lastItem.after(this.selected.sortable);

          // adding as the first item in the group
          } else {
            var groupElt = this.$questions.find("#group_top_"+group);
            groupElt.after(this.selected.sortable);
          }

        // move to before the item chosen
        } else {
          var beforeItem = $.grep(this.items, function(item) {
            return item.type + "_" + item.id == place;
          })[0].sortable;
          beforeItem.before(this.selected.sortable);
        }

        this.reorderDomGroupContent(bottom);
        this.setQuestionGroupClass(group);
      },
      reorderDomGroupContent: function($bottom) {
        if (this.selected.type != 'group') { return; }

        var prev = this.selected.sortable;
        var items = this.itemsInGroup(this.selected.id);
        if (items.length) {
          $.each(items, function(i, item) {
            prev.after(item.sortable);
            prev = item.sortable;
          });
        }
        prev.after($bottom);
      },
      setQuestionGroupClass: function(group) {
        if (this.selected.type != 'question') { return; }

        if (group == 'top') {
          this.selected.sortable.removeClass('group');
        } else {
          this.selected.sortable.addClass('group');
        }
      },

      ajaxPostReorder: function(group) {
        var params = this.buildGroupParams(group);

        var item;
        if (group == 'top') {
          item = $("#quiz_urls .reorder_questions_url, #bank_urls .reorder_questions_url");
        } else {
          item = $("#group_top_" + group).find(".reorder_group_questions_url");
        }
        var url = item.attr('href');
        this.$questions.loadingImage();

        $.ajaxJSON(url, 'POST', JSON.stringify({order: params}), function(data) {
          this.$questions.loadingImage('remove');
        }.bind(this), {}, {contentType: "application/json"});
      },

      buildGroupParams: function(group) {
        var option = this.$form.find("#move_select_question option:selected");
        var place = option.attr('value');

        // rebuild the group list adding in our selection
        var selected = this.selected;
        var params = [];
        $.each(this.itemsInGroup(group), function(i, item) {
          if (item.type + '_' + item.id == place) {
            params.push({type: selected.type, id: selected.id});
          }
          params.push({type: item.type, id: item.id});
        }.bind(this));

        if (place == 'last') {
          params.push({type: selected.type, id: selected.id});
        }
        return params;
      }
    }
    $(document).on('click keydown', ".draggable-handle", function(event) {
      if (event.type == "keydown" && event.keyCode != 13 && event.keyCode != 32) { return; }
      event.preventDefault();

      accessibleSortables.init(
        $(event.target), $("#questions"), $("#move_quiz_item_form")
      );
    });
    $(document).on('focus blur', ".draggable-handle", function(e) {
      var warning = $(e.target).find('.accessibility-warning');
      warning[e.type == 'focusin' ? 'removeClass' : 'addClass']('screenreader-only');
    });

    $("#questions").sortable({
      handle: '.draggable-handle',
      helper: function(event, ui) {
        return ui.clone().removeClass('group');
      },
      items: '.group_top,.group_bottom,.question_holder',
      tolerance: 'pointer',
      start: function(event, ui) {
        ui.placeholder.css('visibility', 'visible');
        if (ui.item.hasClass('group_top')) {
          ui.helper.addClass('dragging');
          var $obj = ui.item;
          var take_with = []
          while($obj.length > 0 && !$obj.hasClass('group_bottom')) {
            $obj = $obj.next();
            if (!$obj.hasClass('ui-sortable-placeholder')) {
              take_with.push({item: $obj, visible: $obj.is(':visible')});
              $obj.hide();
            }
          }
          ui.item.data('take_with', take_with);
          ui.placeholder.show();
        } else {
          if (quiz.findContainerGroup(ui.placeholder)) {
            ui.placeholder.addClass('group');
          } else {
            ui.placeholder.removeClass('group');
          }
          ui.placeholder.append("<div class='question_placeholder' style='height: " + $.raw(ui.helper.height() - 10) + "px;'>&nbsp;</div>");
        }
      },
      change: function(event, ui) {
        var $group = quiz.findContainerGroup(ui.placeholder);
        if (ui.item.hasClass('group_top')) {
          if ($group) {
            $group.before(ui.placeholder);
            $("html,body").scrollTo(ui.placeholder);
          } else {
          }
        } else {
          if ($group) {
            if ($group.attr('id') == 'group_top_new') {
              $group.before(ui.placeholder);
              $("html,body").scrollTo(ui.placeholder);
            } else {
            if ($group.hasClass('question_bank_top')){
              // Groups that point to question banks aren't allowed to have questions
              $group.before(ui.placeholder).addClass('group');
            }else{
              ui.placeholder.addClass('group');
            }
            }
          } else {
            ui.placeholder.removeClass('group');
          }
          ui.placeholder.height(ui.helper.height()).find(".question_placeholder").height(ui.helper.height() - 10);
        }
      },
      stop: function(event, ui) {
        if (ui.item.hasClass('group_top')) {
          var take_with = ui.item.data('take_with');
          if (take_with) {
            var $obj = ui.item;
            for(var idx in take_with) {
              var data = take_with[idx];
              var $item = data.item;
              if (data.visible) $item.show();
              $obj.after($item);
              $obj = $item;
            }
          }
        } else {
          if (quiz.findContainerGroup(ui.item)) {
            ui.item.addClass('group');
            var $obj = ui.item.prev();
            while($obj.length > 0 && !$obj.hasClass('group_top')) {
              $obj = $obj.prev();
            }
            $obj.find(".expand_link").click();
          } else {
            ui.item.removeClass('group');
          }
        }

        var url = $("#quiz_urls .reorder_questions_url, #bank_urls .reorder_questions_url").attr('href');
        var data = {};
        var $container = $("#questions");
        var items = [];
        if (quiz.findContainerGroup(ui.item)) {
          $container = quiz.findContainerGroup(ui.item);
          $list = [];
          url = $container.find(".reorder_group_questions_url").attr('href');
          var $obj = $container.next();
          while($obj.length > 0 && !$obj.hasClass('group_bottom')) {
            items.push($obj);
            $obj = $obj.next();
          }
        } else {
          $container.children(".question_holder:not(.group),.group_top").each(function() {
            items.push($(this));
          });
        }
        $container.loadingImage();
        var list = [];

        $.each(items, function(i, $obj) {
          var object;
          if ($obj.hasClass('question_holder')) {
            var $question = $obj.find('.question');
            var attrID = $question.attr('id');
            var id = attrID ? attrID.substring(9) : $question.find(".id").text();
            object = {'type': 'question', 'id': id};

          } else {
            var id = $obj.attr('id').substring(10);
            object = {'type': 'group', 'id': id};
          }
          list.push(object)
        });

        $.ajaxJSON(url, 'POST', JSON.stringify({order: list}), function(data) {
          $container.loadingImage('remove');
        }, {}, {contentType: "application/json"});
      }
    });

    $(document).delegate(".edit_group_link", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      event.preventDefault();
      var $top = $(this).parents(".group_top");
      var data =  $top.getTemplateData({textValues: ['name', 'pick_count', 'question_points']});
      $top.fillFormData(data, {object_name: 'quiz_group'});
      $top.addClass('editing');
      $top.find(":text:visible:first").focus().select();
      $top.find(".quiz_group_form").attr('action', $top.find(".update_group_url").attr('href'))
        .attr('method', 'PUT');
      $top.find(".submit_button").text(I18n.t('buttons.update_group', "Update Group"));
    }).delegate(".delete_group_link", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      event.preventDefault();
      var $top = $(this).parents(".group_top");
      var $list = $("nothing").add($top);
      var $next = $top.next();
      while($next.length > 0 && !$next.hasClass('group_bottom')) {
        $list = $list.add($next);
        $next = $next.next();
      }
      $list = $list.add($next);
      $top.confirmDelete({
        url: $top.find(".update_group_url").attr('href'),
        confirmed: function() {
          $list.dim();
        },
        success: function() {
          $list.fadeOut(function() {
            $(this).remove();
            quiz.updateDisplayComments();
          });
        }
      });
    }).delegate(".group_edit.cancel_button", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      var $top = $(this).parents(".group_top");
      $top.removeClass('editing');
      if ($top.attr('id') == 'group_top_new') {
        var $next = $top.next();
        while($next.length > 0 && !$next.hasClass('group_bottom')) {
          var $current = $next
          $next.removeClass('group');
          $next = $next.next();
          if ($current.hasClass('assessment_question_bank')) {
            $current.remove();
          }
        }
        $next.remove();
        $top.remove();
      }
      quiz.updateDisplayComments();
    }).delegate(".collapse_link", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      event.preventDefault();
      $(this).parents(".group_top").find(".collapse_link").addClass('hidden').end()
        .find(".expand_link").removeClass('hidden').focus();
      var $obj = $(this).parents(".group_top").next();
      while($obj.length > 0 && $obj.hasClass('question_holder')) {
        $obj.hide();
        $obj = $obj.next();
      }
    }).delegate(".expand_link", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      event.preventDefault();
      $(this).parents(".group_top").find(".collapse_link").removeClass('hidden').focus().end()
        .find(".expand_link").addClass('hidden');
      var $obj = $(this).parents(".group_top").next();
      while($obj.length > 0 && $obj.hasClass('question_holder')) {
        $obj.show();
        $obj = $obj.next();
      }
    });

    RichContentEditor.initSidebar();

    var keyboardShortcutsView = new RCEKeyboardShortcuts();

    RichContentEditor.loadNewEditor($("#quiz_description"), {
      focus: true,
      tinyOptions: {
        aria_label: I18n.t('label.quiz.instructions', 'Quiz instructions, rich text area')
      }
    })
    keyboardShortcutsView.render().$el.insertBefore($(".toggle_description_views_link:first"));

    $(".toggle_description_views_link").click(function(event) {
      event.preventDefault();
      RichContentEditor.callOnRCE($("#quiz_description"), 'toggle');
      //  todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(this).siblings(".toggle_description_views_link").andSelf().toggle();
    });

    $(".toggle_question_content_views_link").click(function(event) {
      event.preventDefault();
      RichContentEditor.callOnRCE($(this).parents(".question_form").find(".question_content"), 'toggle');
      //  todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(this).siblings(".toggle_question_content_views_link").andSelf().toggle();
    });

    $(".toggle_text_after_answers_link").click(function(event) {
      event.preventDefault();
      RichContentEditor.callOnRCE($(this).parents(".question_form").find(".text_after_answers"), 'toggle');
      //  todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(this).siblings(".toggle_text_after_answers_link").andSelf().toggle();
    });

    $("#calc_helper_methods").change(function() {
      var method = $(this).val();
      $("#calc_helper_method_description").text(calcCmd.functionDescription(method));
      var html = "<pre>" + $.raw($.map(calcCmd.functionExamples(method), htmlEscape).join("</pre><pre>")) + "</pre>";
      $("#calc_helper_method_examples").html(html);
    });

    $("#equations_dialog_tabs").tabs();

    $(".delete_quiz_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".quiz").confirmDelete({
        message: I18n.t('confirms.delete_quiz', "Are you sure you want to delete this quiz?"),
        url: $(this).attr('href'),
        success: function() { window.location.replace(ENV.QUIZZES_URL); }
      });
    });

    if (ENV['CONDITIONAL_RELEASE_SERVICE_ENABLED']) {
      window.conditionalRelease = window.conditionalRelease || {};
      conditionalRelease.editor = ConditionalRelease.attach(
        $('#conditional-release-target').get(0),
        I18n.t('quiz'),
        ENV['CONDITIONAL_RELEASE_ENV']);

      $('div.form').on('change', function(event) {
        if (!conditionalRelease.assignmentDirty) {
          conditionalRelease.assignmentDirty = true
          conditionalRelease.editor.setProps({ assignmentDirty: true });
        }
      });
    }
  });

  $.fn.multipleAnswerSetsQuestion = function() {
    var $question = $(this),
        $question_content = $question.find(".question_content"),
        $select = $question.find(".blank_id_select"),
        $question_type = $question.find(".question_type");
    if ($question.data('multiple_sets_question_bindings')) { return; }
    $question.data('multiple_sets_question_bindings', true);
    $question_content.bind('keypress', function(event) {
      setTimeout(function() {$(event.target).triggerHandler('change')}, 50);
    });
    $question_content.bind('change', function() {
      var question_type = $question_type.val();
      if (question_type != 'multiple_dropdowns_question' && question_type != 'fill_in_multiple_blanks_question') {
        return;
      }
      var text = RichContentEditor.callOnRCE($(this), 'get_code');
      var matches = text.match(/\[[A-Za-z0-9_\-.]+\]/g);
      $select.find("option.shown_when_no_other_options_available").remove();
      $select.find("option").addClass('to_be_removed');
      var matchHash = {};
      if (matches) {
        for(var idx  = 0; idx < matches.length; idx++) {
          if (matches[idx]) {
            var variable = matches[idx].substring(1, matches[idx].length - 1);
            if (!matchHash[variable]) {
              var $option = $select.find("option").eq(idx); //." + variable);
              if (!$option.length) {
                $option = $("<option/>").appendTo($select);
              }
              $option
                .removeClass('to_be_removed')
                .val(variable)
                .text(variable);
              matchHash[variable] = true;
            }
          }
        }
      }
      // if there are not any options besides the default "<option class="shown_when_no_other_options_available" value='0'>[ Enter Answer Variables Above ]</option>" one
      if (!$select.find("option:not(.shown_when_no_other_options_available)").length) {
        $select.append("<option class='shown_when_no_other_options_available' value='0'>" + htmlEscape(I18n.t('enter_answer_variable_above', "[ Enter Answer Variables Above ]")) + "</option>");
      }
      $select.find("option.to_be_removed").remove();
      $select.change();
    }).change();
    $select.change(function() {
      var question_type = $question_type.val();
      if (question_type != 'multiple_dropdowns_question' && question_type != 'fill_in_multiple_blanks_question') {
        return;
      }
      $question.find(".form_answers .answer").hide().addClass('hidden');
      $select.find("option").each(function(i) {
        var $option = $(this);
        $question.find(".form_answers .answer_for_" + $(this).val()).each(function() {
          $(this).attr('class', $(this).attr('class').replace(/answer_idx_\d+/g, ""));
        }).addClass('answer_idx_' + i);
      });
      if ($select.val() !== "0") {
        var variable = $select.val(),
            variableIdx = $select[0].selectedIndex;
        if (variableIdx >= 0) {
          $question.find(".form_answers .answer").each(function() {
            var $this = $(this);
            if (!$this.attr('class').match(/answer_idx_/)) {
              if ($this.attr('class').match(/answer_for_/)) {
                var idx = null,
                    blank_id = $this.attr('class').match(/answer_for_[^\s]+/);
                if (blank_id && blank_id[0]) { blank_id = blank_id[0].substring(11); }
                $select.find("option").each(function(i) {
                  if ($(this).text() == blank_id) {
                    idx = i;
                  }
                });
                if (idx === null) {
                  idx = variableIdx;
                }
                $this.addClass('answer_idx_' + idx);
              } else {
                $this.addClass('answer_idx_' + variableIdx);
              }
            }
          });
        }
        $select.find("option").each(function(i) {
          var text = $(this).text();
          $question.find(".form_answers .answer.answer_idx_" + i).find(".blank_id").each(function() {
            $(this).text(text);
          });
        });
        var $valid_answers = $question.find(".form_answers .answer.answer_idx_" + variableIdx).show().removeClass('hidden');
        if (!$valid_answers.length && variable && variable !== '0') {
          for(var idx = 0; idx < 2; idx++) {
            $question.find(".add_answer_link").triggerHandler('click', true);
          }
          $valid_answers = $question.find(".form_answers .answer.answer_idx_" + variableIdx).show().removeClass('hidden');
        }
        if (!$valid_answers.filter(".correct_answer").length) {
          $valid_answers.filter(":first").addClass('correct_answer');
        }
        $valid_answers.each(function() {
          $(this).find(".blank_id").text(variable);
        });
      }
    }).change();
  }

  $.fn.formulaQuestion = function() {
    var $question = $(this);
    if ($question.data('formula_question_bindings')) { return; }
    $question.data('formula_question_bindings', true);
    $question.find(".supercalc").superCalc({
      pre_process: function() {
        var result = [];
        $question.find(".variables .variable").each(function() {
          var data = {
            name: $(this).attr('data-name'),
            value: $(this).attr('data-value')
          };
          result.push(data.name + " = " + data.value);
        });
        return result;
      },
      formula_added: function() {
        $question.triggerHandler('settings_change', true);
      }
    });
    $question.find(".compute_combinations").click(function() {
      var $button = $(this);
      $button.text(I18n.t('buttons.generating', "Generating...")).attr('disabled', true);
      var question_type = $question.find(".question_type").val();
      if (question_type != 'calculated_question') {
        return;
      }
      var $table = $question.find(".combinations");
      $table.find("thead tr").empty();
      $question.find(".variables .variable").each(function() {
        var $th = $("<th/>");
        $th.text($(this).find(".name").text());
        $table.find("thead tr").append($th);
      });
      var $th = $("<th/>");
      $th.text(I18n.t('final_answer', "Final Answer"));
      $th.addClass('final_answer');
      $table.find("thead tr").append($th);
      $table.find("tbody").empty();
      var cnt = parseInt($question.find(".combination_count").val(), 10) || 10;
      if (cnt < 0) {
        cnt = 10;
      } else if (cnt > ENV.quiz_max_combination_count) {
        cnt = ENV.quiz_max_combination_count;
      }
      $question.find(".combination_count").val(cnt);
      var succeeded = 0;
      var existingCombinations = {};
      var mod = 0;
      var finished = function() {
        $question.find(".supercalc").superCalc('clear_cached_finds');
        $button.text("Generate").attr('disabled', false);
        if (succeeded == 0) {
          alert(I18n.t('alerts.no_valid_combinations', "The system could not generate any valid combinations for the parameters given"));
        } else if (succeeded < cnt) {
          alert(I18n.t('alerts.only_n_valid_combinations', {'one': "The system could only generate 1 valid combination for the parameters given", 'other': "The system could only generate %{count} valid combinations for the parameters given"}, {'count': succeeded}));
        }
        $question.triggerHandler('settings_change', false);
      };
      var combinationIndex = 0;
      var failedCount = 0;
      var $status = $question.find(".formulas .formula_row:last .status"),
        $variable_values = $question.find(".variables .variable"),
        $tbody = $table.find("tbody");
      $question.find(".supercalc").superCalc('cache_finds');
      var answer_tolerance = parseFloatOrPercentage($question.find(".combination_answer_tolerance").val());
      var next = function() {
        $button.text(I18n.t('buttons.generating_combinations_progress', "Generating... (%{done}/%{total})", {'done': succeeded, 'total': cnt}));
        var fragment = document.createDocumentFragment();
        for(var idx = 0; idx < 5 && succeeded < cnt && failedCount < 25; idx++) {
          $variable_values.each(function() {
            $(this).find(".variable_setting:first").trigger('change', {cache: true});
          });
          $question.find(".supercalc").superCalc('recalculate', true);
          var result = $status.attr('data-res');
          var solution = new QuizFormulaSolution(result);
          var combination = [];
          $variable_values.each(function() {
            combination.push($(this).attr('data-value'));
          });
          if (!existingCombinations[combination] || true) {
            if (solution.isValid()) {
              var $result = $("<tr/>");
              $variable_values.each(function() {
                var $td = $("<td/>");
                $td.html($(this).attr('data-value'));
                $result.append($td);
              });
              var $td = $("<td/>");
              $td.addClass('final_answer');
              var html = htmlEscape(solution.rawText());
              var tolerance = answer_tolerance;
              if (tolerance) {
                html += " <span style='font-size: 0.8em;'>+/-</span> " + htmlEscape(tolerance);
              }
              $td.html(html);
              $result.append($td);
              succeeded++;
              failedCount = 0;
              fragment.appendChild($result[0]);
            } else {
              failedCount++;
            }
            existingCombinations[combination] = true;
          } else {
            failedCount++;
          }
        }
        $tbody[0].appendChild(fragment);

        $button.text(I18n.t('buttons.generating_combinations_progress', "Generating... (%{done}/%{total})", {'done': succeeded, 'total': cnt}));
        if (combinationIndex >= cnt || succeeded >= cnt || failedCount >= 25) {
          finished();
          return;
        } else {
          combinationIndex++;
          setTimeout(function() {
            next();
          }, 500);
        }
      };
      setTimeout(next, 100);
    });
    $question.find(".recompute_variables").click(function() {
      var question_type = $question.find(".question_type").val();
      if (question_type != 'calculated_question') {
        return;
      }
      $question.triggerHandler('recompute_variables', true);
    });
    $question.bind('recompute_variables', function(event, in_dom) {
      $question.find(".variables .variable").each(function() {
        $(this).find(".variable_setting:first").trigger('change', in_dom ? { recompute: true, cache: true } : { cache: true });
      });
    });
    $question.bind('settings_change', function(event, remove) {
      var question_type = $question.find(".question_type").val();
      if (question_type != 'calculated_question') {
        return;
      }
      var variables = $question.find(".variables tbody tr.variable").length > 0;
      var formulas = $question.find(".formulas .formula").length > 0;

      $question.find(".combinations_option").attr('disabled', !variables || !formulas);
      $question.find(".variables_specified").showIf(variables);
      $question.find(".formulas_specified").showIf(formulas);
      if ($question.hasClass('ready') && remove) {
        $question.find(".combinations_holder .combinations tbody tr").remove();
      }
      $question.find(".combinations_holder").showIf($question.find(".combinations tbody tr").length > 0);
    });

    $question.find(".variables").delegate('.variable_setting', 'change', function(event, options) {
      var question_type = $question.find(".question_type").val();
      if (question_type != 'calculated_question') {
        return;
      }
      var $variable = $(event.target).parents(".variable")
      var data = $variable.data('cached_data');
      if (!data || !options || !options.cache || (options.recompute && options.cache)) {
        data = $variable.getFormData();
        data.min = parseFloat(data.min) || 0;
        data.max = Math.max(data.min, parseFloat(data.max) || 0);
        data.round = parseInt(data.round, 10) || 0;
        data.range = data.max - data.min;
        data.rounder = Math.pow(10, data.round) || 1;
      }
      if (options && options.cache) {
        $variable.data('cached_data', data);
      }
      var val = (Math.random() * data.range) + data.min;
      val = Math.round(val * data.rounder) / (data.rounder);
      $variable.attr('data-value', val);
      if (!options || options.template || options.recompute) {
        $variable.find(".value").text(val);
      }
      if (!options || options.recompute) {
        $question.find(".supercalc").superCalc('recalculate');
        $question.triggerHandler('settings_change', true);
      }
    });
    $question.find(".help_with_equations_link").click(function(event) {
      event.preventDefault();
      $("#calc_helper_methods").empty();
      var functions = calcCmd.functionList();
      for(var idx in functions) {
        var func = functions[idx][0];
        var $option = $("<option/>");
        $option.val(func).text(func);
        $("#calc_helper_methods").append($option);
      }
      $("#calc_helper_methods").change();
      $("#help_with_equations_dialog").dialog({
        title: I18n.t('titles.help_with_formulas', "Help with Quiz Question Formulas"),
        width: 500
      });
    });
    $question.find(".combinations_option").attr('disabled', true);
    $question.find(".question_content").bind('keypress', function(event) {
      setTimeout(function() {$(event.target).triggerHandler('change')}, 50);
    });
    $question.find(".question_content").bind('change', function(event) {
      var text = RichContentEditor.callOnRCE($(this), 'get_code');
      var matches = text.match(/\[[A-Za-z][A-Za-z0-9]*\]/g);
      $question.find(".variables").find("tr.variable").addClass('to_be_removed');
      $question.find(".variables").showIf(matches && matches.length > 0);
      var matchHash = {};
      if (matches) {
        for(var idx  = 0; idx < matches.length; idx++) {
          if (matches[idx]) {
            var variable = matches[idx].substring(1, matches[idx].length - 1);
            if (!matchHash[variable]) {
              var $variable = $question.find('.variables tr.variable[data-name="' + variable + '"]');
              if ($variable.length === 0) {
                var label_id = htmlEscape("label_for_var_" + variable);
                // xsslint safeString.identifier label_id

                $variable = $("<tr class='variable'>"
                              + "<th id='" + label_id + "' class='name'></th>"
                              + "<td><div><input aria-labelledby='" + label_id + " equation_var_minimum' type='text' name='min' class='min variable_setting' style='width: 70%;' value='1'/></div></td>"
                              + "<td><div><input aria-labelledby='" + label_id + " equation_var_maximum' type='text' name='max' class='max variable_setting' style='width: 70%;' value='10'/></div></td>"
                              + "<td><div style='width: 70%;'><select aria-labelledby='" + label_id + " equation_var_precision' name='round' class='round variable_setting'><option>0</option><option>1</option><option>2</option><option>3</option></div></td>"
                              + "<td aria-labelledby='equation_var_example' class='value'></td></tr>");

                $question.find(".variables tbody").append($variable);
                $variable.find(".variable_setting:first").triggerHandler('change');
              }
              $variable.removeClass('to_be_removed');
              $variable.addClass(variable);
              $variable.attr('data-name', variable);
              $variable.find("th.name").text(variable);
              matchHash[variable] = true;
            }
          }
        }
      }
      $question.find(".variables").find("tr.to_be_removed").remove();
      $question.find(".supercalc").superCalc('recalculate', true);
      $question.triggerHandler('settings_change', false);
    }).change();
  }

  function numericalAnswerTypeChange($el) {
    var val = $el.val();
    var $answer = $el.parents(".numerical_answer");
    $answer.find(".numerical_answer_text").hide();
    $answer.find("." + val).show();
  }

  // attach HTML answers but only when they click the button
  $('#questions').delegate('.edit_html', 'click', function(event) {
    event.preventDefault();
    var $this = $(this);
    var toggler = $this.data('editorToggle');
    var inputColumn = $this.parents().find('.answer_type:visible')[0]
    var rceWidth = inputColumn.offsetWidth

    // create toggler instance on the first click
    if (!toggler) {
      toggler = new MultipleChoiceToggle($this, {
        editorBoxLabel: I18n.t('label.answer.text', 'Answer text, rich text area'),
        tinyOptions: {width: rceWidth}
      });
      $this.data('editorToggle', toggler);
    }

    toggler.toggle();
  });

  $(function() {
    $(document).on('change', function controlResultVisibilityFields() {
      // "Let Students See Their Quiz Responses" related fields visibility:
      if (isShowingResults()) {
        $('.show_quiz_results_options').show();
        // CA options:
        //
        // What we'd like to do is show/hide the date-pickers based on the
        // "Let Students See The Correct Answers" option, and disable them
        // if we're showing results just once ("Only Once After Each Attempt"):
        correctAnswerVisibility.showDatePickers(correctAnswerVisibility.isOn());
        correctAnswerVisibility.enableDatePickers(!isShowingResultsJustOnce());
      } else {
        correctAnswerVisibility.disable();
        $('#quiz_one_time_results').prop('checked', false)
        $('#hide_results_only_after_last').prop('checked', false);
        $('#quiz_show_correct_answers_last_attempt').prop('checked', false);
        $('.show_quiz_results_options').hide();
      }

      // Only allow students to see answers on last attempt if the quiz has more than one attempt
      showCorrectAnswersLastAttempt = parseInt($('#quiz_allowed_attempts').val()) > 0;
      $('#quiz_show_correct_answers_last_attempt_container').toggle(showCorrectAnswersLastAttempt);
      if(!showCorrectAnswersLastAttempt) {
        $('#quiz_show_correct_answers_last_attempt').prop('checked', false);
      }
    }).triggerHandler('change');
  });
});
