import { RESTAdapter } from 'ember-data';
import parseLinkHeader from '../parse-link-header';

export default RESTAdapter.extend({
  namespace: '/api/v1',
  ajax: function(url, type, hash) {
    var adapter = this;

    return new Ember.RSVP.Promise(function(resolve, reject) {
      hash = adapter.ajaxOptions(url, type, hash);

      hash.success = function(json, status, hxr) {
        json.meta = parseLinkHeader(hxr);
        Ember.run(null, resolve, json);
      };

      hash.error = function(jqXHR, textStatus, errorThrown) {
        Ember.run(null, reject, adapter.ajaxError(jqXHR));
      };

      Ember.$.ajax(hash);
    }, "DS: RestAdapter#ajax " + type + " to " + url);
  }
});

