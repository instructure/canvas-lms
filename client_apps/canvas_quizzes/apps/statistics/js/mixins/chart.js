define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');

  var getChartNode = function(component) {
    var ref = (component.refs || {}).chart || component;
    return ref.getDOMNode();
  };

  var ChartMixin = {
    defaults: {
      updateChart: function(svg, props) {
        this.removeChart();
        this.__svg = this.createChart(getChartNode(this), props);
      },

      render: function() {
        return React.DOM.div({ref: 'wrapper'}, {}, React.DOM.svg({ className: "chart", ref: 'chart'}));
      },

      removeChart: function() {
        if (this.__svg) {
          this.__svg.remove();
          delete this.__svg;
        }
      }
    },

    addTitle: function(svg, title) {
      return svg.append('title').text(title);
    },

    addDescription: function(holder, description) {
      return holder.append('text')
        .attr('tabindex', '0')
        .attr('class', 'screenreader-only')
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
        this.updateChart(this.__svg, nextProps);
        return false;
      },

      componentWillUnmount: function() {
        this.removeChart();
      },

    }
  };

  return ChartMixin;
});