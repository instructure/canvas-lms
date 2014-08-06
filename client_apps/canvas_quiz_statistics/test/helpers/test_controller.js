require([
  'core/delegate',
  'config',
  'lodash',
  'boot'
], function(AppDelegate, config, _, App) {
  var clone = _.clone;

  var stockConfig = clone(config);
  var container;

  beforeEach(function() {
    if (AppDelegate.isMounted()) {
      AppDelegate.unmount();
    }

    if (!jasmine.fixture) {
      container = jasmine.fixture = document.createElement('div');
      container.className = 'fixture';
      container.id = 'jasmine_content';

      if (jasmine.inspecting) {
        document.body.appendChild(container);
      }
    }
  });

  afterEach(function() {
    // Restore any config changed during tests:
    Object.keys(stockConfig).forEach(function(configKey) {
      App.config[configKey] = stockConfig[configKey];
    });

    if (!jasmine.inspecting && container) {
      try {
        container.remove();
      }
      catch(e) {
        // phantomjs whines about this
      }
      finally {
        container = jasmine.fixture = undefined;
      }
    }
  });
});