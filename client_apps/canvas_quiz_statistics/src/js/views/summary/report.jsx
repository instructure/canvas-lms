/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var $ = require('canvas_packages/jquery');
  var Tooltip = require('canvas_packages/tooltip');
  var Status = require('jsx!./report/status');
  var I18n = require('i18n!quiz_reports');

  var Report = React.createClass({
    mixins: [ React.addons.ActorMixin ],

    propTypes: {
      generatable: React.PropTypes.bool
    },

    getInitialState: function() {
      return {
        tooltipContent: '',
        statusLayer: null
      };
    },

    getDefaultProps: function() {
      return {
        readableType: 'Analysis Report',
        generatable: true,
        isGenerated: false,
        downloadUrl: undefined
      };
    },

    componentDidMount: function() {
      var container = document.createElement('div');
      var tooltip = $(this.getDOMNode()).tooltip({
        tooltipClass: 'center bottom vertical',
        show: false,
        hide: false,
        items: $(this.getDOMNode()),
        position: {
          my: 'center bottom',
          at: 'center top'
        },
        content: function() {
          return container;
        }
      }).data('tooltip');

      this.setState({
        statusContainer: container,
        statusLayer: React.renderComponent(Status(), container),
        tooltip: tooltip
      });
    },

    componentDidUpdate: function(prevProps/*, prevState*/) {
      this.state.statusLayer.setProps(this.props, function() {
        var tooltip = this.state.tooltip;
        var $tooltip = tooltip._find($(tooltip.options.items));
        var $anchor = $(this.getDOMNode());

        tooltip.option('items', $anchor);

        if ($tooltip.length) {
          $tooltip.position({
            my: 'center bottom',
            at: 'center top',
            of: $anchor
          });
        }
      }.bind(this));
    },

    componentWillUnmount: function() {
      this.state.tooltip.destroy();
      React.unmountComponentAtNode(this.state.statusLayer);
    },

    render: function() {
      return (
        <div className="report-generator inline">
          {this.props.isGenerated ?
            this.renderDownloader() :
            this.renderGenerator()
          }
        </div>
      );
    },

    renderGenerator: function() {
      return (
        <button
          disabled={!this.props.generatable}
          onClick={this.onGenerate}
          className="btn btn-link generate-report">
          <i className="icon-analytics" /> {this.props.readableType}
        </button>
      );
    },

    renderDownloader: function() {
      return(
        <a href={this.props.file.url} className="btn btn-link download-report">
          <i className="icon-analytics" /> {this.props.readableType}
        </a>
      );
    },

    onGenerate: function(e) {
      e.preventDefault();

      this.sendAction('quizReports:generate', this.props.reportType);
    }
  });

  return Report;
});