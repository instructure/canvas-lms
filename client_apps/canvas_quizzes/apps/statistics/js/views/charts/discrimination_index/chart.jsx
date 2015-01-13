/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var ChartMixin = require('../../../mixins/chart');

  var Chart = React.createClass({
    mixins: [ ChartMixin.mixin ],

    getDefaultProps: function() {
      return {
        correct: [],
        total: [],
        ratio: []
      };
    },

    createChart: function(node, props) {
      var barHeight, barWidth, svg;

      barHeight = props.height / 3;
      barWidth = props.width / 2;

      svg = d3.select(node)
        .attr('width', props.width)
        .attr('height', props.height)
        .append('g');

      svg.selectAll('.bar.correct')
        .data(props.ratio)
        .enter()
          .append('rect')
          .attr('class', 'bar correct')
          .attr('x', barWidth)
          .attr('width', function(correctRatio) {
            return correctRatio * barWidth;
          }).attr('y', function(d, bracket) {
            return bracket * barHeight;
          }).attr('height', function() {
            return barHeight - 1;
          });

      svg.selectAll('.bar.incorrect')
        .data(props.ratio)
        .enter()
          .append('rect')
          .attr('class', 'bar incorrect')
          .attr('x', function(correctRatio) {
            return -1 * (1 - correctRatio * barWidth);
          }).attr('width', function(correctRatio) {
            return (1 - correctRatio) * barWidth;
          }).attr('y', function(d, bracket) {
            return bracket * barHeight;
          }).attr('height', function() {
            return barHeight - 1;
          });

      this.__svg = svg;

      return svg;
    },

    render: ChartMixin.defaults.render
  });

  return Chart;
});
