/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'jquery',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/files/Breadcrumbs',
  'compiled/models/Folder',
  '../../../../coffeescripts/helpers/fakeENV',
  'compiled/react_files/modules/filesEnv',
], ($, React, ReactDOM, TestUtils, Breadcrumbs, Folder, fakeENV, filesEnv) => {

  QUnit.module('Files Breadcrumbs Component', {
    setup () {
      fakeENV.setup({context_asset_string: 'course_1'});
      filesEnv.baseUrl = '/courses/1/files';
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
