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

import $ from 'jquery';
import GradingPeriodMenuView from 'compiled/views/gradezilla/GradingPeriodMenuView';

QUnit.module('GradingPeriodMenuView', {
  setup () {
    this.stub($, 'publish');
    const periods = [{ id: '1401' }, { id: '1402' }];
    this.view = new GradingPeriodMenuView({ periods, currentGradingPeriod: '1401' });
    this.view.render();
    this.view.$el.appendTo('#fixtures');
  },

  teardown () {
    $('#fixtures').empty();
  }
});

test('sets focus on the button after changing grading periods', function () {
  this.view.$el.find('button').click();
  $('input[value=1402]').parent().click();
  equal(document.activeElement, this.view.$('button')[0]);
});
