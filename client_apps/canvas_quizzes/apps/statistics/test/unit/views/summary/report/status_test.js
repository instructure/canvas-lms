define((require) => {
  const Subject = require('jsx!views/summary/report/status');
  const $ = require('canvas_packages/jquery');

  describe('Views.Summary.Report.Status', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {});

    describe('when not yet generated', () => {
      it('should read a message', () => {
        setProps({
          generatable: true,
          file: {},
          progress: {}
        });

        expect(subject.getDOMNode().innerText).toMatch('never been generated');
      });
    });

    describe('when generating', () => {
      it('should show a progress bar', () => {
        setProps({
          generatable: true,
          isGenerating: true,
          progress: {
            completion: 0,
          }
        });

        expect('.progress').toExist();
      });

      it('should fill up the progress bar', () => {
        setProps({
          generatable: true,
          isGenerating: true,
          progress: {
            completion: 0,
          }
        });

        expect(find('.progress .bar').style.width).toBe('0%');

        setProps({
          progress: {
            completion: 25
          }
        });

        expect(find('.progress .bar').style.width).toBe('25%');
      });
    });

    describe('when generated', () => {
      it('should read the time of generation', () => {
        setProps({
          generatable: true,
          isGenerated: true,
          file: {
            createdAt: new Date(2013, 6, 18)
          },
          progress: {}
        });

        expect(subject.getDOMNode().innerText).toMatch('Generated: .* 2013');
      });
    });
  });
});
