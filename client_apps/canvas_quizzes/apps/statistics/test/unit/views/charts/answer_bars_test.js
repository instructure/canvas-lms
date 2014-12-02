define(function(require) {
  var Subject = require('jsx!views/charts/answer_bars');
  var $ = require('canvas_packages/jquery');
  var React = require('react');
  var d3 = require('d3');

  describe('Views.Charts.AnswerBars', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should show a tooltip when hovering over a bar', function() {
      var rect;

      setProps({
        answers: [
          { id: '1', correct: true, responses: 4, ratio: 4/6.0 },
          { id: '2', correct: false, responses: 2, ratio: 2/6.0 },
        ]
      });

      expect(findAll('rect.bar').length).toBe(2);
      rect = find('rect.bar:first');
      // can't really simulate a mouseover to trigger d3's event handler, we'll
      // have to manually trigger things:
      d3.event = { target: rect };
      subject.refs.chart.inspect({ id: '1' });

      expect($('.qtip .answer-distribution-tooltip-content').length).toBe(1,
        'should show answer details in the tooltip');
    });
  });
});