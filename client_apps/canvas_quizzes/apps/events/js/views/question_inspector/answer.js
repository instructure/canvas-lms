/** @jsx React.DOM */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_log_auditing').default;
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