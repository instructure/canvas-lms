/** @jsx */

define([
  './ObjectStore'
], function (ObjectStore) {

  class FileStore extends ObjectStore {
    /**
     * contextAndId should be in the format 'context/id'
     * Options is an object containing additional options for the store:
     *    - perPage - indicates the number of records that should be pulled per
     *                request.
     */
    constructor (contextAndId, options) {
      var apiUrl = '/api/v1/' + contextAndId + '/files';
      super(apiUrl, options);
    }
  }

  return FileStore;
});