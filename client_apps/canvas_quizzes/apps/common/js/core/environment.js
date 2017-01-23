define(['canvas_packages/jquery', 'lodash'], ($, _) => {
  const extend = _.extend;

  /**
   * @class Common.Core.Environment
   *
   * API for manipulating the search query.
   */
  const Environment = {
    /**
     * @property {Object} query
     * The extracted GET query parameters. See #parseQueryString
     */
    query: {},

    /**
     * Extract query parameters from a query string. The method can handle
     * scalar and 1-level array values.
     *
     * @param  {String} query
     *         The query string from the location bar. Like:
     *         "?foo=bar" or "foo=bar&arr[]=1&arr[]=2"
     *
     * @return {Object}
     *         Contains the key-value pairs found in the query string.
     */
    parseQueryString (query) {
      const items = query.replace(/^\?/, '').split('&');

      return items.reduce((params, item) => {
        const pair = item.split('=');
        let key = decodeURIComponent(pair[0]);
        const value = decodeURIComponent(pair[1]);

        if (key && key.length) {
          if (key.substr(-2, 2) === '[]') {
            key = key.substr(0, key.length - 2);

            params[key] = params[key] || [];
            params[key].push(value);
          } else {
            params[key] = value;
          }
        }

        return params;
      }, {});
    },

    /**
     * Create or replace a bunch of parameters in the query string.
     *
     * @example
     *   // Say the search has something like ?foo=bar&from=03/01/2014
     *   Env.updateQueryString({
     *     from: "03/28/2014"
     *   });
     *   // => ?foo=bar&from=03/28/2014
     *
     */
    updateQueryString (params) {
      this.query = extend({}, this.query, params);

      history.pushState('', '', [
        location.pathname,
        decodeURIComponent($.param(this.query))
      ].join('?'));
    },

    getQueryParameter (key) {
      return this.query[key];
    },

    removeQueryParameter (key) {
      this.removeQueryParameters([key]);
    },

    removeQueryParameters (keys) {
      const query = this.query;

      keys.forEach((key) => {
        delete query[key];
      });

      this.updateQueryString({});
    }
  };

  // Extract the actual query string either from location.search if it's there,
  // or from the hash if we're using hash-based history, or from the href
  // as the last resort.
  const extractQueryString = function () {
    if (window.location.search.length) {
      return window.location.search;
    } else if (window.location.hash.length) {
      return window.location.hash.split('?')[1] || '';
    }

    return window.location.href.split('?')[1] || '';
  };

  Environment.query = Environment.parseQueryString(extractQueryString());

  return Environment;
});
