define(function(require) {
  var Subject = require('jsx!views/summary/report/status');
  var $ = require('canvas_packages/jquery');

  describe('Views.Summary.Report.Status', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});

    describe('when not yet generated', function() {
      it('should read a message', function() {
        setProps({
          generatable: true,
          file: {},
          progress: {}
        });

        expect(subject.getDOMNode().innerText).toMatch('never been generated');
      });
    });

    describe('when generating', function() {
      it('should show a progress bar', function() {
        setProps({
          generatable: true,
          progress: {
            completion: 0,
            workflowState: 'running'
          }
        });

        expect('.progress').toExist();
      });

      it('should fill up the progress bar', function() {
        setProps({
          generatable: true,
          progress: {
            completion: 0,
            workflowState: 'running'
          }
        });

        expect(find('.progress .bar').style.width).toBe('0%');

        setProps({
          progress: {
            workflowState: 'running',
            completion: 25
          }
        });

        expect(find('.progress .bar').style.width).toBe('25%');
      });
    });

    describe('when generated', function() {
      it('should read the time of generation', function() {
        setProps({
          generatable: true,
          isGenerated: true,
          file: {
            createdAt: new Date(2013, 6, 18)
          },
          progress: {}
        });

        expect(subject.getDOMNode().innerText).toMatch('Generated at .* 2013');
      });
    });
  });
});