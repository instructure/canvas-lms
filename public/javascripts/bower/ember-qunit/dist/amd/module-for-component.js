define(
  ["./test-resolver","./module-for","ember","exports"],
  function(__dependency1__, __dependency2__, __dependency3__, __exports__) {
    "use strict";
    var testResolver = __dependency1__["default"] || __dependency1__;
    var moduleFor = __dependency2__["default"] || __dependency2__;
    var Ember = __dependency3__["default"] || __dependency3__;

    __exports__["default"] = function moduleForComponent(name, description, callbacks) {
      var resolver = testResolver.get();

      moduleFor('component:' + name, description, callbacks, function(container, context, defaultSubject) {
        var templateName = 'template:components/' + name;

        var template = resolver.resolve(templateName);

        if (template) {
          container.register(templateName, template);
          container.injection('component:' + name, 'template', templateName);
        }
        
        context.dispatcher = Ember.EventDispatcher.create();
        context.dispatcher.setup({}, '#ember-testing');

        context.__setup_properties__.append = function(selector) {
          var containerView = Ember.ContainerView.create({container: container});
          var view = Ember.run(function(){
            var subject = context.subject();
            containerView.pushObject(subject);
            // TODO: destory this somewhere
            containerView.appendTo('#ember-testing');
            return subject;
          });

          return view.$();
        };
        context.__setup_properties__.$ = context.__setup_properties__.append;
      });
    }
  });