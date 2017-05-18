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
  var Subject = require('core/delegate');
  var App = require('main');

  describe('Delegate', function() {
    describe('#mount', function() {
      this.promiseSuite = true;

      it('should work', function() {
        var onReady = jasmine.createSpy('onAppMount');
        spyOn(console, 'warn');
        Subject.mount(jasmine.fixture).then(onReady);

        this.flush();
        expect(onReady).toHaveBeenCalled();
      });

      it('should mount the app view');
      it('should accept options', function() {
        Subject.mount(jasmine.fixture, {
          loadOnStartup: false
        });

        expect(App.config.loadOnStartup).toBe(false);
      });

      describe('config.loadOnStartup', function() {
        it('should log a warning when config.quizStatisticsUrl is missing', function() {
          var warnSpy = spyOn(console, 'warn');

          App.configure({ quizStatisticsUrl: null });
          Subject.mount(jasmine.fixture);
          this.flush();

          expect(warnSpy).toHaveBeenCalled();
        });
      });
    });
  });
});