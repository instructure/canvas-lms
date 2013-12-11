/*!
 * ic-styled
 * please see license at https://github.com/instructure/ic-styled
 */

;(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'));
  } else {
    root.ic = root.ic || {};
    root.ic.Styled = factory(Ember);
  }
}(this, function(Ember) {

  /*
   * Auto-injects a sister component containing the styles for this component.
   * Given a component `x-foo` create a template at `components/x-foo-css`,
   * treat it like a `css` file, it becomes a `<style>` tag.
   */

  Ember.Component.reopen({
    injectStyles: function() {
      var klass = this.constructor;
      var Style = lookupStyleComponent(this);
      if (!Style || Style._injected) { return; }
      Style._injected = true;
      var style = Style.create();
      style.reopen({tagName: 'style', classNames: 'ic-styled'});
      style.appendTo(document.body);
      Ember.run.scheduleOnce('afterRender', this, function() {
        style.$().prependTo('head');
      });
    }.on('willInsertElement')
  });

  function getStyleComponentName(component) {
    var tagName = component.get('tagName');
    if (!tagName || tagName.indexOf('-') == -1) {
      // do not use _debugContainerKey without permission from Stefan Penner
      tagName = component._debugContainerKey.split(':')[1];
    }
    return tagName+'-css';
  }

  function lookupStyleComponent(component) {
    var noIdea = component.container.lookup('component-lookup:main');
    var name = getStyleComponentName(component);
    return noIdea.lookupFactory(name, component.container);
  }

}));

