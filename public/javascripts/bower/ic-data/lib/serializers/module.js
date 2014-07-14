import BaseSerializer from './base';

var ModuleSerializer = BaseSerializer.extend({
  normalize: function(type, hash, prop){
    hash.links = hash.links || {};
    var url = hash.items_url;
    url = url.replace("https://localhost", "http://localhost:8080");
    hash.links.items = url;
    delete hash.items_url;
    return this._super(type, hash, prop);
  },

});

export default ModuleSerializer;

