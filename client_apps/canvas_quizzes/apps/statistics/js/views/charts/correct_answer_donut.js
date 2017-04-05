/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var d3 = require('d3');
  var ChartMixin = require('../../mixins/chart');
  var round = require('canvas_quizzes/util/round');
  // var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var I18n = require('i18n!quiz_statistics');

  var CIRCLE = 2 * Math.PI;
  var Y_OFFSETS = [-5,15,15];

  // A tween for the foreground of the donut.
  //
  // See https://github.com/mbostock/d3/wiki/Transitions#attrTween
  var arcTween = function(arc, transition, newAngle) {
    transition.attrTween('d', function(d) {
      var interpolate = d3.interpolate(d.endAngle, newAngle);

      return function(t) {
        d.endAngle = interpolate(t);

        return arc(d);
      };
    });
  };

  // Thanks SVG 1.1, no wrapping in SVG text
  // http://stackoverflow.com/questions/13241475/how-do-i-include-newlines-in-labels-in-d3-charts
  var addLineBreaks = function() {
    var element = d3.select(this);
    var words = element.text().split(" ");
    element.text('');

    for (var i=0; i < words.length; i++) {
      var tspan = element.append("tspan").text(words[i]);
      tspan.attr('x', 1).attr('dy', Y_OFFSETS[i]);
      if (i > 0) {
        tspan.attr("class", "subcaption");
      }
    }
  };

  // A formatter for the text label on the donut chart
  var getLabel = function(ratio) {
    return I18n.t('%{ratio}% answered correctly', {
      ratio: round(ratio * 100.0, 0)
    });
  };

  // A tween for the ratio caption (0% to 100%)
  //
  // See https://github.com/mbostock/d3/wiki/Transitions#text
  var textTween = function(newRatio) {
    var currentRatio = parseFloat(''+this.textContent) / 100.0;
    var i = d3.interpolate(currentRatio, newRatio);


    return function(t) {
      this.textContent = getLabel(i(t));
      d3.select(this).each(addLineBreaks);
    };
  };

  var Chart = React.createClass({
    mixins: [ ChartMixin.mixin ],

    getDefaultProps: function() {
      return {
        animeDuration: 500
      };
    },

    createChart: function(node, props) {
      var diameter = props.diameter;
      var radius = diameter / 2;
      var ratio = props.correctResponseRatio;
      var arc, foreground, caption;

      var svg = d3.select(node)
        .attr('width', radius)
        .attr('height', radius)
        .attr('aria-hidden', true)
        .append('g')
          .attr('transform', 'translate(' + radius + ',' + radius + ')');

      arc = d3.svg.arc()
        .innerRadius(radius)
        .outerRadius(diameter / 2.5)
        .startAngle(0);

      // background circle that's always "empty" (shaded in light color)
      svg.append('path')
        .datum({ endAngle: CIRCLE })
        .attr('class', 'background')
        .attr('d', arc);

      // foreground circle that fills up based on ratio (green, or flashy)
      foreground = svg.append('path')
        .datum({ endAngle: 0 })
        .attr('class', 'foreground')
        .attr('d', arc);

      // text inside the circle
      caption = svg.selectAll('text').data([ ratio ]);
      caption.enter().append('text')
        .attr('text-anchor', 'middle')
        .text(getLabel(props.correctResponseRatio));

      // we need these for updating
      this.arc = arc;
      this.foreground = foreground;
      this.caption = caption;

      this.updateChart(svg, props);

      return svg;
    },

    updateChart: function(svg, props) {
      var ratio = props.correctResponseRatio;

      this.foreground
        .transition()
        .duration(props.animeDuration)
        .call(arcTween.bind(null, this.arc), CIRCLE * ratio);

      this.caption.datum(ratio).transition()
        .duration(props.animeDuration)
        .tween('text', textTween);
    },

    render: ChartMixin.defaults.render
  });

  var CorrectAnswerDonut = React.createClass({
    propTypes: {
      correctResponseRatio: React.PropTypes.number.isRequired
    },

    getDefaultProps: function() {
      return {
        /**
         * @cfg {Number} [radius=80]
         *      Diameter of the donut chart in pixels.
         */
        diameter: 120,
        correctResponseRatio: 0,
        children: []
      };
    },

    render: function() {
      return (
        <section className="correct-answer-ratio-section">
          {this.transferPropsTo(Chart())}
        </section>
      );
    }
  });

  return CorrectAnswerDonut;
});