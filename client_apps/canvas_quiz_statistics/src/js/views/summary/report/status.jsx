/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_reports');
  var Descriptor = require('../../../models/quiz_report_descriptor');

  var Status = React.createClass({
    propTypes: {
      generatable: React.PropTypes.bool,
      isGenerated: React.PropTypes.bool,

      file: React.PropTypes.shape({
        createdAt: React.PropTypes.string,
      }),

      progress: React.PropTypes.shape({
        workflowState: React.PropTypes.string,
        completion: React.PropTypes.number,
      }),
    },

    getInitialState: function() {
      return {
        justBeenGenerated: false
      };
    },

    getDefaultProps: function() {
      return {
        generatable: true,
        file: {},
        progress: {}
      };
    },

    componentWillReceiveProps: function(nextProps) {
      if (this.props.isGenerating && nextProps.isGenerated) {
        this.setState({
          justBeenGenerated: true
        });
      }
    },

    render: function() {
      var label = Descriptor.getDetailedStatusLabel(this.props, this.state.justBeenGenerated);

      return (
        <div className="quiz-report-status">
          {this.props.isGenerating ? this.renderProgress(label) : label}
        </div>
      );
    },

    renderProgress: function(label) {
      var completion = this.props.progress.completion;

      return (
        <div className="auxiliary">
          <p>
            <span className="screenreader-only" children={label} />
            <span aria-hidden="true">
              {I18n.t('generating', 'Report is being generated...')}
            </span>
          </p>

          <div className="progress">
            <div className="bar" style={{ width: (completion || 0) + '%' }} />
          </div>
        </div>
      );
    }
  });

  return Status;
});