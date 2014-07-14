import BaseSerializer from './base';

var FolderSerializer = BaseSerializer.extend({
  extractDeleteRecord: function(store, type, payload) {
    // payload is {delete: true} and then ember data wants to go ahead and set
    // the new properties, return null so it doesn't try to do that
    return null;
  },
  normalize: function(type, hash, prop){
    hash.links = hash.links || {};
    ['files', 'folders'].forEach(function(linkType){
      var url = hash[linkType + '_url'] + '?include[]=user';
      url = url.replace("https://localhost", "http://localhost:8080"); // TODO remove
      hash.links[linkType] = url;
      delete hash[linkType + '_url']
    })
    return this._super(type, hash, prop);
  },

  keyForRelationship: function(key, kind){
    if (kind === "belongsTo") {
      return key + "_id";
    } else {
      return key;
    }
  }

});

export default FolderSerializer;

