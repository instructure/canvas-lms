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

import I18n from 'i18n!external_tools'
import $ from 'jquery'
import _ from 'underscore'
import createStore from '../../shared/helpers/createStoreJestCompatible'
import parseLinkHeader from 'compiled/fn/parseLinkHeader'
import 'compiled/jquery.rails_flash_notifications'

  const PER_PAGE = 50;

  const sort = function(tools) {
    if (tools) {
      return _.sortBy(tools, (tool) => {
        if (tool.name) {
          return tool.name.toUpperCase();
        } else {
          return 'ZZZZZZZZZZ'; // end of sort list
        }
      });
    } else {
      return [];
    }
  };

  const store = createStore({
    externalTools: [],
    links: {},
    isLoading: false,    // flag to indicate fetch is in progress
    isLoaded: false,     // flag to indicate data has loaded
    hasMore: false       // flag to indicate if there are more pages of external tools
  });

  store.reset = function() {
    this.setState({
      externalTools: [],
      links: {},
      isLoading: false,
      isLoaded: false,
      hasMore: false
    })
  };

  store.fetch = function() {
    var url = this.getState().links.next || '/api/v1' + ENV.CONTEXT_BASE_URL + '/lti_apps?per_page=' + PER_PAGE;
    this.setState({ isLoading: true });
    $.ajax({
      url,
      type: 'GET',
      success: this._fetchSuccessHandler.bind(this),
      error: this._fetchErrorHandler.bind(this)
    });
  };

  store.fetchWithDetails = function(tool) {
    if (tool.app_type === 'ContextExternalTool') {
      return $.getJSON('/api/v1/' + tool.context.toLowerCase() + 's/' + tool.context_id + '/external_tools/' + tool.app_id);
    } else {
      // DOES NOT EXIST YET
      return $.getJSON('/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id);
    }
  };

  store.save = function(configurationType, data, success, error) {
    configurationType = configurationType || 'manual';

    var params = this._generateParams(configurationType, data);

    // Don't send shared secret if it hasn't changed //
    if(params['shared_secret'] == "N/A") {
      delete params['shared_secret'];
    }

    var url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools';
    var method = 'POST';
    if (data.app_id) {
      url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + data.app_id;
      method = 'PUT';
    }
    $.ajax({
      url: url,
      contentType: 'application/json',
      data: JSON.stringify({ external_tool: params }),
      type: method,
      success: success.bind(this),
      error: error.bind(this)
    });
  };

  store.updateAccessToken = function(context_base_url, accessToken, success, error) {
    $.ajax({
      url: context_base_url,
      dataType: 'json',
      type: 'PUT',
      data: { account: { settings: { app_center_access_token: accessToken}}},
      success: success.bind(this),
      error: error.bind(this)
    });
  };

  store.delete = function(tool) {
    var url;

    if (tool.app_type === 'ContextExternalTool') {
      url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + tool.app_id;
    } else { // Lti::ToolProxy
      url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id;
    }

    var tools = _.filter(this.getState().externalTools, function(t) { return t.app_id !== tool.app_id; });
    this.setState({ externalTools: sort(tools) });

    $.ajax({
      url: url,
      type: 'DELETE',
      success: this._deleteSuccessHandler.bind(this),
      error: this._deleteErrorHandler.bind(this)
    });
  };

  function handleToolUpdate (tool, dismiss=false) {
    if (tool.app_type === 'ContextExternalTool') {
      // we dont support LTI 1
      return;
    }

    var url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id + '/update',
        errorHandler = dismiss ? this._dismissUpdateErrorHandler : this._acceptUpdateErrorHandler;
    tool.has_update = false;
    this.setState({ externalTools: sort(this.getState().externalTools) });

    $.ajax({
      url: url,
      type: dismiss ? 'DELETE' : 'PUT',
      success: this._genericSuccessHandler.bind(this),
      error: errorHandler.bind(this)
    });
  }

  store.acceptUpdate = function(tool) {
    handleToolUpdate.call(this, tool);
  };

  store.dismissUpdate = function(tool) {
    handleToolUpdate.call(this, tool, true);
  };

  store.triggerUpdate = function () {
    this.setState({ externalTools: sort(this.getState().externalTools) });
  }

  store.activate = function(tool, success, error) {
    var url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id;
    var tools = _.map(this.getState().externalTools, function(t) {
      if (t.app_id === tool.app_id) {
        t['enabled'] = true;
      }
      return t;
    });
    this.setState({ externalTools: sort(tools) });

    $.ajax({
      url: url,
      data: { workflow_state: 'active' },
      type: 'PUT',
      success: success.bind(this),
      error: error.bind(this)
    });
  };

  store.deactivate = function(tool, success, error) {
    var url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id;
    var tools = _.map(this.getState().externalTools, function(t) {
      if (t.app_id === tool.app_id) {
        t['enabled'] = false;
      }
      return t;
    });
    this.setState({ externalTools: sort(tools) });

    $.ajax({
      url: '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id,
      data: { workflow_state: 'disabled' },
      type: 'PUT',
      success: success.bind(this),
      error: error.bind(this)
    });
  };

  store.findById = function(toolId) {
    return _.find(this.getState().externalTools, function(tool) {
      return tool.app_id === toolId;
    });
  };

  store._generateParams = function(configurationType, data) {
    var params = {};
    params['name'] = data.name;
    params['privacy_level'] = 'anonymous';
    params['consumer_key'] = 'N/A';
    params['shared_secret'] = 'N/A';
    params['verify_uniqueness'] = data.verifyUniqueness
    if (data.consumerKey && data.consumerKey.length > 0) {
      params['consumer_key'] = data.consumerKey;
    }
    if (data.sharedSecret && data.sharedSecret.length > 0) {
      params['shared_secret'] = data.sharedSecret;
    }
    switch(configurationType) {
      case 'manual':
        // Convert custom fields into kv pair
        if (data.customFields === '' || typeof data.customFields === 'undefined') {
          params['custom_fields_string'] = '';
        } else {
          var pairs = (data.customFields || '').split('\n');
          params.custom_fields = {}
          _.forEach(pairs, function(pair) {
            var vals = pair.trim().split(/=(.+)?/);
            params.custom_fields[vals[0]] = vals[1];
          });
        }

        params['domain'] = data.domain;
        params['privacy_level'] = data.privacyLevel;
        params['url'] = data.url;
        params['description'] = data.description;
        break;
      case 'url':
        params['config_type'] = 'by_url';
        params['config_url'] = data.configUrl;
        break;
      case 'xml':
        params['config_type'] = 'by_xml';
        params['config_xml'] = data.xml;
        break;
    }

    if (data.allow_membership_service_access != null) {
      params['allow_membership_service_access'] = data.allow_membership_service_access;
    }

    return params;
  };

  //*** CALLBACK HANDLERS ***/

  store._fetchSuccessHandler = function(tools, status, xhr) {
    var links = parseLinkHeader(xhr);
    if (links.current !== links.first) {
      tools = this.getState().externalTools.concat(tools);
    }

    this.setState({
      links: links,
      isLoading: false,
      isLoaded: true,
      externalTools: sort(tools),
      hasMore: !!links.next
    });
  };

  store._fetchErrorHandler = function() {
    this.setState({
      isLoading: false,
      isLoaded: false,
      externalTools: [],
      hasMore: false
    });
  };

  store._genericSuccessHandler = store._deleteSuccessHandler = function() {
    // noop
  };

  store._deleteErrorHandler = function() {
    $.flashError(I18n.t('Unable to remove app'));
    this.fetch({ force: true });
  };

  store._acceptUpdateErrorHandler = function() {
    $.flashError(I18n.t('Unable to accept update'));
    this.fetch({ force: true });
  };

  store._dismissUpdateErrorHandler = function() {
    $.flashError(I18n.t('Unable to dismiss update'));
    this.fetch({ force: true });
  };

export default store
