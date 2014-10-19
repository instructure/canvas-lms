/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_statistics');
  var ToggleDetailsButton = require('jsx!./toggle_details_button');
  var ScreenReaderContent = require('jsx!../../components/screen_reader_content');

  var QuestionHeader = React.createClass({
    getDefaultProps: function() {
      return {
        position: 1,
        responseCount: 0,
        participantCount: 0,
        onToggleDetails: null,
        expandable: true,
        asideContents: false
      };
    },

    render: function() {
      return (
        <header>
          <ScreenReaderContent tagName="h3">
            {I18n.t('question_header', 'Question %{position}', { position: this.props.position })}
          </ScreenReaderContent>

          {/*
            we'd like SR to read the question description after its position
          */}
          <ScreenReaderContent
            dangerouslySetInnerHTML={{ __html: this.props.questionText }}
            />

          <span className="question-attempts">
            {I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
              count: this.props.responseCount,
              total: this.props.participantCount
            })}
          </span>

          <div className="pull-right">
            {this.props.expandable &&
              <ToggleDetailsButton
                onClick={this.props.onToggleDetails}
                expanded={this.props.expanded} />
            }

            {this.props.asideContents}
          </div>

          {/* hide from SR since it's been read earlier */}
          <div
            className="question-text"
            aria-hidden
            dangerouslySetInnerHTML={{ __html: this.props.questionText }}
            />
        </header>
      );
    }
  });

  return QuestionHeader;
});
