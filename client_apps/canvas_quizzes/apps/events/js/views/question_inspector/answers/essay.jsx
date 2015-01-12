/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var K = require('../../../constants');
  var Button = require('jsx!../../../components/button');
  var I18n = require('i18n!quiz_log_auditing.question_answers.essay');

  var Essay = React.createClass({
    statics: {
      questionTypes: [ K.Q_ESSAY ]
    },

    getDefaultProps: function() {
      return {
        answer: ''
      };
    },

    getInitialState: function() {
      return {
        htmlView: false
      };
    },

    render: function() {
      var content;

      if (this.state.htmlView) {
        content = (
          <div dangerouslySetInnerHTML={{__html: this.props.answer }} />
        );
      }
      else {
        content = <pre>{this.props.answer}</pre>;
      }

      return (
        <div>
          {content}

          <Button type="default" onClick={this.toggleView}>
            {this.state.htmlView ?
              I18n.t('view_plain_answer', 'View Plain') :
              I18n.t('view_html_answer', 'View HTML')
            }
          </Button>
        </div>
      );
    },

    toggleView: function() {
      this.setState({ htmlView: !this.state.htmlView });
    }
  });

  return Essay;
});