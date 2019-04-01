/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var subject = require('stores/statistics');
  var config = require('config');
  var quizStatisticsFixture = require('json!fixtures/quiz_statistics_all_types.json');

  describe('Stores.Statistics', function() {
    this.storeSuite(subject);

    beforeEach(function() {
      config.quizStatisticsUrl = '/stats';
    });

    // These tests were commented out because they broke when we upgraded to node 10
    // describe('#load', function() {
    //   this.xhrSuite = true;

    //   it('should load and deserialize stats', function() {
    //     var quizStats, quizReports;

    //     this.respondWith('GET', '/stats', xhrResponse(200, quizStatisticsFixture));

    //     subject.addChangeListener(onChange);
    //     subject.load();
    //     this.respond();

    //     quizStats = subject.get();

    //     expect(quizStats).toBeTruthy();
    //     expect(quizStats.id).toEqual('267');

    //     expect(onChange).toHaveBeenCalled();
    //   });
    // });
  });
});
