// from https://github.com/shinetech/backbone-identity-map/blob/d9d1b5faf8f5cf4ef05b358f65347745f0df2693/backbone-identity-map.js

/**
 * Identity Map for Backbone models.
 *
 * Usage:
 *
 *    var NewModel = IdentityMap(Backbone.Model.extend(
 *      {...},
 *      {...}
 *    ));
 *
 * A model that is wrapped in IdentityMap will cache models by their
 * ID. Any time you call new NewModel(), and you pass in an id
 * attribute, IdentityMap will check the cache to see if that object
 * has already been created. If so, that existing object will be
 * returned. Otherwise, a new model will be instantiated.
 *
 * Any models that are created without an ID will instantiate a new
 * object. If that model is subsequently assigned an ID, it will add
 * itself to the cache with this ID. If by that point another object
 * has already been assigned to the cache with the same ID, then
 * that object will be overridden.
 */
define(['Backbone', 'underscore'], function(Backbone, _) {

  // Stores cached models:
  // key: (unique identifier per class) + ':' + (model id)
  // value: model object
  var cache = {};

  /**
   * realConstructor: a backbone model constructor function
   * returns a constructor function that acts like realConstructor,
   * but returns cached objects if possible.
   */
  IdentityMap = function(realConstructor) {
    var classCacheKey = _.uniqueId();
    var modelConstructor = _.extend(function(attributes, options) {
      // creates a new object (used if the object isn't found in
      // the cache)
      var create = function() {
        return new realConstructor(attributes, options);
      };
      var objectId = attributes &&
        attributes[realConstructor.prototype.idAttribute];
      // if there is an ID, check if that object exists in the
      // cache already
      if (objectId) {
        var cacheKey = classCacheKey + ':' + objectId;
        if (!cache[cacheKey]) {
          // the object has an ID, but isn't found in the cache
          cache[cacheKey] = create();
        } else {
          // the object was in the cache
          var object = cache[cacheKey];
          // set up the object just like new Backbone.Model() would
          if (options && options.parse) {
            attributes = object.parse(attributes);
          }
          object.set(attributes);
        }
        return cache[cacheKey];
      } else {
        var obj = create();
        // when an object's id is set, add it to the cache
        obj.on('change:' + realConstructor.prototype.idAttribute,
          function(model, objectId) {
            cache[classCacheKey + ':' + objectId] = obj;
            obj.off(null, null, this);
          },
        this);
        return obj;
      }
    }, realConstructor);
    modelConstructor.prototype = realConstructor.prototype;
    return modelConstructor;
  };

  /**
   * Clears the cache. (useful for unit testing)
   */
  IdentityMap.resetCache = function() {
    cache = {};
  };

  return IdentityMap

});
