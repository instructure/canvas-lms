define(
  ["./module-for","ember","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var moduleFor = __dependency1__["default"] || __dependency1__;
    var Ember = __dependency2__["default"] || __dependency2__;

    __exports__["default"] = function moduleForModel(name, description, callbacks) {
      moduleFor('model:' + name, description, callbacks, function(container, context, defaultSubject) {
        // custom model specific awesomeness
        container.register('store:main', DS.Store);
        container.register('adapter:application', DS.FixtureAdapter);

        context.__setup_properties__.store = function(){
          return container.lookup('store:main');
        };

        if (context.__setup_properties__.subject === defaultSubject) {
          context.__setup_properties__.subject = function(options) {
            return Ember.run(function() {
              return container.lookup('store:main').createRecord(name, options);
            });
          };
        }
      });
    }
  });