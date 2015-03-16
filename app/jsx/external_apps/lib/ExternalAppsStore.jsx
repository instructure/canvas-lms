/** @jsx */

define([
  'i18n!external_tools',
  'jquery',
  'underscore',
  'jsx/shared/helpers/createStore',
  'compiled/fn/parseLinkHeader',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, $, _, createStore, parseLinkHeader) {

  var PER_PAGE = 50;

  var sort = function(tools) {
    if (tools) {
      return _.sortBy(tools, function (tool) {
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

  var store = createStore({
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
      url: url,
      type: 'GET',
      success: this._fetchSuccessHandler.bind(this),
      error: this._fetchErrorHandler.bind(this)
    });
  };

  store.fetchWithDetails = function(tool) {
    if (tool.app_type === 'ContextExternalTool') {
      return $.getJSON('/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + tool.app_id);
    } else {
      // DOES NOT EXIST YET
      return $.getJSON('/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id);
    }
  };

  store.save = function(configurationType, data, success, error) {
    configurationType = configurationType || 'manual';

    var params = this._generateParams(configurationType, data);

    var url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools';
    var method = 'POST';
    if (data.app_id) {
      url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + data.app_id;
      method = 'PUT';
    }
    $.ajax({
      url: url,
      data: { external_tool: params },
      type: method,
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
    if (data.consumerKey && data.consumerKey.length > 0) {
      params['consumer_key'] = data.consumerKey;
    }
    if (data.sharedSecret && data.sharedSecret.length > 0) {
      params['shared_secret'] = data.sharedSecret;
    }

    switch(configurationType) {
      case 'manual':
        // Convert custom fields into kv pair
        var pairs = (data.customFields || '').split('\n');
        _.forEach(pairs, function(pair) {
          var vals = pair.trim().split('=');
          params['custom_fields[' + vals[0] + ']'] = vals[1];
        });
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

  store._deleteSuccessHandler = function() {
    // noop
  };

  store._deleteErrorHandler = function() {
    $.flashError(I18n.t('Unable to remove app'));
    this.fetch({ force: true });
  };

  return store;
});
