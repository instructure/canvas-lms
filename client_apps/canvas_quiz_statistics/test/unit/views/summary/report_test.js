define(function(require) {
  var Subject = require('jsx!views/summary/report');
  var $ = require('canvas_packages/jquery');

  describe('Views.Summary.Report', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('should be a button if it can be generated', function() {
      setProps({ isGenerated: false });

      expect('button.generate-report').toExist();
    });

    it('should be an anchor if it can be downloaded', function() {
      setProps({
        isGenerated: true,
        file: {
          createdAt: new Date(),
          url: 'http://foobar.com/'
        }
      });

      expect('a.download-report').toExist();
      expect(find('a.download-report').href).toBe('http://foobar.com/');
    });

    it('should emit quizReports:generate', function() {
      setProps({
        generatable: true,
        reportType: 'student_analysis'
      });

      expect(function() {
        click('button.generate-report');
      }).toSendAction({
        action: 'quizReports:generate',
        args: 'student_analysis'
      });
    });

    it('should mount a Status inside a tooltip', function() {
      var $node, $target;
      var onTooltipOpen = jasmine.createSpy();

      setProps({
        generatable: true,
        file: {
          url: 'http://something.com',
          createdAt: '04/04/2014'
        }
      });

      $node = $(subject.getDOMNode());
      $node.on('tooltipopen', onTooltipOpen);
      $target = $(find('button'));
      $target.mouseover();

      expect(onTooltipOpen).toHaveBeenCalled();
      expect($('.ui-tooltip-content .quiz-report-status')[0]).toExist();
    });
  });
});