/** @jsx */

define([
  './ObjectStore'
], function(ObjectStore) {

  class FileStore extends ObjectStore {
    /**
     * contextAndId should be in the format 'context/id'
     */
    constructor (contextAndId) {
      var apiUrl = '/api/v1/' + contextAndId + '/files?per_page=20';
      super(apiUrl);
    }
  }

  return FileStore;
});