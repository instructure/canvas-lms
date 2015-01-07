/** @jsx */

define([
  'i18n!external_tools',
  'jquery',
  'underscore',
  'compiled/models/ExternalTool',
  'compiled/collections/PaginatedCollection',
  'compiled/collections/ExternalToolCollection',
  'jsx/shared/helpers/createStore',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, $, _, ExternalTool, PaginatedCollection, ExternalToolCollection, createStore) {

  var store = createStore({
    isLoadingApps: false,          // flag to indicate fetch is in progress
    isLoadedApps: false,           // flag to indicate if fetch should re-pull if already pulled
    isLoadingAppReviews: false,    // flag to indicate fetch is in progress
    isLoadedAppReviews: false,     // flag to indicate if fetch should re-pull if already pulled
    isLoadingExternalTools: false, // flag to indicate fetch is in progress
    isLoadedExternalTools: false,  // flag to indicate if fetch should re-pull if already pulled
    apps: [],
    externalTools: [],
    filter: 'all',
    filterText: ''
  });

  store.fetchAll = function() {
    this.fetchApps();
    this.fetchExternalTools();
  };

  /* Apps ---------------------------------------------------------------------------------------- */

  store.fetchApps = function() {
    if (this.getState().isLoadedApps == false) {
      this.setState({ isLoadingApps: true });
      var apps = new PaginatedCollection();
      //apps.setParam('per_page', 20);
      apps.resourceName = 'app_center/apps';
      apps.fetch({
        success: this.fetchAppsSuccessHandler.bind(this),
        error: this.fetchAppsErrorHandler.bind(this)
      });
    }
  };

  store.fetchAppsSuccessHandler = function(collection) {
    this.setState({
      isLoadingApps: false,
      isLoadedApps: true,
      apps: collection.models
    });
  };

  store.fetchAppsErrorHandler = function() {
    this.setState({
      isLoadingApps: false,
      apps: []
    });
  };

  store.filteredApps = function() {
    var filter = this.getState().filter
      , filterText = new RegExp(this.getState().filterText, 'i');

    return _.filter(this.getState().apps, function(app) {
      if (!app.attributes.name) { return false; }

      var isInstalled = !!app.attributes.is_installed
        , name = app.attributes.name
        , categories = app.attributes.categories || [];

      if (filter == 'installed' && !isInstalled) {
        return false;
      } else if (filter == 'not_installed' && isInstalled) {
        return false;
      }

      return (name.match(filterText) || categories.join().match(filterText));
    }.bind(this));
  };

  store.findAppByShortName = function(shortName) {
    return _.find(this.getState().apps, function(app) {
      return app.attributes.short_name === shortName;
    });
  };

  store.flagAppAsInstalled = function(shortName) {
    _.find(this.getState().apps, function(app) {
      if (app.attributes.short_name == shortName) {
        app.attributes.is_installed = true;
      }
    });
  };

  /* External Tools ---------------------------------------------------------------------------- */

  store.fetchExternalTools = function(force) {
    if (force == true || this.getState().isLoadedExternalTools == false) {
      this.setState({ isLoadingExternalTools: true });
      var externalTools = new ExternalToolCollection();
      externalTools.setParam('per_page', 100);
      externalTools.fetch({
        success: this.fetchExternalToolsSuccessHandler.bind(this),
        error: this.fetchExternalToolsErrorHandler.bind(this)
      });
    }
  };

  store.fetchExternalToolsSuccessHandler = function(collection) {
    this.setState({
      isLoadingExternalTools: false,
      isLoadedExternalTools: true,
      externalTools: collection.models
    });
  };

  store.fetchExternalToolsErrorHandler = function() {
    this.setState({
      isLoadingExternalTools: false,
      externalTools: []
    });
  };

  store.findExternalToolById = function(id) {
    return _.find(this.getState().externalTools, function(tool) {
      return tool.id === id;
    });
  };

  store.deleteExternalTool = function(tool) {
    var tools = _.without(this.getState().externalTools, tool);
    this.setState({ externalTools: tools });
    tool.destroy({
      success: function() {
        this.fetchApps();
      }.bind(this),
      error: function() {
        $.flashError(I18n.t('Unable to remove app'));
        this.fetchApps();
      }.bind(this)
    });
  };

  store.createExternalTool = function(configurationType, data, success, error) {
    this.saveExternalTool(new ExternalTool(), data, success, error, configurationType);
  };

  store.saveExternalTool = function(tool, data, success, error, configurationType) {
    configurationType = configurationType || 'manual';

    tool.on('sync', this.saveExternalToolSuccessHandler.bind(this, success));
    tool.on('error', this.saveExternalToolErrorHandler.bind(this, error));

    tool.set('name', data.name);
    tool.set('consumer_key', data.consumerKey);
    if (data.sharedSecret.length > 0) {
      tool.set('shared_secret', data.sharedSecret);
    }

    // Convert custom fields into kv pair
    var customFields = {};
    var pairs = (data.customFields || '').split('\n');
    _.forEach(pairs, function(pair) {
      var vals = pair.trim().split('=');
      customFields[vals[0]] = vals[1];
    });

    switch(configurationType) {
      case 'manual':
        tool.set('custom_fields', customFields);
        tool.set('domain', data.domain);
        tool.set('privacy_level', data.privacy);
        tool.set('url', data.url);
        tool.set('description', data.description);
        break;
      case 'url':
        tool.set('privacy_level', 'anonymous');
        tool.set('config_url', this.configUrl(data));
        tool.set('config_type', 'by_url');
        break;
      case 'xml':
        tool.set('privacy_level', 'anonymous');
        tool.set('config_type', 'by_xml');
        tool.set('config_xml', data.xml);
        break;
    }

    tool.save();
  };

  store.saveExternalToolSuccessHandler = function(cb, tool) {
    tool.off('sync', this.onSaveSuccess);
    var tools = this.getState().externalTools;
    if (!_.contains(tools, tool)) {
      tools.push(tool);
    }
    this.setState({ externalTools: tools });
    cb();
  };

  store.saveExternalToolErrorHandler = function(cb, tool) {
    cb();
  };

  store.configUrl = function(data) {
    var url = data.configUrl;

    var queryParams = {};
    _.map(data, function(v, k) {
      queryParams[k] = v.value;
    });
    delete queryParams['configUrl'];
    delete queryParams['consumer_key'];
    delete queryParams['shared_secret'];

    var newUrl = url + (url.indexOf('?') !== -1 ? '&' : '?') + $.param(queryParams);
    return newUrl;
  };

  return store;
});
