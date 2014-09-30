/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ScreenReaderContent = require('jsx!../../components/screen_reader_content');
  var I18n = require('i18n!quiz_statistics.answer_details');

  var ToggleDetailsButton = React.createClass({
    propTypes: {
      expanded: React.PropTypes.bool.isRequired,
      onClick: React.PropTypes.func,
      controlsAll: React.PropTypes.bool
    },

    getDefaultProps: function() {
      return {
        expanded: false,
        controlsAll: false
      };
    },

    render: function() {
      var isExpanded = this.props.expanded;
      var controlsAll = this.props.controlsAll;
      var label;

      if (isExpanded && controlsAll) {
        label = I18n.t('hide_all', 'Hide answer details for all questions');
      }
      else if (!isExpanded && controlsAll) {
        label = I18n.t('show_all', 'Show answer details for all questions');
      }
      else if (isExpanded) {
        label = I18n.t('hide', 'Hide answer details');
      }
      else {
        label = I18n.t('show', 'Show answer details');
      }

      return(
        <button title={label} onClick={this.props.onClick} className="btn">
          <ScreenReaderContent children={label} />

          {isExpanded ?
            <i className="icon-collapse" /> :
            <i className="icon-expand" />
          }
        </button>
      );
    }
  });

  return ToggleDetailsButton;
});