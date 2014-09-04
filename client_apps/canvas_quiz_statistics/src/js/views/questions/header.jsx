/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_statistics');
  var ToggleDetailsButton = require('jsx!./toggle_details_button');

  var QuestionHeader = React.createClass({
    getDefaultProps: function() {
      return {
        responseCount: 0,
        participantCount: 0,
        onToggleDetails: null
      };
    },

    render: function() {
      return (
        <header>
          <span className="question-attempts">
            {I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
              count: this.props.responseCount,
              total: this.props.participantCount
            })}
          </span>

          <aside className="pull-right">
            <ToggleDetailsButton
              onClick={this.props.onToggleDetails}
              expanded={this.props.expanded} />
          </aside>

          <div
            className="question-text"
            dangerouslySetInnerHTML={{ __html: this.props.questionText }}
            />
        </header>
      );
    }
  });

  return QuestionHeader;
});