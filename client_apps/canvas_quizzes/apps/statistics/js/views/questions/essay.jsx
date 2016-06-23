/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Question = require('jsx!../question');
  // var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var QuestionHeader = require('jsx!./header');
  var I18n = require('i18n!quiz_statistics');
  var AnswerTable = require('jsx!./answer_table');

  var Essay = React.createClass({
    render: function() {
      var props = this.props;

      return(
        <Question>
          <div className="grid-row">
            <div className="col-sm-8 question-top-left">
              <QuestionHeader
                responseCount={this.props.responses}
                participantCount={this.props.participantCount}
                questionText={this.props.questionText}
                position={this.props.position} />

              <div
                className="question-text"
                aria-hidden
                dangerouslySetInnerHTML={{ __html: this.props.questionText }} />
            </div>
            <div className="col-sm-4 question-top-right">
            </div>
          </div>
          <div className="grid-row">
            <div className="col-sm-8 question-bottom-left">
              <AnswerTable answers={this.props.answers} useAnswerBuckets={true} />
              {this.renderLinkButton()}
            </div>
            <div className="col-sm-4 question-bottom-right"></div>
          </div>
        </Question>
      );
    },

    renderLinkButton: function() {
      return (
        <a className="btn" href={this.props.speedGraderUrl} target="_blank" style={{marginBottom: "20px", maxWidth: "50%"}}>
          {I18n.t('speedgrader', 'View in SpeedGrader')}
        </a>
      );
    }
  });

  return Essay;
});