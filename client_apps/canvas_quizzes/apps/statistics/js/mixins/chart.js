define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');

  const getChartNode = function (component) {
    const ref = (component.refs || {}).chart || component;
    return ref.getDOMNode();
  };

  var ChartMixin = {
    defaults: {
      updateChart (svg, props) {
        this.removeChart();
        this.__svg = this.createChart(getChartNode(this), props);
      },

      render () {
        return React.DOM.div({ ref: 'wrapper' }, {}, React.DOM.svg({ className: 'chart', ref: 'chart' }));
      },

      removeChart () {
        if (this.__svg) {
          this.__svg.remove();
          delete this.__svg;
        }
      }
    },

    addTitle (svg, title) {
      return svg.append('title').text(title);
    },

    addDescription (holder, description) {
      return holder.append('text')
        .attr('tabindex', '0')
        .attr('class', 'screenreader-only')
        .text(description);
    },

    mixin: {
      componentWillMount () {
        if (typeof this.createChart !== 'function') {
          throw 'ChartMixin: you must define a createChart() method that returns a d3 element';
        }

        if (!this.updateChart) {
          this.updateChart = ChartMixin.defaults.updateChart;
        }

        if (!this.removeChart) {
          this.removeChart = ChartMixin.defaults.removeChart;
        }
      },

      componentDidMount () {
        this.__svg = this.createChart(getChartNode(this), this.props);
      },

      shouldComponentUpdate (nextProps/* , nextState*/) {
        this.updateChart(this.__svg, nextProps);
        return false;
      },

      componentWillUnmount () {
        this.removeChart();
      },

    }
  };

  return ChartMixin;
});
