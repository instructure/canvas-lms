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

 // This is now just a text element, not a donut chart.
 // Name is retained to avoid a larger refactor.

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var round = require('canvas_quizzes/util/round');
  var I18n = require('i18n!quiz_statistics').default;
  // A formatter for the ratio text
  var getLabel = function(ratio) {
    return I18n.t('%{ratio}% answered correctly', {
      ratio: round(ratio * 100.0, 0)
    });
  };
  var CorrectAnswerDonut = React.createClass({
    propTypes: {
      correctResponseRatio: React.PropTypes.number.isRequired
    },
    render: function() {
      return (
        <section className="correct-answer-ratio-section">
          <p>
            {getLabel(this.props.correctResponseRatio)}
          </p>
        </section>
      );
    }
  });
  return CorrectAnswerDonut;
});