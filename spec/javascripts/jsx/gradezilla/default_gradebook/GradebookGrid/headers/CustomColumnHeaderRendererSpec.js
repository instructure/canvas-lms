/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!gradebook';
import ReactDOM from 'react-dom';
import { createGradebook, setFixtureHtml } from '../../GradebookSpecHelper';
import CustomColumnHeaderRenderer
from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/CustomColumnHeaderRenderer';

QUnit.module('CustomColumnHeaderRenderer', function (suiteHooks) {
  let $container;
  let gradebook;
  let column;
  let renderer;
  let component;

  function render () {
    renderer.render(column, $container, {} /* gridSupport */, { ref (ref) { component = ref } });
  }

  suiteHooks.beforeEach(function () {
    $container = document.createElement('div');
    document.body.appendChild($container);
    setFixtureHtml($container);

    gradebook = createGradebook();
    gradebook.gotCustomColumns([
      { id: '2401', teacher_notes: true, title: 'Notes' },
      { id: '2402', teacher_notes: false, title: 'Other Notes' }
    ]);
    column = { id: gradebook.getCustomColumnId('2401'), customColumnId: '2401' };
    renderer = new CustomColumnHeaderRenderer(gradebook);
  });

  suiteHooks.afterEach(function() {
    $container.remove();
  });

  QUnit.module('#render', function () {
    test('renders the CustomColumnHeader to the given container node', function () {
      render();
      ok($container.innerText.includes('Notes'), 'the "Notes" header is rendered');
    });

    test('calls the "ref" option with the component reference', function () {
      render();
      equal(component.constructor.name, 'CustomColumnHeader');
    });

    test('uses translated label for teacher notes', function () {
      sinon.stub(I18n, 't').withArgs('Notes').returns('Translated Notes');
      render();
      equal(component.props.title, 'Translated Notes');
      I18n.t.restore();
    });

    test('uses the custom column for the related "customColumnId" on the column definition', function () {
      column = { id: 'custom_col_2402', customColumnId: '2402' };
      render();
      equal(component.props.title, 'Other Notes');
    });
  });

  QUnit.module('#destroy', function () {
    test('unmounts the component', function () {
      render();
      renderer.destroy({}, $container);
      const removed = ReactDOM.unmountComponentAtNode($container);
      strictEqual(removed, false, 'the component was already unmounted');
    });
  });
});
