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
      var name = getStyleComponentName(this);
      var css = Style.create().renderToBuffer().buffer;
      inject(name, css);
    }.on('willInsertElement')
  });

  function getStyleComponentName(component) {
    var tagName = component.get('tagName');
    // do not use _debugContainerKey without permission from Stefan Penner
    var key = component._debugContainerKey;
    if ((!tagName || tagName.indexOf('-') == -1) && key) {
      tagName = key.split(':')[1];
    }
    return tagName+'-css';
  }

  function lookupStyleComponent(component) {
    var noIdea = component.container.lookup('component-lookup:main');
    var name = getStyleComponentName(component);
    return noIdea.lookupFactory(name, component.container);
  }

  function getStyleTag() {
    var style = document.createElement('style');
    style.setAttribute('id', 'ic-styled-styles');
    var head = document.getElementsByTagName('head')[0];
    head.insertBefore(style, head.firstChild);
    getStyleTag = function() { return style; };
    return style;
  }

  function inject(name, css) {
    var styleTag = getStyleTag();
    var comment = '\n\n/* ic-styled: '+name+' */\n\n';
    styleTag.appendChild(document.createTextNode(comment+css));
  }

}));

