/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_log_auditing');
  var classSet = require('canvas_quizzes/util/class_set');
  var MultipleChoice = require('jsx!./answers/multiple_choice');
  var MultipleAnswers = require('jsx!./answers/multiple_answers');
  var MultipleDropdowns = require('jsx!./answers/multiple_dropdowns');
  var Essay = require('jsx!./answers/essay');
  var FIMB = require('jsx!./answers/fill_in_multiple_blanks');
  var Matching = require('jsx!./answers/matching');

  var Renderers;

  var GenericRenderer = React.createClass({
    render: function() {
      return <div>{''+this.props.answer}</div>;
    }
  });

  var Renderers = [ FIMB, Matching, MultipleAnswers, MultipleChoice, MultipleDropdowns, Essay ];

  var getRenderer = function(questionType) {
    return Renderers.filter(function(entry) {
      if (entry.questionTypes.indexOf(questionType) > -1) {
        return true;
      }
    })[0] || GenericRenderer;
  };

  var Answer = React.createClass({
    render: function() {
      return getRenderer(this.props.question.questionType)(this.props);
    }
  });

  return Answer;
});