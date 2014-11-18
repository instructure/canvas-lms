define(function() {
  /**
   * @class Events.Mixins.PaginatedCollection
   * @extends {Backbone.Collection}
   *
   * Adds support for utilizing JSON-API pagination meta-data to allow fetching
   * any page of a paginated API resource, or all pages at once.
   *
   * Usage example:
   *
   *     var Collection = Backbone.Collection.extend({
   *       // install the mixin
   *       constructor: function() {
   *         PaginatedCollection(this);
   *         return Backbone.Collection.apply(this, arguments);
   *       },
   *
   *       url: function() {
   *         return '/users';
   *       }
   *     });
   *
   *     var collection = new Collection();
   *
   *     collection.fetch(); // /users
   *     collection.length;  // 10
   *
   *     collection.fetchNext(); // /users?page=2
   *     collection.length;      // 20
   *
   *     // load all available users in one go:
   *     // /users?page=1
   *     // ...
   *     // /users?page=5
   *     collection.fetchAll().then(function() {
   *       collection.length; // 50
   *     });
   */
  var Mixin = {
    /**
     * Fetch the next page, if available.
     *
     * @param {Object} options
     *        Normal options you'd pass to Backbone.Collection#fetch().
     *
     * @param {Number} [options.page]
     *        If specified, exactly that page will be fetched, otherwise we'll
     *        use the current cursor (or 1).
     *
     * @return {Promise}
     *         Resolves when the page has been loaded and the pagination meta
     *         parsed.
     */
    fetchNext: function(options) {
      var meta = this._paginationMeta;

      if (!options) {
        options = {};
      }
      else if (options.hasOwnProperty('xhr')) {
        delete options.xhr;
      }

      if (!options.data) {
        options.data = {};
      }

      options.data.page = options.page || meta.nextPage;

      return this.sync('read', this, options).then(function(payload) {
        this.add(payload, { parse: true /* always parse */ });

        if (payload.meta && payload.meta.pagination) {
          this._parsePaginationMeta(payload.meta.pagination);
        }

        return payload;
      }.bind(this));
    },

    /**
     * @return {Boolean}
     *         Whether there's more data (that we know of) to pull in from the
     *         server.
     */
    canLoadMore: function() {
      return !!this._paginationMeta.hasMore;
    },

    /**
     * Fetch all available pages.
     *
     * @param  {Object} options
     *         Options to pass to #fetchNext. "page" is not allowed here and
     *         will be ignored if specified.
     *
     * @return {Promise}
     *         Resolves when *all* pages have been loaded.
     */
    fetchAll: function(options) {
      var meta = this._paginationMeta;

      if (!options) {
        options = {};
      }
      else if (options.hasOwnProperty('page')) {
        console.warn(
          'You may not specify a page when fetching all pages. ' +
          'Resetting cursor to 1.'
        );

        delete options.page;
      }

      meta.nextPage = 1;

      return (function fetch(collection) {
        return collection.fetchNext(options).then(function() {
          if (meta.hasMore) {
            return fetch(collection);
          } else {
            return collection;
          }
        });
      })(this);
    },

    /** @private */
    _resetPaginationMeta: function() {
      this._paginationMeta = {};
    },

    /** @private */
    _parsePaginationMeta: function(respMeta) {
      var meta = this._paginationMeta;

      meta.perPage = respMeta.per_page;
      meta.count = respMeta.count;
      meta.remainder = meta.count - this.models.length;
      meta.hasMore = !!respMeta.next;
      meta.nextPage = meta.hasMore ? respMeta.page + 1 : undefined;

      return meta;
    }
  };

  return function applyMixin(collection) {
    collection.fetchNext = Mixin.fetchNext;
    collection.fetchAll = Mixin.fetchAll;
    collection._parsePaginationMeta = Mixin._parsePaginationMeta;
    collection._resetPaginationMeta = Mixin._resetPaginationMeta;

    collection.on('reset', collection._resetPaginationMeta, collection);
    collection._resetPaginationMeta();
  };
});