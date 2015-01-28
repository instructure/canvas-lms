/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var ChartMixin = require('../../mixins/chart');
  var round = require('canvas_quizzes/util/round');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var I18n = require('i18n!quiz_statistics');

  var CIRCLE = 2 * Math.PI;
  var FMT_PERCENT = d3.format('%');

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

  // A tween for the ratio caption (0% to 100%)
  //
  // See https://github.com/mbostock/d3/wiki/Transitions#text
  var textTween = function(newRatio) {
    var currentRatio = parseFloat(''+this.textContent) / 100.0;
    var i = d3.interpolate(currentRatio, newRatio);

    return function(t) {
      this.textContent = FMT_PERCENT(i(t));
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
        .attr('dy', '.35em')
        .text(FMT_PERCENT(0));

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
        diameter: 80,
        correctResponseRatio: 0,
        children: []
      };
    },

    getDefaultLabel: function() {
      return I18n.t('correct_response_ratio',
        '%{ratio}% of your students correctly answered this question.', {
        ratio: round(this.props.correctResponseRatio * 100.0, 0)
      });
    },

    render: function() {
      return (
        <section className="correct-answer-ratio-section">
          {this.transferPropsTo(Chart())}

          <div className="auxiliary">
            <SightedUserContent tagName="p">
              <strong>{I18n.t('correct_answer', 'Correct answer')}</strong>
            </SightedUserContent>

            <p>{this.props.label || this.getDefaultLabel()}</p>
          </div>
        </section>
      );
    }
  });

  return CorrectAnswerDonut;
});