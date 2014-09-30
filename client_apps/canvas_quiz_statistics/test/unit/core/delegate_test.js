define(function(require) {
  var Subject = require('core/delegate');
  var App = require('boot');

  describe('Delegate', function() {
    describe('#mount', function() {
      this.promiseSuite = true;

      it('should work', function() {
        var onReady = jasmine.createSpy('onAppMount');
        spyOn(console, 'warn');
        Subject.mount(jasmine.fixture).then(onReady);

        this.flush();
        expect(onReady).toHaveBeenCalled();
      });

      it('should mount the app view');
      it('should accept options', function() {
        Subject.mount(jasmine.fixture, {
          loadOnStartup: false
        });

        expect(App.config.loadOnStartup).toBe(false);
      });

      describe('config.loadOnStartup', function() {
        it('should log a warning when config.quizStatisticsUrl is missing', function() {
          var warnSpy = spyOn(console, 'warn');

          App.configure({ quizStatisticsUrl: null });
          Subject.mount(jasmine.fixture);
          this.flush();

          expect(warnSpy).toHaveBeenCalled();
        });
      });
    });
  });
});