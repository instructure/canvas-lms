define([
  'react',
  'react-addons-test-utils',
  'jsx/external_apps/components/ConfigurationFormManual'
], (React, TestUtils, ConfigurationFormManual) => {

  QUnit.module('External Apps Manual Configuration Form');

  const fakeStore = {
    findAppByShortName () {
      return {
        short_name: 'someApp',
        config_options: []
      };
    }
  };

  const component = TestUtils.renderIntoDocument (
    <ConfigurationFormManual
      domain=''
      description=''
      shortName="someApp"
      store={fakeStore}
    />
  );

    test('domain field should not be null', () => {

      const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormManual);

      equal(app.props.domain, '');
    });

    test('description field should not be null', () => {

      const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormManual);

      equal(app.props.description, '');
    });

});
