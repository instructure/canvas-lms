/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var $ = require('canvas_packages/jquery');
  var Tooltip = require('canvas_packages/tooltip');

  var Report = React.createClass({
    mixins: [ React.addons.ActorMixin ],

    propTypes: {
      generatable: React.PropTypes.bool
    },

    getInitialState: function() {
      return {
        tooltipContent: null
      };
    },

    getDefaultProps: function() {
      return {
        readableType: 'Analysis Report',
        generatable: false,
        downloadUrl: undefined
      };
    },

    componentDidMount: function() {
      $(this.getDOMNode()).tooltip({
        content: function() {
          return this.state.tooltipContent;
        }.bind(this)
      });
    },

    componentDidUpdate: function(prevProps, prevState) {

    },

    componentWillUnmount: function() {
      $(this.getDOMNode()).tooltip('destroy');
    },

    render: function() {
      return (
        <div className="report-generator inline">{
          this.props.generatable ?
            this.renderGenerator() :
            this.renderDownloader()
          }
        </div>
      );
    },

    renderGenerator: function() {
      return (
        <button title="adooken" onClick={this.onGenerate} className="btn btn-link generate-report">
          <i className="icon-analytics" /> {this.props.readableType}
        </button>
      );
    },

    renderDownloader: function() {
      return(
        <a href={this.props.downloadUrl} className="btn btn-link">
          <i className="icon-analytics" /> {this.props.readableType}
        </a>
      );
    },

    onGenerate: function(e) {
      e.preventDefault();

      this.sendAction('statistics:generateReport', this.props.reportType);
    }
  });

  return Report;
});