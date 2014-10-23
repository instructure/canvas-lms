define(function(require) {
  var React = require('react');

  var getChartNode = function(component) {
    var ref = (component.refs || {}).chart || component;
    return ref.getDOMNode();
  };

  var ChartMixin = {
    defaults: {
      updateChart: function(props) {
        this.removeChart();
        this.__svg = this.createChart(getChartNode(this), props);
      },

      render: function() {
        return React.DOM.svg({ className: "chart" });
      },

      removeChart: function() {
        if (this.__svg) {
          this.__svg.remove();
          delete this.__svg;
        }
      }
    },

    addTitle: function(svg, title) {
      svg.append('title').text(title);
    },

    addDescription: function(svg, description) {
      svg.append('text')
        .attr('fill', 'transparent')
        .attr('font-size', '0px')
        .text(description);
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
        this.__svg = this.createChart(getChartNode(this), this.props);
      },

      shouldComponentUpdate: function(nextProps/*, nextState*/) {
        this.updateChart(nextProps);
        return false;
      },

      componentWillUnmount: function() {
        this.removeChart();
      },

    }
  };

  return ChartMixin;
});