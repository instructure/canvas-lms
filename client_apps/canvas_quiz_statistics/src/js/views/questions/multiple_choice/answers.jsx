/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Answers = React.createClass({
    getDefaultProps: function() {
      return {
        answers: []
      };
    },

    render: function() {
      // .detail-section CSS class makes this section controllable by the
      // "Toggle Details" button
      return(
        <ol className="answer-drilldown detail-section">
          {this.props.answers.map(this.renderAnswer)}
        </ol>
      );
    },

    renderAnswer: function(answer) {
      return (
        <li
          key={'answer-'+answer.id}
          className={answer.correct ? 'correct' : undefined}>
          <span className="answer-response-ratio">
            {answer.ratio} <sup>%</sup>
          </span>

          <div className="answer-text">
            {answer.text}
          </div>
        </li>
      );
    }
  });

  return Answers;
});