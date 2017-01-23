requirejs.config({
  baseUrl: '/',
  paths: {
    canvas_quizzes: 'apps/common/js'
  }
});

require(['config/requirejs/development'], () => {
  require([
    'canvas_packages/jquery',
    'old_version_of_react_used_by_canvas_quizzes_client_apps',
    'canvas_quizzes/util/inflections',
  ], ($, React, Inflection) => {
    const parseFileName = function () {
      let appName;
      let fileName = $('h1.class .class-source-link')[0].innerHTML
        .match(/([\w|\.]+)/)[1]
        .trim();

      fileName = Inflection.camelize(fileName, true).replace(/\./g, '/');
      fileName = Inflection.underscore(fileName).replace(/\/_/g, '/');
      fileName = fileName.split('/');
      appName = fileName.shift();
      fileName = fileName.join('/');

      return `jsx!apps/${appName}/js/${fileName}`;
    };

    $(() => {
      $(window).on('click', '.seed-name', function () {
        const $this = $(this);
        const $data = $this.next().find('.seed-data');
        const $container = $this.next().find('.seed-runner');
        const data = JSON.parse($data.text());
        const mountUp = function (props) {
          const fileName = parseFileName();

          require([fileName], (Component) => {
            React.unmountComponentAtNode($container[0]);
            React.renderComponent(Component(props), $container[0]);
          });
        };

        $container.text('Loading...');

        if (typeof data === 'string') {
          require([`text!${data}`], (fixture) => {
            mountUp(JSON.parse(fixture));
          });
        } else {
          mountUp(data);
        }
      });
    });
  });
});
