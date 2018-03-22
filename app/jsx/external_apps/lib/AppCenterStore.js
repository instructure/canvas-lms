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

import $ from 'jquery'
import _ from 'underscore'
import createStore from '../../shared/helpers/createStore'
import ExternalAppsStore from '../../external_apps/lib/ExternalAppsStore'
import parseLinkHeader from 'compiled/fn/parseLinkHeader'
import 'compiled/jquery.rails_flash_notifications'

  var PER_PAGE = 250;

  var sort = function(apps) {
    if (apps) {
      return _.sortBy(apps, function (app) {
        if (app.name) {
          return app.name.toUpperCase();
        } else {
          return 'ZZZZZZZZZZ'; // end of sort list
        }
      });
    } else {
      return [];
    }
  };

  var store = createStore({
    isLoading: false,    // flag to indicate fetch is in progress
    isLoaded: false,     // flag to indicate if fetch should re-pull if already pulled
    apps: [],
    links: {},
    filter: 'all',
    filterText: '',
    hasMore: false       // flag to indicate if there are more pages of external tools
  });

  store.reset = function() {
    this.setState({
      isLoading: false,
      isLoaded: false,
      apps: [],
      links: {},
      filter: 'all',
      filterText: '',
      hasMore: false
    })
  };

  store.fetch = function () {
    var url = this.getState().links.next || '/api/v1' + ENV.CONTEXT_BASE_URL + '/app_center/apps?per_page=' + PER_PAGE;
    this.setState({ isLoading: true });
    $.ajax({
      url: url,
      type: 'GET',
      success: this._fetchSuccessHandler.bind(this),
      error: this._fetchErrorHandler.bind(this)
    });
  };

  store.filteredApps = function () {
    var filter = this.getState().filter
      , filterText = new RegExp(this.getState().filterText, 'i');

    return _.filter(this.getState().apps, function (app) {
      if (!app.name) {
        return false;
      }

      var isInstalled = !!app.is_installed
        , name = app.name
        , categories = app.categories || [];

      if (filter == 'installed' && !isInstalled) {
        return false;
      } else if (filter == 'not_installed' && isInstalled) {
        return false;
      }

      return (name.match(filterText) || categories.join().match(filterText));
    }.bind(this));
  };

  store.findAppByShortName = function (shortName) {
    return _.find(this.getState().apps, function (app) {
      return app.short_name === shortName;
    });
  };

  store.flagAppAsInstalled = function (shortName) {
    _.find(this.getState().apps, function (app) {
      if (app.short_name == shortName) {
        app.is_installed = true;
      }
    });
  };

  //*** CALLBACK HANDLERS ***/

  store._fetchSuccessHandler = function (apps, status, xhr) {
    var links = parseLinkHeader(xhr);
    if (links.current !== links.first) {
      tools = this.getState().apps.concat(apps);
    }

    this.setState({
      links: links,
      isLoading: false,
      isLoaded: true,
      apps: sort(apps),
      hasMore: !!links.next
    });

    // Update the installed app list
    ExternalAppsStore.fetch();
  };

  store._fetchErrorHandler = function () {
    this.setState({
      isLoading: false,
      isLoaded: false,
      apps: [],
      hasMore: true
    });
  };

export default store
