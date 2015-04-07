/** @jsx */

define([
  'jquery',
  'underscore',
  'jsx/shared/helpers/createStore',
  'compiled/fn/parseLinkHeader',
  'compiled/jquery.rails_flash_notifications'
], function($, _, createStore, parseLinkHeader) {


  var initialStoreState = {
    links: {},
    items: [],
    isLoading: false,
    hasLoaded: false,
    hasMore: false
  };

  class ObjectStore {

    /**
     * apiEndpoint should be the endpoint for this resource.
     */
    constructor(apiEndpoint) {
      // We clone the initialStoreState so it doesn't hang onto a bad reference.
      this.store = createStore(_.clone(initialStoreState))
      this.apiEndpoint = apiEndpoint;
    }

    /**
     * Fetches the resources.
     * options is an optional object.  Currently this allows for the following:
     *   - fetchAll: true - this will continually fetch all pages of the resource
     */
    fetch(options) {
      var url = this.store.getState().links.next || this.apiEndpoint;
      this.store.setState({ isLoading: true });
      $.ajax({
        url: url,
        type: 'GET',
        success: this._fetchSuccessHandler.bind(this, options),
        error: this._fetchErrorHandler.bind(this)
      });
    }

    /**
     * Sets the store back to the initial state.
     */
    reset() {
      // We clone the initialStoreState so it doesn't hang onto a bad reference.
      this.store.setState(_.clone(initialStoreState))
    }

    /**
     * Returns the current state of the underlying store.
     */
    getState() {
      return this.store.getState();
    }

    /**
     * Adds a change listener
     */
    addChangeListener(callback) {
      this.store.addChangeListener(callback);
    }

    /**
     * Removes a change listener
     */
    removeChangeListener(callback) {
      this.store.removeChangeListener(callback);
    }

    _fetchSuccessHandler(options, items, status, xhr) {
      var links = parseLinkHeader(xhr);
      items = this.store.getState().items.concat(items);

      this.store.setState({
        links: links,
        isLoading: false,
        isLoaded: true,
        items: items,
        hasMore: !!links.next
      });

      if (options && options.fetchAll && (!!links.next)) {
        this.fetch(options);
      }
    }

    _fetchErrorHandler() {
      this.store.setState({
        items: [],
        isLoading: false,
        isLoaded: false,
        hasMore: true
      });
    }

  }

  return ObjectStore;


});