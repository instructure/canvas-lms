define((require) => {
  const Subject = require('core/delegate');
  const App = require('main');

  describe('Delegate', () => {
    describe('#mount', function () {
      this.promiseSuite = true;

      it('should work', function () {
        const onReady = jasmine.createSpy('onAppMount');
        spyOn(console, 'warn');
        Subject.mount(jasmine.fixture).then(onReady);

        this.flush();
        expect(onReady).toHaveBeenCalled();
      });

      it('should mount the app view');
      it('should accept options', () => {
        Subject.mount(jasmine.fixture, {
          loadOnStartup: false
        });

        expect(App.config.loadOnStartup).toBe(false);
      });

      describe('config.loadOnStartup', () => {
        it('should log a warning when config.quizStatisticsUrl is missing', function () {
          const warnSpy = spyOn(console, 'warn');

          App.configure({ quizStatisticsUrl: null });
          Subject.mount(jasmine.fixture);
          this.flush();

          expect(warnSpy).toHaveBeenCalled();
        });
      });
    });
  });
});
