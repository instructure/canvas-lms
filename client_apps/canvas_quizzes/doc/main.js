requirejs.config({
  baseUrl: '/',
  paths: {
    'canvas_quizzes': 'apps/common/js'
  }
});

require([ 'config/requirejs/development' ], function() {
  require([
    'canvas_packages/jquery',
    'old_version_of_react_used_by_canvas_quizzes_client_apps',
    'canvas_quizzes/util/inflections',
  ], function($, React, Inflection) {
    var parseFileName = function() {
      var appName;
      var fileName = $('h1.class .class-source-link')[0].innerHTML
        .match(/([\w|\.]+)/)[1]
        .trim();

      fileName = Inflection.camelize(fileName, true).replace(/\./g, '/');
      fileName = Inflection.underscore(fileName).replace(/\/_/g, '/');
      fileName = fileName.split('/');
      appName = fileName.shift();
      fileName = fileName.join('/');

      return 'jsx!apps/' + appName + '/js/' + fileName;
    };

    $(function() {
      $(window).on('click', '.seed-name', function() {
        var $this = $(this);
        var $data = $this.next().find('.seed-data');
        var $container = $this.next().find('.seed-runner');
        var data = JSON.parse($data.text());
        var mountUp = function(props) {
          var fileName = parseFileName();

          require([ fileName ], function(Component) {
            React.unmountComponentAtNode($container[0]);
            React.renderComponent(Component(props), $container[0]);
          });
        };

        $container.text('Loading...');

        if (typeof data === 'string') {
          require([ 'text!' + data ], function(fixture) {
            mountUp(JSON.parse(fixture));
          });
        }
        else {
          mountUp(data);
        }
      });
    });
  });
});