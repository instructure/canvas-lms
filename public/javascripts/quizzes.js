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
require([
  'i18n!quizzes',
  'jquery' /* $ */,
  'calcCmd',
  'str/htmlEscape',
  'str/pluralize',
  'wikiSidebar',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors, errorBox */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar, /\$\.underscore/, truncateText */,
  'jquery.instructure_misc_plugins' /* .dim, confirmDelete, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.rails_flash_notifications' /* flashMessage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'supercalc' /* superCalc */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.placeholder' /* /\.placeholder/ */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(I18n, $, calcCmd, htmlEscape, pluralize, wikiSidebar) {

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

    // Determines whether or to show the "show question details" link.
    checkShowDetails: function() {
      var hasQuestions = this.$questions.find('fieldset:not(.essay_question, .text_only_question)').length;
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

      if (answer.answer_selection_type == "any_answer") {
        $answer.addClass('correct_answer');
      } else if (answer.answer_selection_type == "matching") {
        $answer.removeClass('correct_answer');
      } else if (answer.answer_selection_type != "multiple_answer") {
        var $answers = $answer.parent().find(".answer");
        $answers.find(".answer").filter(".correct_answer").not(":first").removeClass('correct_answer');
        if ($answers.filter(".correct_answer").length === 0) {
          $answers.filter(":first").addClass('correct_answer');
        }
        $answers.find('.select_answer_link').attr('title', I18n.t('titles.click_to_set_as_correct', "Click to set this answer as correct"));
      } else {
        $answer.filter(".correct_answer").find('.select_answer_link').attr('title', I18n.t('titles.click_to_unset_as_correct', "Click to unset this answer as correct"));
        $answer.filter(":not(.correct_answer)").find('.select_answer_link').attr('title', I18n.t('titles.click_to_set_as_correct', "Click to set this answer as correct"));
      }

      $answer.find(".numerical_answer_type").change();

      var templateData = {
        answer_text: answer.answer_text,
        id: answer.id,
        match_id: answer.match_id
      }
      templateData.comments_header = I18n.beforeLabel('comments_on_answer', "Comments, if the user chooses this answer");
      templateData.short_answer_header = I18n.beforeLabel('possible_answer', "Possible Answer");

      $answer.find(".comment_focus").attr('title', I18n.t('titles.click_to_enter_comments_on_answer', 'Click to enter comments for the student if they choose this answer'));

      if (question_type == "essay_question") {
        templateData.comments_header = I18n.beforeLabel('comments_on_question', "Comments for this question");
      } else if (question_type == "matching_question") {
        templateData.answer_match_left_html = answer.answer_match_left_html;
        templateData.comments_header = I18n.beforeLabel('comments_on_wrong_match', "Comments if the user gets this match wrong");
        $answer.find(".comment_focus").attr('title', I18n.t('titles.click_to_enter_comments_on_wrong_match', 'Click to enter comments for the student if they miss this match'));
      } else if (question_type == "missing_word_question") {
        templateData.short_answer_header = I18n.beforeLabel('answer_text', "Answer text");
      } else if (question_type == "multiple_choice_question") {
        templateData.answer_html = answer.answer_html;
      } else if (question_type == "multiple_answers_question") {
        templateData.answer_html = answer.answer_html;
        templateData.short_answer_header = I18n.beforeLabel('answer_text', "Answer text");
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

      addHTMLFeedback($answer, answer, 'answer_comment');

      if (answer.answer_weight > 0) {
        $answer.addClass('correct_answer');
        if (answer.answer_selection_type == "multiple_answer") {
          $answer.find('.select_answer_link').attr('title', I18n.t('titles.click_to_unset_as_correct', "Click to unset this answer as correct"));
        }
      } else if (answer.answer_weight < 0) {
        $answer.addClass('negative_answer');
      }

      if (question_type == "matching_question") {
        $answer.removeClass('correct_answer');
      }
    },
    questionContentCounter: 0,

    showFormQuestion: function($form) {
      if (!$form.attr('id')) {
        // we show and then hide the form so that the layout for the editorBox is computed correctly
        $form.show();
        $form.find(".question_content").attr('id', 'question_content_' + quiz.questionContentCounter++);
        $form.find(".question_content").editorBox();
        $form.find(".text_after_answers").attr('id', 'text_after_answers_' + quiz.questionContentCounter++);
        $form.find(".text_after_answers").editorBox();
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
        htmlValues: []
      };
      if (escaped) {
        fillArgs['htmlValues'].push('question_text');
      } else {
        fillArgs['except'].push('question_text');
      }
      $question.fillTemplateData(fillArgs);
      $question.find(".original_question_text").fillFormData(question);
      $question.find(".question_correct_comment").toggleClass('empty', !question.correct_comments && !question.correct_comments_html);
      $question.find(".question_incorrect_comment").toggleClass('empty', !question.incorrect_comments && !question.incorrect_comments_html);
      $question.find(".question_neutral_comment").toggleClass('empty', !question.neutral_comments && !question.neutral_comments_html);
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
            var answer = data.answer;
            if (question.answerDecimalPoints || question.answer_tolerance) {
              var tolerance = parseFloat(question.answer_tolerance);
              tolerance = tolerance || Math.pow(0.1, question.answerDecimalPoints);
              answer = answer + " <span style='font-size: 0.8em;'>+/-</span> " + tolerance;
              $question.find(".answer_tolerance").text(tolerance);
            }
            $td.html(answer);
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
          $question.find(".answers").append($displayAnswer);
          var $option = $(document.createElement("option"));
          $option.val("option_" + i).text(data.answer_text);
          $select.append($option);
        });
      }

      $question.find(".blank_id_select").empty();
      if (question.question_type == 'missing_word_question') {
        var $text = $question.find(".question_text");
        $text.html("<span class='text_before_answers'>" + question.question_text + "</span> ");
        $text.append($select);
        $text.append(" <span class='text_after_answers'>" + question.text_after_answers + "</span>");
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
        var code = "";
        for(var cdx in split) {
          if(split[cdx]) {
            code = code + "<li>" + htmlEscape(split[cdx]) + "</li>";
          }
        }
        if (code) {
          $text.append(I18n.beforeLabel('other_incorrect_matches', "Other Incorrect Match Options") + "<ul class='matching_answer_incorrect_matches_list'>" + code + "</ul>");
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
        $question.fillTemplateData({
          data: {id: question.id},
          id: 'question_' + question.id,
          hrefValues: ['id']
        });
        $question.find(".original_question_text").fillFormData(question)
        quiz.updateDisplayComments();
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
      $formQuestion.find(".explanation").hide().filter("." + question_type + "_explanation").show();
      $formQuestion.attr('class', 'question').addClass('selectable');
      $formQuestion.find(".missing_word_after_answer").hide().end()
        .find(".matching_answer_incorrect_matches_holder").hide().end()
        .find(".question_comment").css('display', '').end();
      if ($("#questions").hasClass('survey_quiz')) {
        $formQuestion.find(".question_comment").css('display', 'none').end()
          .find(".question_neutral_comment").css('display', '');
      }
      $formQuestion.find(".question_header").text("Question:");
      $formQuestion.addClass(question_type);
        $formQuestion.find(".question_points_holder").showIf(!$formQuestion.closest(".question_holder").hasClass('group') && question_type != 'text_only_question');
      $formQuestion.find("textarea.comments").each(function() {
        $(this).val($.trim($(this).val()));
        if ($(this).val()) {
          $(this).parents(".question_comment").removeClass('empty');
        } else {
          $(this).parents(".question_comment").addClass('empty');
        }
      });
      var options = {
        addable: true
      };
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
      } else if (question_type == 'essay_question') {
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
        result.textValues = ['numerical_answer_type', 'answer_exact', 'answer_error_margin', 'answer_range_start', 'answer_range_end'];
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
        $formQuestion.find(".question_header").text(I18n.beforeLabel('message_text', "Message Text"));
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
        var val = parseFloat($(this).find(".question_points:visible,.question_points.hidden").text());
        if (isNaN(val)) { val = 0; }
        tally += val;
      });
      $("#questions .group_top:not(#group_top_new)").each(function() {
        var val = parseFloat($(this).find(".question_points").text());
        if (isNaN(val)) { val = 0; }
        var cnt = parseInt($(this).find(".pick_count").text(), 10);
        if (isNaN(cnt)) { cnt = 0; }
        tally += val * cnt;
      });
      tally = Math.round(tally * 100.0) / 100.0;
      $("#quiz_options_form").find(".points_possible").text(tally);
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
      if (type == "int") {
        var val = parseInt($input.val(), 10);
        if (isNaN(val)) { val = 0; }
        $input.val(val);
      } else if (type == "float") {
        var val = Math.round(parseFloat($input.val()) * 100.0) / 100.0;
        if (isNaN(val)) { val = 0.0; }
        $input.val(val);
      } else if (type == "float_long") {
        var val = Math.round(parseFloat($input.val()) * 10000.0) / 10000.0;
        if (isNaN(val)) { val = 0.0; }
        $input.val(val);
      }
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
      answer_range_end: ""
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
    data.answer_exact = data.exact || data.answer_exact;
    data.answer_error_margin = data.answer_error_margin || data.margin;
    data.answer_range_start = data.start || data.answer_range_start;
    data.answer_range_end = data.end || data.answer_range_end

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
        textValues: ['question_name', 'question_points', 'question_type', 'answer_selection_type', 'assessment_question_id', 'correct_comments', 'incorrect_comments', 'neutral_comments', 'matching_answer_incorrect_matches', 'equation_combinations', 'equation_formulas'],
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
        $question.find(".answer").each(function() {
          var $answer = $(this);
          var answerData = $answer.getTemplateData({
            textValues: ['answer_exact', 'answer_error_margin', 'answer_range_start', 'answer_range_end', 'answer_weight', 'numerical_answer_type', 'blank_id', 'id', 'match_id', 'answer_text', 'answer_match_left', 'answer_match_right', 'answer_comment'],
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
        question.answer_tolerance = parseFloat($question.find(".answer_tolerance").text(), 10) || 0;
      }
      question.position = i;
      question.question_points = parseFloat(question.question_points);
      if (isNaN(question.question_points)) {
        question.question_points = 0;
      }
      quiz.points_possible += question.question_points;
      quiz.questions.push(question);
    });
    return quiz;
  }

  function generateFormQuizQuestion(formQuiz) {
    var data = {};
    for(var name in formQuiz) {
      if (name.indexOf('questions[question_0]') == 0) {
        var n = name.replace("questions[question_0]", "question");
        data[n] = formQuiz[name];
      }
    }
    return data;
  }

  function generateFormQuiz(quiz) {
    var data = {};
    var quizAssignmentId = quizAssignmentId || null;
    if (quizAssignmentId) {
      data['quiz[assignment_id]'] = quizAssignmentId;
    }
    data['quiz[title]'] = quiz.quiz_name;
    for(var idx in quiz.questions) {
      var question = quiz.questions[idx];
      var id = "questions[question_" + idx + "]";
      data[id + '[question_name]'] = question.question_name;
      data[id + '[assessment_question_id]'] = question.assessment_question_id;
      data[id + '[question_type]'] = question.question_type;
      data[id + '[points_possible]'] = question.question_points;
      data[id + '[correct_comments]'] = question.correct_comments;
      data[id + '[incorrect_comments]'] = question.incorrect_comments;
      data[id + '[neutral_comments]'] = question.neutral_comments;
      data[id + '[question_text]'] = question.question_text;
      data[id + '[position]'] = question.position;
      data[id + '[text_after_answers]'] = question.text_after_answers;
      data[id + '[matching_answer_incorrect_matches]'] = question.matching_answer_incorrect_matches;
      for(var jdx in question.formulas) {
        var jd = id + "[formulas][formula_" + jdx + "]";
        data[jd] = question.formulas[jdx];
      }
      for(var jdx in question.variables) {
        var jd = id + "[variables][variable_" + jdx + "]";
        data[jd + '[name]'] = question.variables[jdx].name;
        data[jd + '[min]'] = question.variables[jdx].min;
        data[jd + '[max]'] = question.variables[jdx].max;
        data[jd + '[scale]'] = question.variables[jdx].scale;
      }
      data[id + '[answer_tolerance]'] = question.answer_tolerance;
      data[id + '[formula_decimal_places]'] = question.formula_decimal_places;
      for(var jdx in question.answers) {
          var answer = question.answers[jdx];
          var jd = id + "[answers][answer_" + jdx + "]";
          data[jd + '[answer_text]'] = answer.answer_text;
          data[jd + '[answer_html]'] = answer.answer_html;
          data[jd + '[answer_comments]'] = answer.answer_comment;
          data[jd + '[answer_comments_html]'] = answer.answer_comment_html;
          data[jd + '[answer_weight]'] = answer.answer_weight;
          data[jd + '[answer_match_left]'] = answer.answer_match_left;
          data[jd + '[answer_match_left_html]'] = answer.answer_match_left_html;
          data[jd + '[answer_match_right]'] = answer.answer_match_right;
          data[jd + '[numerical_answer_type]'] = answer.numerical_answer_type;
          data[jd + '[answer_exact]'] = answer.answer_exact;
          data[jd + '[answer_error_margin]'] = answer.answer_error_margin;
          data[jd + '[answer_range_start]'] = answer.answer_range_start;
          data[jd + '[answer_range_end]'] = answer.answer_range_end;
          data[jd + '[blank_id]'] = answer.blank_id;
          data[jd + '[match_id]'] = answer.match_id;
          data[jd + '[id]'] = answer.id;
          for(var kdx in answer.variables) {
            var kd = jd + "[variables][variable_" + kdx + "]";
            data[kd + '[name]'] = answer.variables[kdx].name;
            data[kd + '[value]'] = answer.variables[kdx].value;
          }
      }
    }
    return data;
  }

  function addHTMLFeedback($container, question_data, name) {
    html = question_data[name+'_html'];
    if (html && html.length > 0) {
      $container.find('.'+name+'_html').html(html).css('display', 'inline-block');
      $container.find('textarea').val(html);
      $container.find('a,textarea').hide();
      $container.removeClass('empty');
    }
  }

  $(document).ready(function() {
    quiz.init().updateDisplayComments();

    var $quiz_options_form = $("#quiz_options_form");
    $.scrollSidebar();
    $(".datetime_field").datetime_field();
    $("#questions").delegate('.group_top,.question,.answer_select', 'mouseover', function(event) {
      $(this).addClass('hover');
    }).delegate('.group_top,.question,.answer_select', 'mouseout', function(event) {
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

    $quiz_options_form.find("#time_limit_option").change(function() {
      if (!$(this).attr('checked')) {
        $("#quiz_time_limit").val("");
      }
    }).triggerHandler('change');

    $("#limit_attempts_option").change(function() {
      var $item = $("#quiz_allowed_attempts");
      if ($(this).attr('checked')) {
        var val = parseInt($item.data('saved_value') || $item.val() || "2", 10);
        if (val == -1 || isNaN(val)) {
          val = 1;
        }
        $item.val(val);
      } else {
        $item.data('saved_value', $(this).val());
        $item.val('--');
      }
    }).triggerHandler('change');

    $("#protect_quiz").change(function() {
      var checked = $(this).attr('checked');
      $(".protected_options").showIf(checked).find(":checkbox").each(function() {
        if (!checked) {
          $(this).attr('checked', false).change();
        }
      });
    }).triggerHandler('change');

    $("#quiz_require_lockdown_browser").change(function() {
      $("#lockdown_browser_suboptions").showIf($(this).attr('checked'));
      $("#quiz_require_lockdown_browser_for_results").attr('checked', true).change();
    });

    $("#lockdown_browser_suboptions").showIf($("#quiz_require_lockdown_browser").attr('checked'));

    $("#ip_filter").change(function() {
      $("#ip_filter_suboptions").showIf($(this).attr('checked'));
      if (!$(this).attr('checked')) {
        $("#quiz_ip_filter").val("");
      }
    }).triggerHandler('change');

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
      $dialog.dialog('close').dialog({
        autoOpen: false,
        width: 400,
        title: I18n.t('titles.ip_address_filtering', "IP Address Filtering")
      }).dialog('open');
      if (!$dialog.hasClass('loaded')) {
        $dialog.find(".searching_message").text(I18n.t('retrieving_filters', "Retrieving Filters..."));
        var url = $("#quiz_urls .filters_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.addClass('loaded');
          if (data.length) {
            for(var idx in data) {
              var filter = data[idx];
              var $filter = $dialog.find(".ip_filter.blank:first").clone(true).removeClass('blank');
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

    $("#require_access_code").change(function(event) {
      $("#access_code_suboptions").showIf($(this).attr('checked'));
      if (!$(this).attr('checked')) {
        $("#quiz_access_code").val("");
      }
    }).triggerHandler('change');

    $("#never_hide_results").change(function() {
      $(".show_quiz_results_options").showIf($(this).attr('checked'));
      if (!$(this).attr('checked')) {
        $("#hide_results_only_after_last").attr('checked', false);
        $("#quiz_show_correct_answers").attr('checked', false);
      }
    }).triggerHandler('change');

    $("#multiple_attempts_option,#limit_attempts_option,#quiz_allowed_attempts").bind('change', function() {
      var checked = $("#multiple_attempts_option").attr('checked') && $("#limit_attempts_option").attr('checked');
      var cnt = parseInt($("#quiz_allowed_attempts").val(), 10);
      if (checked && cnt && cnt > 0) {
        $("#hide_results_only_after_last_holder").show();
      } else {
        $("#hide_results_only_after_last").attr('checked', false);
        $("#hide_results_only_after_last_holder").hide();
      }
    }).triggerHandler('change');

    $quiz_options_form.find(".save_quiz_button").click(function() {
      $quiz_options_form.data('activator', 'save');
    });

    $quiz_options_form.find(".publish_quiz_button").click(function() {
      $quiz_options_form.data('activator', 'publish');
    });

    $quiz_options_form.formSubmit({
      object_name: "quiz",
      required: ['title'],

      processData: function(data) {
        $(this).attr('method', 'PUT');
        if ($(this).data('submit_type') == 'save_only') {
          delete data['activate'];
        }
        data['quiz[description]'] = $("#quiz_description").editorBox('get_code');
        var attempts = 1;
        if (data.multiple_attempts) {
          attempts = parseInt(data.allowed_attempts, 10);
          if (isNaN(attempts) || !data.limit_attempts) { attempts = -1; }
        }
        data.allowed_attempts = attempts;
        data['quiz[allowed_attempts]'] = attempts;
        return data;
      },

      beforeSubmit: function(data) {
        $(this).find(".button.save_quiz_button").attr('disabled', true);
        $(this).find(".button.publish_quiz_button").attr('disabled', true);
        if ($(this).data('activator') == 'publish') {
          $(this).find(".button.publish_quiz_button").text(I18n.t('buttons.publishing', "Publishing..."));
        } else {
          $(this).find(".button.save_quiz_button").text(I18n.t('buttons.saving', "Saving..."));
        }
      },

      success: function(data) {
        var $form = $(this);
        $(this).find(".button.save_quiz_button").attr('disabled', false);
        $(this).find(".button.publish_quiz_button").attr('disabled', false);
        if ($(this).data('activator') == 'publish') {
          $(this).find(".button.publish_quiz_button").text(I18n.t('buttons.published', "Published!"));
        } else {
          $(this).find(".button.save_quiz_button").text(I18n.t('buttons.saved', "Saved!"));
        }
        setTimeout(function() {
          $form.find(".button.save_quiz_button").text(I18n.t('buttons.save_settings', "Save Settings"));
        }, 2500);
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
        if ($(this).data('submit_type') == 'save_and_publish') {
          location.href = $(this).attr('action');
        } else {
          $.flashMessage(I18n.t('notices.quiz_data_saved', "Quiz data saved"));
        }
        quiz.updateDisplayComments();
    },
    error: function(data) {
      $(this).formErrors(data);
      $(this).find(".button.save_quiz_button").attr('disabled', false);
      $(this).find(".button.publish_quiz_button").attr('disabled', false);
      }
    });

    $quiz_options_form.find(".save_quiz_button").click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      $quiz_options_form.data('submit_type', 'save_only').submit();
    }).end().find(".publish_quiz_button").click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      $quiz_options_form.data('submit_type', 'save_and_publish').submit();
    });

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
      $("#quiz_options_form .quiz_survey_setting").showIf(assignment_id && assignment_id.match(/survey/));
      $("#quiz_points_possible").showIf(assignment_id == 'graded_survey');
      $("#survey_instructions").showIf(assignment_id == 'survey' || assignment_id == 'graded_survey');
      $("#quiz_assignment_group").showIf(assignment_id == 'assignment' || assignment_id == 'graded_survey');
      $("#questions").toggleClass('survey_quiz', assignment_id == 'survey' || assignment_id == 'graded_survey');
      $("#quiz_display_points_possible").showIf(assignment_id != 'survey' && assignment_id != 'graded_survey');
      $("#quiz_options_holder").toggleClass('survey_quiz', assignment_id == 'survey' || assignment_id == 'graded_survey');
      var url = $("#quiz_urls .update_quiz_url").attr('href');
      $("#quiz_title_input").val(quiz_title);
      $("#quiz_title_text").text(quiz_title);
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
      var question = $question.getTemplateData({
        textValues: ['question_type', 'correct_comments', 'incorrect_comments', 'neutral_comments', 'question_name', 'question_points', 'answer_selection_type', 'blank_id'],
        htmlValues: ['question_text', 'correct_comments_html', 'incorrect_comments_html', 'neutral_comments_html']
      });
      question.question_text = $question.find("textarea[name='question_text']").val();
      var matches = [];
      $question.find(".matching_answer_incorrect_matches_list li").each(function() {
        matches.push($(this).text());
      });
      question.matching_answer_incorrect_matches = matches.join("\n");
      question.question_points = parseFloat(question.question_points, 10);
      if (isNaN(question.question_points)) { question.question_points = 0; }
      var $form = $("#question_form_template").clone(true).attr('id', '');
      var $formQuestion = $form.find(".question");
      $form.fillFormData(question);
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
          $form.find(".combinations_holder .combinations thead tr").append($th);
        }
        var $th = $("<th class='final_answer'/>");
        $th.text(I18n.t('final_answer', "Final Answer"));
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
            $tr.append($td);
          }
          var text = question.answers[idx].answer_text;
          if (question.answer_tolerance) {
            text = text + " <span style='font-size: 0.8em;'>+/-</span> " + question.answer_tolerance;
          }
          var $td = $("<td class='final_answer'/>");
          $td.html(text);
          $tr.append($td);
          $form.find(".combinations tbody").append($tr);
          $form.find(".combinations_holder").show();
        }
        $form.triggerHandler('settings_change', false);
        $formQuestion.triggerHandler('recompute_variables', true);
      } else {
        $question.find(".answers .answer").each(function() {
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
      if ($question.hasClass('essay_question')) {
        $formQuestion.find(".comments_header").text(I18n.beforeLabel('comments_on_question', "Comments for this question"));
      }
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
    });

    $(".question_form :input[name='question_type']").change(function() {
      quiz.updateFormQuestion($(this).parents(".question_form"));
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

    $(document).delegate("a.comment_focus", 'focus click', function(event) {
      event.preventDefault();
      $(this).parents(".question_comment,.answer_comments").removeClass('empty')
        .find("textarea.comments").focus().select();
    });

    $(document).delegate("textarea.comments", 'focus', function() {
      $(this).parents(".question_comment,.answer_comments").removeClass('empty');
    }).delegate('textarea.comments', 'blur', function() {
      $(this).val($.trim($(this).val()));
      if ($(this).val() == "") {
        $(this).parents(".question_comment,.answer_comments").addClass('empty');
      }
    });

    $(document).delegate(".numerical_answer_type", 'change', function() {
      var val = $(this).val();
      var $answer = $(this).parents(".numerical_answer");
      $answer.find(".numerical_answer_text").hide();
      $answer.find("." + val).show();
    }).change();

    $(document).delegate(".select_answer_link", 'click', function(event) {
      event.preventDefault();
      var $question = $(this).parents(".question");
      if (!$question.hasClass('selectable')) { return; }
      if ($question.find(":input[name='question_type']").val() != "multiple_answers_question") {
        $question.find(".answer:visible").removeClass('correct_answer');
        $(this).parents(".answer").addClass('correct_answer');
      } else {
        $(this).parents(".answer").toggleClass('correct_answer');
        if ($(this).parents(".answer").hasClass('correct_answer')) {
          $(this).attr('title', I18n.t('titles.click_to_unset_as_correct', "Click to unset this answer as correct"));
        } else {
          $(this).attr('title', I18n.t('titles.click_to_set_as_correct', "Click to set this answer as correct"));
        }
      }
      $(this).blur();
    });

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
      $(this).parents(".answer").remove();
    });

    $(".add_question_group_link").click(function(event) {
      event.preventDefault();
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
      $(".question_form:visible,.group_top.editing .quiz_group_form:visible").submit();
      var $question = makeQuestion();
      if ($(this).parents(".group_top").length > 0) {
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
        .find(".submit_button").html(I18n.t('buttons.create_question', "Create Question"));
      $form.find("option.missing_word").remove();
      $question.find(".question_type").change();
      $("html,body").scrollTo({top: $question.offset().top - 10, left: 0});
      $question.find(":input:first").focus().select();
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
            bank.title = $.truncateText(bank.title)
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
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.find_question_bank', "Find Question Bank"),
        width: 600,
        height: 400
      }).dialog('open');
    });

    $findBankDialog.delegate('.bank', 'click', function() {
      $findBankDialog.find(".bank.selected").removeClass('selected');
      $(this).addClass('selected');
      $findBankDialog.find(".submit_button").attr('disabled', false);
    }).delegate('.submit_button', 'click', function() {
      var $bank = $findBankDialog.find(".bank.selected:first");
      var bank = $bank.getTemplateData({textValues: ['title'], dataValues: ['id', 'context_id', 'context_type']});
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
            bank.title = $.truncateText(bank.title)
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
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.find_quiz_question', "Find Quiz Question"),
        open: function() {
          if ($dialog.find(".selected_side_tab").length == 0) {
            $dialog.find(".bank:not(.blank):first").click();
          }
        },
        width: 600,
        height: 400
      }).dialog('open');
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
        $option.text($.truncateText(group.name));
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
        $dialog.dialog('close').dialog({
          width: 400,
          autoOpen: false
        }).dialog('open');
      }
    });

    $("#add_question_group_dialog .submit_button").click(function(event) {
      var $dialog = $("#add_question_group_dialog");
      $dialog.find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('buttons.creating_group', "Creating Group..."));
      var params = $dialog.getFormData();
      var url = $dialog.find(".add_question_group_url").attr('href');
      $.ajaxJSON(url, 'POST', params, function(data) {
        $dialog.find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.create_group', "Create Group"));

        var $group_top = $("#group_top_template").clone(true).attr('id', 'group_top_new');
        var $group_bottom = $("#group_bottom_template").clone(true).attr('id', 'group_bottom_new');
        $("#questions").append($group_top.show()).append($group_bottom.show());
        var group = data.quiz_group;
        $group_top.fillTemplateData({
          data: group,
          id: 'group_top_' + group.id,
          hrefValues: ['id']
        });
        $group_top.fillFormData(data, {object_name: 'quiz_group'});
        $("#unpublished_changes_message").slideDown();
        $group_bottom.attr('id', 'group_bottom_' + group.id);
        quiz.updateDisplayComments();

        updateFindQuestionDialogQuizGroups(data.quiz_group.id);
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
        var id = parseInt($(this).getTemplateData({textValues: ['assessment_question_id']}).assessment_question_id, 10);
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
          question.question_text = $.truncateText($div.text(), 75);
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
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.add_questions_as_group', "Add Questions as a Group")
      }).dialog('open');
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
            quiz.addExistingQuestion(question.quiz_question);
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
        answer_selection_type = "any_answer";
      } else if ($question.hasClass('essay_question')) {
        var answers = [{
          comments: I18n.t('default_response_to_essay', "Response to show student after they submit an answer")
        }];
        answer_type = "comment";
        question_type = "essay_question";
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
        answer_selection_type = "any_answer";
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
      var $answers = $form.find(".answer");
      var $question = $(this).find(".question");
      var answers = [];
      var questionData = $question.getFormData({
        values: ['question_type', 'question_name', 'question_points', 'correct_comments', 'incorrect_comments', 'neutral_comments',
          'question_text', 'answer_selection_type', 'text_after_answers', 'matching_answer_incorrect_matches']
      });
      questionData.assessment_question_bank_id = $(".question_bank_id").text() || ""
      var error_text = null;
      if (questionData.question_type == 'calculated_question') {
        if ($form.find(".combinations_holder .combinations tbody tr").length === 0) {
          error_text = I18n.t('errors.no_possible_solution', "Please generate at least one possible solution");
        }
      } else if ($answers.length === 0 || $answers.filter(".correct_answer").length === 0) {
        if ($answers.length === 0 && questionData.question_type != "essay_question" && questionData.question_type != "text_only_question") {
          error_text = I18n.t('errors.no_answer', "Please add at least one answer");
        } else if ($answers.filter(".correct_answer").length === 0 && (questionData.question_type == "multiple_choice_question" || questionData.question_type == "true_false_question" || questionData.question_tyep == "missing_word_question")) {
          error_text = I18n.t('errors.no_correct_answer', "Please choose a correct answer");
        }
      }
      if (error_text) {
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
        data.blank_id = $answer.find(".blank_id").text();
        data.answer_text = $answer.find("input[name='answer_text']:visible").val();
        if (questionData.question_type == "true_false_question") {
          data.answer_text = (i == 0) ? I18n.t('true', "True") : I18n.t('false', "False");
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
        question.answer_tolerance = parseFloat($question.find(".combination_answer_tolerance").val(), 10) || 0;
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
      var questionData = quizData($displayQuestion);
      var formData = generateFormQuiz(questionData);
      var questionData = generateFormQuizQuestion(formData);
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
        var question = data.quiz_question || data.assessment_question;
        var questionData = $.extend({}, question, question.question_data);
        // questionData.assessment_question_id might be null now because
        // question.question_data.assessment_quesiton_id might be null but
        // question.assessment_question_id is the right value. because $.extend
        // overwrites all kes that exist even if they have null values.  this
        // is hacky, the better thing to do is just get the right thing back
        // from the server.  it matters because the form when you click "find
        // questions" uses it to see if the question already exists in this
        // quiz.
        questionData.assessment_question_id = questionData.assessment_question_id || question.assessment_question_id || question.id;
        quiz.updateDisplayQuestion($displayQuestion, questionData, true);
        $("#unpublished_changes_message").slideDown();
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
      if (event.keyCode > 57 && event.keyCode < 91) {
        event.preventDefault();
      }
    }).delegate('input.float_value', 'change blur focus', function(event) {
      quiz.parseInput($(this), $(this).hasClass('long') ? 'float_long' : 'float');
    });

    $("#questions").delegate('.question_teaser_link', 'click', function(event) {
      event.preventDefault();
      var $teaser = $(this).parents(".question_teaser");
      var question_data = $teaser.data('question');
      if (!question_data) {
        $teaser.find(".teaser.question_text").text(I18n.t('loading_question', "Loading Question..."));
        $.ajaxJSON($teaser.find(".update_question_url").attr('href'), 'GET', {}, function(question) {
          showQuestion(question.quiz_question);
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
        $teaser.after($question);
        $teaser.remove();
        $question.show();
        $question.find(".question_points").text(questionData.points_possible);
        quiz.updateDisplayQuestion($question.find(".display_question"), questionData, true);
        if ($teaser.hasClass('to_edit')) {
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
        var group = data.quiz_group;
        $form.loadingImage('remove');
        var $group = $form.parents(".group_top");
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
          $group.next(".assessment_question_bank").fillTemplateData({data: bank, hrefValues: ['bank_id', 'context_type_string', 'context_id']})
            .find(".bank_name").hide().filter(".bank_name_link").show();
        }
        $group.fillFormData(data, {object_name: 'quiz_group'});
        var $bottom = $group.next();
        while($bottom.length > 0 && !$bottom.hasClass('group_bottom')) {
          $bottom = $bottom.next();
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

    $("#questions").sortable({
      handle: '.move_icon',
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
              take_with.push($obj);
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
          ui.placeholder.append("<div class='question_placeholder' style='height: " + (ui.helper.height() - 10) + "px;'>&nbsp;</div>");
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
      update: function(event, ui) {
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
        var for_question_bank = $("#questions.question_bank").length > 0;
        $.each(items, function(i, $obj) {
          if (for_question_bank) {
            var id = $obj.find(".assessment_question_id").text();
            list.push(id);
          } else if($obj.hasClass('question_holder')) {
            var $question = $obj.find('.question');
            var attrID = $question.attr('id');
            var id = attrID ? attrID.substring(9) : $question.find(".id").text();
            list.push('question_' + id);
          } else {
            var id = 'group_' + $obj.attr('id').substring(10);
            list.push(id);
          }
        });
        var data = { order: list.join(",") };
        $.ajaxJSON(url, 'POST', data, function(data) {
          $container.loadingImage('remove');
        });
      },
      stop: function(event, ui) {
        if (ui.item.hasClass('group_top')) {
          var take_with = ui.item.data('take_with');
          if (take_with) {
            var $obj = ui.item;
            for(var idx in take_with) {
              var $item = take_with[idx];
              $obj.after($item.show());
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
        .find(".expand_link").removeClass('hidden');
      var $obj = $(this).parents(".group_top").next();
      while($obj.length > 0 && $obj.hasClass('question_holder')) {
        $obj.hide();
        $obj = $obj.next();
      }
    }).delegate(".expand_link", 'click', function(event) {
      if ($(this).closest('.group_top').length == 0) { return; }
      event.preventDefault();
      $(this).parents(".group_top").find(".collapse_link").removeClass('hidden').end()
        .find(".expand_link").addClass('hidden');
      var $obj = $(this).parents(".group_top").next();
      while($obj.length > 0 && $obj.hasClass('question_holder')) {
        $obj.show();
        $obj = $obj.next();
      }
    });

    if (window.wikiSidebar) {
      wikiSidebar.init();
      wikiSidebar.attachToEditor($("#quiz_description"));
    }

    setTimeout(function() {
      $("#quiz_description").editorBox();
    }, 2000);

    $(".toggle_description_views_link").click(function(event) {
      event.preventDefault();
      $("#quiz_description").editorBox('toggle');
    });

    $(".toggle_question_content_views_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".question_form").find(".question_content").editorBox('toggle');
    });

    $(".toggle_text_after_answers_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".question_form").find(".text_after_answers").editorBox('toggle');
    });

    $(document).bind('editor_box_focus', function(event, $editor) {
      wikiSidebar.attachToEditor($editor);
    });

    $(".quiz_options_link,.link_to_content_link").click(function(event) {
      event.preventDefault();
      $("#quiz_content_links,#quiz_options_holder").toggle();
      if ($("#quiz_content_links:visible").length > 0) {
        if (window.wikiSidebar) {
          wikiSidebar.show();
        }
      } else {
        if (window.wikiSidebar) {
          wikiSidebar.hide();
        }
      }
    });

    $("#calc_helper_methods").change(function() {
      var method = $(this).val();
      $("#calc_helper_method_description").text(calcCmd.functionDescription(method));
      var code = "<pre>" + calcCmd.functionExamples(method).join("</pre><pre>") + "</pre>";
      $("#calc_helper_method_examples").html(code);
    });

    $("#equations_dialog_tabs").tabs();
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
      var text = $(this).editorBox('get_code');
      var matches = text.match(/\[[A-Za-z][A-Za-z0-9]*\]/g);
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
                .addClass(variable)
                .val(variable)
                .text(variable);
              matchHash[variable] = true;
            }
          }
        }
      }
      // if there are not any options besides the default "<option class="shown_when_no_other_options_available" value='0'>[ Enter Answer Variables Above ]</option>" one
      if (!$select.find("option:not(.shown_when_no_other_options_available)").length) {
        $select.append("<option class='shown_when_no_other_options_available' value='0'>" + I18n.t('enter_answer_variable_above', "[ Enter Answer Variables Above ]") + "</option>");
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
      } else if (cnt > maxCombinations) {
        cnt = maxCombinations;
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
      var answer_tolerance = parseFloat($question.find(".combination_answer_tolerance").val(), 10);
      var next = function() {
        $button.text(I18n.t('buttons.generating_combinations_progress', "Generating... (%{done}/%{total})", {'done': succeeded, 'total': cnt}));
        var fragment = document.createDocumentFragment();
        for(var idx = 0; idx < 5 && succeeded < cnt && failedCount < 25; idx++) {
          $variable_values.each(function() {
            $(this).find(".variable_setting:first").trigger('change', {cache: true});
          });
          $question.find(".supercalc").superCalc('recalculate', true);
          var result = $status.attr('data-res');
          var combination = [];
          $variable_values.each(function() {
            combination.push($(this).attr('data-value'));
          });
          var val = parseFloat(result.substring(1), 10);
          if (!existingCombinations[combination] || true) {
            if (result.match(/^=/) && result != "= NaN" && result != "= Infinity" && val) {
              var $result = $("<tr/>");
              $variable_values.each(function() {
                var $td = $("<td/>");
                $td.html($(this).attr('data-value'));
                $result.append($td);
              });
              var $td = $("<td/>");
              $td.addClass('final_answer');
              var text = $.trim(result.substring(1));
              var tolerance = answer_tolerance;
              if (tolerance) {
                text += " <span style='font-size: 0.8em;'>+/-</span> " + tolerance;
              }
              $td.html(text);
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
        $(this).find(".variable_setting:first").trigger('change', in_dom ? null : {recompute: true});
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
      if (!data || !options || !options.cache) {
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
      if (!options || options.template) {
        $variable.find(".value").html(val);
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
      $("#help_with_equations_dialog").dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.help_with_formulas', "Help with Quiz Question Formulas"),
        width: 500
      }).dialog('open');
    });
    $question.find(".combinations_option").attr('disabled', true);
    $question.find(".question_content").bind('keypress', function(event) {
      setTimeout(function() {$(event.target).triggerHandler('change')}, 50);
    });
    $question.find(".question_content").bind('change', function(event) {
      var text = $(this).editorBox('get_code');
      var matches = text.match(/\[[A-Za-z][A-Za-z0-9]*\]/g);
      $question.find(".variables").find("tr.variable").addClass('to_be_removed');
      $question.find(".variables").showIf(matches && matches.length > 0);
      var matchHash = {};
      if (matches) {
        for(var idx  = 0; idx < matches.length; idx++) {
          if (matches[idx]) {
            var variable = matches[idx].substring(1, matches[idx].length - 1);
            if (!matchHash[variable]) {
              var $variable = $question.find(".variables tr.variable").eq(idx);
              if ($variable.length === 0) {
                $variable = $("<tr class='variable'><td class='name'></td><td><input type='text' name='min' class='min variable_setting' style='width: 30px;' value='1'/></td><td><input type='text' name='max' class='max variable_setting' style='width: 30px;' value='10'/></td><td><select name='round' class='round variable_setting'><option>0</option><option>1</option><option>2</option><option>3</option></td><td class='value'></td></tr>");
                $question.find(".variables tbody").append($variable);
                $variable.find(".variable_setting:first").triggerHandler('change');
              }
              $variable.removeClass('to_be_removed');
              $variable.addClass(variable);
              $variable.attr('data-name', variable);
              $variable.find("td.name").text(variable);
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
  
});
