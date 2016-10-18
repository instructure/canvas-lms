define([
  'react',
  'react-addons-test-utils',
  'jsx/external_apps/components/AppDetails',
  'jsx/external_apps/lib/AppCenterStore'
], (React, TestUtils, AppDetails, AppCenterStore) => {

  module('External Apps App Details');

  test('the back to app center link goes to the proper place', () => {

    const fakeStore = {
      findAppByShortName () {
        return {
          short_name: 'someApp',
          config_options: []
        };
      }
    };

    const component = TestUtils.renderIntoDocument(
      <AppDetails
        baseUrl="/someUrl"
        shortName="someApp"
        store={fakeStore}
      />
    );

    const link = TestUtils.findRenderedDOMComponentWithClass(component, 'app_cancel');

    equal(link.props.href, '/someUrl', 'the url matches appropriately');
  });

});