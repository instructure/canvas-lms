define([
  'jquery',
  'react',
  'react-dom',
  'jsx/files/Breadcrumbs',
  'compiled/models/Folder',
  'helpers/fakeENV'
], ($, React, ReactDOM, Breadcrumbs, Folder, fakeENV) => {

  const TestUtils = React.addons.TestUtils

  module('Files Breadcrumbs Component', {
    setup () {
      fakeENV.setup({context_asset_string: 'course_1'});
    },
    teardown() {
      $('#fixtures').empty();
      fakeENV.teardown();
    }
  });

  test('generates the home, rootFolder, and other links', () => {

    const sampleProps = {
      rootTillCurrentFolder: [
        new Folder({context_type: 'course', context_id: 1}),
        new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'})
      ],
      contextAssetString: 'course_1'
    };

    const component = TestUtils.renderIntoDocument(
      <Breadcrumbs {...sampleProps} />
    , $('#fixtures')[0]);

    const links = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a');
    ok(links.length === 4);
    equal(links[0].props.href, '/', 'correct home url');
    equal(links[2].props.href, '/courses/1/files', 'rootFolder link has correct url');
    equal(links[3].props.href, '/courses/1/files/folder/test_folder_name', 'correct url for child');
    equal(ReactDOM.findDOMNode(links[3]).text, 'test_folder_name', 'shows folder names');
  });

});
