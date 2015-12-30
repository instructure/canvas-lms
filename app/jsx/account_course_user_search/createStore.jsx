define([
  "jquery",
  "jsx/shared/helpers/createStore",
  "compiled/fn/parseLinkHeader",
  "underscore",
  "jquery.ajaxJSON"
], function($, createStore, parseLinkHeader, _) {

  /**
   * Build a store that support basic ajax fetching (first, next, all),
   * and caches the results by params.
   *
   * You only need to implement getUrl, and can optionally implement
   * normalizeParams and jsonKey
   */
  var factory = function(spec) {
    return _.extend(createStore(), {
      /**
       * Get a blank state in the store; useful when mounting the top-
       * level component that uses the store
       *
       * @param {any} context
       *        User-defined data you can use later on in normalizeParams
       *        and getUrl; will be available as `this.context`
       */
      reset(context) {
        this.clearState();
        this.context = context;
      },

      getKey(params) {
        return JSON.stringify(params || {});
      },

      normalizeParams(params) {
        return params;
      },

      getUrl() {
        throw "not implemented"
      },

      /**
       * If the API response is an object instead of an array, use this
       * to specify the key containing the actual array of results
       */
      jsonKey: null,

      /**
       * Load the first page of data for the given params
       */
      load(params) {
        var key = this.getKey(params);
        this.lastParams = params;
        var params = this.normalizeParams(params);
        var url = this.getUrl();
        var state = this.getState()[key] || {};

        return this._load(key, url, params);
      },

      /**
       * Create a record; since we're lazy, just blow away all the store
       * data, but reload the last thing we fetched
       */
      create(params) {
        var url = this.getUrl();
        return $.ajaxJSON(url, "POST", this.normalizeParams(params)).then(() => {
          this.clearState();
          if (this.lastParams)
            this.load(this.lastParams);
        });
      },

      /**
       * Load the next page of data for the given params
       */
      loadMore(params) {
        var key = this.getKey(params);
        this.lastParams = params;
        var state = this.getState()[key] || {};

        if (!state.next) return;

        return this._load(key, state.next, {}, {append: true});
      },

      /**
       * Load data from the endpoint, following `next` links until
       * everything has been fetched. Don't be dumb and call this
       * on users or something :P
       */
      loadAll(params, append) {
        var key = this.getKey(params);
        var params = this.normalizeParams(params);
        this.lastParams = params;
        var url = this.getUrl();
        this._loadAll(key, url, params, append);
      },

      _loadAll(key, url, params, append) {
        var promise = this._load(key, url, params, {append});
        if (!promise) return;

        promise.then(() => {
          var state = this.getState()[key] || {};
          if (state.next) {
            this._loadAll(key, state.next, {}, true);
          }
        });
      },

      _load(key, url, params, options) {
        options = options || {};
        this.mergeState(key, {loading: true});

        return $.ajaxJSON(url, "GET", params).then((data, _, xhr) => {
          if (this.jsonKey) {
            data = data[this.jsonKey];
          }
          if (options.wrap) {
            data = [data];
          }
          if (options.append) {
            data = (this.getStateFor(key).data || []).concat(data);
          }

          var { next } = parseLinkHeader(xhr);
          this.mergeState(key, { data, next, loading: false });
        }, (xhr) => {
          this.mergeState(key, { error: true, loading: false });
        });
      },

      getStateFor(key) {
        return this.getState()[key] || {};
      },

      mergeState(key, newState) {
        var state = this.getState()[key] || {};
        var overallState = {};
        overallState[key] = _.extend({}, state, newState);
        this.setState(overallState);
      },

      /**
       * Return whatever results we have for the given params, as well as
       * useful meta data.
       *
       * @return {Object}   obj
       *
       * @return {Object[]} obj.data
       *         The actual data
       *
       * @return {Boolean}  obj.error
       *         Indication of whether there was an error
       *
       * @return {Boolean}  obj.loading
       *         Whether or not we are currently fetching data
       *
       * @return {String}   obj.next
       *         A URL where we can retrieve the next page of data (if
       *         there is more)
       */
      get(params) {
        var key = this.getKey(params);
        return this.getState()[key];
      }
    }, spec);
  }

  return factory;
});
