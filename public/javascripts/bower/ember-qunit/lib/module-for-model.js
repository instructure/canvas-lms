import moduleFor from './module-for';
import Ember from 'ember';

export default function moduleForModel(name, description, callbacks) {
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

