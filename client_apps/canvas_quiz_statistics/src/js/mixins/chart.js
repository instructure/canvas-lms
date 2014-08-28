define(function(require) {
  var React = require('react');

  var ChartMixin = {
    defaults: {
      updateChart: function(props) {
        this.removeChart();
        this.createChart(this.getDOMNode(), props);
      },

      removeChart: function() {
        if (this.__svg) {
          this.__svg.remove();
          delete this.__svg;
        }
      }
    },

    mixin: {
      componentWillMount: function() {
        if (typeof this.createChart !== 'function') {
          throw "ChartMixin: you must define a createChart() method that returns a d3 element";
        }

        if (!this.updateChart) {
          this.updateChart = ChartMixin.defaults.updateChart;
        }

        if (!this.removeChart) {
          this.removeChart = ChartMixin.defaults.removeChart;
        }
      },

      componentDidMount: function() {
        this.__svg = this.createChart(this.getDOMNode(), this.props);
      },

      shouldComponentUpdate: function(nextProps/*, nextState*/) {
        this.updateChart(nextProps);
        return false;
      },

      componentWillUnmount: function() {
        this.removeChart();
      },

      render: function() {
        return React.DOM.svg({ className: "chart" });
      }
    }
  };

  return ChartMixin;
});