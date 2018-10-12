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
import I18n from 'i18n!external_tools'
import _ from 'underscore'
import createStore from '../../shared/helpers/createStoreJestCompatible'
import ExternalAppsStore from './ExternalAppsStore'
import parseLinkHeader from 'compiled/fn/parseLinkHeader'
import 'compiled/jquery.rails_flash_notifications'

  const PER_PAGE = 250;

  const sort = function(apps) {
    if (apps) {
      return _.sortBy(apps, (app) => {
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

  const defaultState = {
    isLoading: false,    // flag to indicate fetch is in progress
    isLoaded: false,     // flag to indicate if fetch should re-pull if already pulled
    apps: [],
    lti13Tools: [],
    lti13LoadStatus: 'pending',
    links: {},
    filter: 'all',
    filterText: '',
    hasMore: false       // flag to indicate if there are more pages of external tools
  }

  const store = createStore(defaultState);

  store.reset = function() {
    this.setState(defaultState)
  };

  store.fetch = function () {
    const url = this.getState().links.next || `/api/v1${ENV.CONTEXT_BASE_URL}/app_center/apps?per_page=${PER_PAGE}`;
    this.setState({ isLoading: true });
    $.ajax({
      url,
      type: 'GET',
      success: this._fetchSuccessHandler.bind(this),
      error: this._fetchErrorHandler.bind(this)
    });
  };

  store.fetch13Tools = function() {
    const url = `/api/v1${ENV.CONTEXT_BASE_URL}/lti_apps?lti_1_3_tool_configurations=true`;
    this.setState({ lti13LoadStatus: true });
    $.ajax({
      url,
      type: 'GET',
      success: this._fetch13ToolsSuccessHandler.bind(this),
      error: this._fetch13ToolsErrorHandler.bind(this)
    });
  };

  store.filteredApps = function (toFilter = this.getState().apps) {
    const filter = this.getState().filter
    const filterText = new RegExp(this.getState().filterText, 'i');

    return _.filter(toFilter, (app) => {
      if (!app.name) {
        return false;
      }

      const isInstalled = !!app.is_installed
      const name = app.name
      const categories = app.categories || [];

      if (filter === 'installed' && !isInstalled) {
        return false;
      } else if (filter === 'not_installed' && isInstalled) {
        return false;
      }

      return (name.match(filterText) || categories.join().match(filterText));
    });
  };

  store.findAppByShortName = function (shortName) {
    return _.find(this.getState().apps, (app) => app.short_name === shortName);
  };

  store.flagAppAsInstalled = function (shortName) {
    _.find(this.getState().apps, (app) => {
      if (app.short_name === shortName) {
        app.is_installed = true;
      }
    });
  };

  store.installTool = function (developerKeyId) {
    const toggleValue = store._toggle_lti_1_3_tool_enabled(developerKeyId).bind(this)
    toggleValue(true)
    const url = `/api/v1${ENV.CONTEXT_BASE_URL}/developer_keys/${developerKeyId}/create_tool`;
    $.ajax({
      url,
      type: 'POST',
      success: () => {},
      error: () => {
        $.flashError('Failed to install tool.')
        toggleValue(false)
      }
    });
  }

  store.removeTool = function (developerKeyId) {
    const toggleValue = store._toggle_lti_1_3_tool_enabled(developerKeyId).bind(this)
    toggleValue(false)
    const url = `/api/v1${ENV.CONTEXT_BASE_URL}/developer_keys/${developerKeyId}/delete_tool`;
    $.ajax({
      url,
      type: 'DELETE',
      success: () => {},
      error: () => {
        $.flashError('Failed to remove tool.')
        toggleValue(true)
      }
    });
  }

  // *** CALLBACK HANDLERS ***/

  store._fetchSuccessHandler = function (apps, status, xhr) {
    const links = parseLinkHeader(xhr);
    if (links.current !== links.first) {
      tools = this.getState().apps.concat(apps);
    }

    this.setState({
      links,
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

  store._fetch13ToolsSuccessHandler = function(tools, status, xhr) {
    this.setState({
      lti13LoadStatus: 'success',
      lti13Tools: sort(tools)
    });
  };

  store._fetch13ToolsErrorHandler = function() {
    $.flashError(I18n.t('Unable to load Lti 1.3 Tools'));
    this.setState({
      lti13LoadStatus: 'error'
    });
  };

  store._toggle_lti_1_3_tool_enabled = function(developerKeyId) {
    return (value) => {
      const oldTools = this.getState().lti13Tools
      const installedToolIndex = oldTools.findIndex((tool) => tool.app_id === developerKeyId)
      const tool = Object.assign(
        {},
        oldTools[installedToolIndex],
        {installed_locally: value, enabled: value, installed_in_current_course: true}
      )
      const lti13Tools = oldTools.slice()
      lti13Tools.splice(installedToolIndex, 1, tool)
      this.setState({lti13Tools})
    }
  }

export default store
