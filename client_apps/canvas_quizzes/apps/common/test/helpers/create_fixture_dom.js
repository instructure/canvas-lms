(function() {
  var container;

  // Create a DOM element we can use to mount components we're testing in. The
  // element can be found at `jasmine.fixture` or $("#jasmine_content").
  beforeEach(function() {
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
}());