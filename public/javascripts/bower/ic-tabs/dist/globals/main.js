!function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),(f.ic||(f.ic={})).tabs=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
"use strict";
var TabComponent = _dereq_("./tab")["default"] || _dereq_("./tab");
var TabListComponent = _dereq_("./tab-list")["default"] || _dereq_("./tab-list");
var TabPanelComponent = _dereq_("./tab-panel")["default"] || _dereq_("./tab-panel");
var TabsComponent = _dereq_("./tabs")["default"] || _dereq_("./tabs");
var tabsCssTemplate = _dereq_("./tabs-css")["default"] || _dereq_("./tabs-css");
var Application = window.Ember.Application;

Application.initializer({
  name: 'ic-tabs',
  initialize: function(container) {
    container.register('component:ic-tab',       TabComponent);
    container.register('component:ic-tab-list',  TabListComponent);
    container.register('component:ic-tab-panel', TabPanelComponent);
    container.register('component:ic-tabs',      TabsComponent);
    container.register('template:components/ic-tabs-css', tabsCssTemplate);
  }
});

exports.TabComponent = TabComponent;
exports.TabListComponent = TabListComponent;
exports.TabPanelComponent = TabPanelComponent;
exports.TabsComponent = TabsComponent;
},{"./tab":4,"./tab-list":2,"./tab-panel":3,"./tabs":6,"./tabs-css":5}],2:[function(_dereq_,module,exports){
"use strict";
var Component = window.Ember.Component;
var ArrayProxy = window.Ember.ArrayProxy;
var computed = window.Ember.computed;

exports["default"] = Component.extend({

  tagName: 'ic-tab-list',

  attributeBindings: [
    'role',
    'aria-multiselectable'
  ],

  /**
   * See http://www.w3.org/TR/wai-aria/roles#tablist
   *
   * @property role
   * @type String
   */

  role: 'tablist',

  /**
   * Tells screenreaders that only one tab can be selected at a time.
   *
   * @property 'aria-multiselectable'
   * @private
   */

  'aria-multiselectable': false,

  /**
   * The currently selected tab.
   *
   * @property activeTab
   */

  activeTab: computed.alias('parentView.activeTab'),

  /**
   * Registers itself with the ic-tab component.
   *
   * @method registerWithTabs
   * @private
   */

  registerWithTabs: function() {
    this.get('parentView').registerTabList(this);
  }.on('didInsertElement'),

  /**
   * Storage for all tab components, facilitating keyboard navigation.
   *
   * @property tabs
   * @type ArrayProxy
   */

  tabs: null,

  /**
   * Creates the tabs ArrayProxy on init (otherwise would be shared by every
   * instance)
   *
   * @private
   */

  createTabs: function() {
    this.set('tabs', ArrayProxy.create({content: []}));
  }.on('init'),

  /**
   * Adds a tab to the tabs ArrayProxy.
   *
   * @method registerTab
   * @private
   */

  registerTab: function(tab) {
    this.get('tabs').addObject(tab);
  },

  unregisterTab: function(tab) {
    var tabs = this.get('tabs');
    var index = tab.get('index');
    var parent = this.get('parentView');
    tabs.removeObject(tab);
    if (parent.get('activeTab') == tab) {
      if (tabs.get('length') === 0) return;
      var index = (index === 0) ? index : index - 1;
      var tab = tabs.objectAt(index);
      parent.select(tab);
    }
  },

  /**
   * Sets up keyboard navigation.
   *
   * @method navigateOnKeyDown
   * @private
   */

  navigateOnKeyDown: function(event) {
    var key = event.keyCode;
    if (key == 37 /*<*/ || key == 38 /*^*/) {
      this.selectPrevious();
    } else if (key == 39 /*>*/ || key == 40 /*v*/) {
      this.selectNext();
    } else {
      return;
    }
    event.preventDefault();
  }.on('keyDown'),

  /**
   * Tracks the index of the active tab so we can select previous/next.
   *
   * @property activeTabIndex
   * @type Number
   */

  activeTabIndex: function() {
    return this.get('tabs').indexOf(this.get('activeTab'));
  }.property('activeTab'),

  /**
   * Selects the next tab in the list, or loops to the beginning.
   *
   * @method selectNext
   * @private
   */

  selectNext: function() {
    var index = this.get('activeTabIndex') + 1;
    if (index == this.get('tabs.length')) { index = 0; }
    this.selectTabAtIndex(index);
  },

  /**
   * Selects the previous tab in the list, or loops to the end.
   *
   * @method selectPrevious
   * @private
   */

  selectPrevious: function() {
    var index = this.get('activeTabIndex') - 1;
    if (index == -1) { index = this.get('tabs.length') - 1; }
    this.selectTabAtIndex(index);
  },

  /**
   * Selects a tab at an index.
   *
   * @method selectTabAtIndex
   * @private
   */

  selectTabAtIndex: function(index) {
    var tab = this.get('tabs').objectAt(index);
    tab.select({focus: true});
  }

});
},{}],3:[function(_dereq_,module,exports){
"use strict";
var Component = window.Ember.Component;
var computed = window.Ember.computed;

exports["default"] = Component.extend({

  tagName: 'ic-tab-panel',

  attributeBindings: [
    'role',
    'aria-labeledby'
  ],

  // TODO: remove this, toggleVisibility won't fire w/o it though (?)
  classNameBindings: ['active'],

  /**
   * See http://www.w3.org/TR/wai-aria/roles#tabpanel
   *
   * @property role
   * @type String
   * @private
   */

  role: 'tabpanel',

  /**
   * Reference to the TabListComponent instance, used so we can find the
   * associated tab.
   *
   * @property tabList
   * @type TabListComponent
   * @private
   */

  tabList: computed.alias('parentView.tabList'),

  /**
   * Reference to the ArrayProxy of TabPanelComponent instances.
   *
   * @property tabPanels
   * @type ArrayProxy
   * @private
   */

  tabPanels: computed.alias('parentView.tabPanels'),

  /**
   * Tells screenreaders which tab labels this panel.
   *
   * @property 'aria-labeledby'
   * @type String
   * @private
   */

  'aria-labeledby': computed.alias('tab.elementId'),

  /**
   * Reference to this panel's associated tab.
   *
   * @property tab
   * @type TabComponent
   */

  tab: function() {
    var index = this.get('tabPanels').indexOf(this);
    var tabs = this.get('tabList.tabs');
    return tabs && tabs.objectAt(index);
  }.property('tabList.tabs.@each'),

  /**
   * Tells whether or not this panel is active.
   *
   * @property active
   * @type Boolean
   */

  active: function() {
    return this.get('tab.active');
  }.property('tab.active'),

  /**
   * Shows or hides this panel depending on whether or not its active.
   *
   * @method toggleVisibility
   * @private
   */

  toggleVisibility: function() {
    var display = this.get('active') ? '' : 'none';
    this.$().css('display', display);
  }.observes('active'),

  /**
   * Registers with the TabsComponent.
   *
   * @method registerWithTabs
   * @private
   */

  registerWithTabs: function() {
    this.get('parentView').registerTabPanel(this);
  }.on('didInsertElement'),

  unregisterWithTabs: function() {
    this.get('parentView').unregisterTabPanel(this);
  }.on('willDestroyElement')

});
},{}],4:[function(_dereq_,module,exports){
"use strict";
var Component = window.Ember.Component;
var computed = window.Ember.computed;

var alias = computed.alias;

exports["default"] = Component.extend({

  tagName: 'ic-tab',

  attributeBindings: [
    'role',
    'aria-controls',
    'aria-selected',
    'aria-expanded',
    'tabindex',
    'selected'
  ],

  /**
   * See http://www.w3.org/TR/wai-aria/roles#tab
   *
   * @property role
   * @type String
   * @private
   */

  role: 'tab',

  /**
   * Sets the [selected] attribute on the element when this tab is active.
   * Makes sure to remove the attribute completely when not selected.
   *
   * @property selected
   * @type Boolean
   */

  selected: function() {
    return this.get('active') ? 'selected' : null;
  }.property('active'),

  /**
   * Makes the selected tab keyboard tabbable, also prevents tabs from getting
   * focus when clicked with a mouse.
   *
   * @property tabindex
   * @type Number
   */

  tabindex: function() {
    return this.get('active') ? 0 : null;
  }.property('active'),

  /**
   * Reference to the parent TabsComponent instance.
   *
   * @property tabs
   * @type TabsComponent
   */

  tabs: alias('parentView.parentView'),

  /**
   * Reference to the parent TabListComponent instance.
   *
   * @property tabs
   * @type TabList
   */

  tabList: alias('parentView'),

  /**
   * Tells screenreaders which panel this tab controls.
   *
   * @property 'aria-controls'
   * @type String
   * @private
   */

  'aria-controls': alias('tabPanel.elementId'),

  /**
   * Tells screenreaders whether or not this tab is selected.
   *
   * @property 'aria-selected'
   * @type String
   * @private
   */

  'aria-selected': function() {
    // coerce to ensure a "true" or "false" attribute value
    return this.get('active')+'';
  }.property('active'),

  /**
   * Tells screenreaders whether or not this tabs panel is expanded.
   *
   * @property 'aria-expanded'
   * @type String
   * @private
   */

  'aria-expanded': alias('aria-selected'),

  /**
   * Whether or not this tab is selected.
   *
   * @property active
   * @type Boolean
   */

  active: function(key, val) {
    return this.get('tabs.activeTab') === this;
  }.property('tabs.activeTab'),

  /**
   * Selects this tab, bound to click.
   *
   * @method select
   * @param [options]
   *   @param {*} [options.focus] - focuses the element when selected.
   */

  select: function(options) {
    this.get('tabs').select(this);
    if (options && options.focus) {
      Ember.run.schedule('afterRender', this, function() {
        this.$().focus();
      });
    }
  }.on('click'),

  /**
   * The index of this tab in the TabListComponent instance.
   *
   * @property index
   * @type Number
   */

  index: function() {
    return this.get('tabList.tabs').indexOf(this);
  }.property('tabList.tabs.@each'),

  /**
   * Reference to the associated TabPanel instance.
   *
   * @property tabPanel
   * @type TabPanelComponent
   */

  tabPanel: function() {
    var index = this.get('index');
    var panels = this.get('tabs.tabPanels');
    return panels && panels.objectAt(index);
  }.property('tabs.tabPanels.@each'),

  /**
   * Selects this tab when the TabsComponent selected-index property matches
   * the index of this tab. Mostly useful for query-params support.
   *
   * @method selectFromTabsSelectedIndex
   * @private
   */

  selectFromTabsSelectedIndex: function() {
    var activeTab = this.get('tabs.activeTab');
    if (activeTab === this) return; // this was just selected
    var index = parseInt(this.get('tabs.selected-index'), 10);
    var myIndex = this.get('index');
    if (index === myIndex) {
      this.select();
    }
  }.observes('tabs.selected-index').on('didInsertElement'),

  /**
   * Registers this tab with the TabListComponent instance.
   *
   * @method registerWithTabList
   * @private
   */

  registerWithTabList: function() {
    this.get('tabList').registerTab(this);
  }.on('didInsertElement'),

  unregisterWithTabList: function() {
    this.get('tabList').unregisterTab(this);
  }.on('willDestroyElement')


});
},{}],5:[function(_dereq_,module,exports){
"use strict";
var Ember = window.Ember["default"] || window.Ember;
exports["default"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("ic-tabs,\nic-tab-list,\nic-tab-panel {\n  display: block\n}\n\nic-tab-list {\n  border-bottom: 1px solid #aaa;\n}\n\nic-tab {\n  display: inline-block;\n  padding: 6px 12px;\n  border: 1px solid transparent;\n  border-top-left-radius: 3px;\n  border-top-right-radius: 3px;\n  cursor: pointer;\n  margin-bottom: -1px;\n  position: relative;\n}\n\nic-tab[selected] {\n  border-color: #aaa;\n  border-bottom-color: #fff;\n}\n\nic-tab:focus {\n  box-shadow: 0 10px 0 0 #fff,\n              0 0 5px hsl(208, 99%, 50%);\n  border-color: hsl(208, 99%, 50%);\n  border-bottom-color: #fff;\n  outline: none;\n}\n\nic-tab:focus:before,\nic-tab:focus:after {\n  content: '';\n  position: absolute;\n  bottom: -6px;\n  width: 5px;\n  height: 5px;\n  background: #fff;\n}\n\nic-tab:focus:before {\n  left: -4px;\n}\n\nic-tab:focus:after {\n  right: -4px;\n}\n\n");
  
});
},{}],6:[function(_dereq_,module,exports){
"use strict";
var Component = window.Ember.Component;
var ArrayProxy = window.Ember.ArrayProxy;
var computed = window.Ember.computed;

exports["default"] = Component.extend({

  tagName: 'ic-tabs',

  /**
   * The selected TabComponent instance.
   *
   * @property activeTab
   * @type TabComponent
   */

  activeTab: null,

  /**
   * The TabPanelComponent instances.
   *
   * @property tabPanels
   * @type ArrayProxy
   */

  tabPanels: null,

  /**
   * Set this to the tab you'd like to be active. Usually it is bound to a
   * controller property that is used as a query parameter, but can be bound to
   * anything.
   *
   * @property 'selected-index'
   * @type Number
   */

  'selected-index': 0,

  /**
   * Creates the `tabPanels` ArrayProxy.
   *
   * @method createTabPanels
   * @private
   */

  createTabPanels: function(tabList) {
    this.set('tabPanels', ArrayProxy.create({content: []}));
  }.on('init'),

  /**
   * Selects a tab.
   *
   * @method select
   */

  select: function(tab) {
    this.set('activeTab', tab);
    this.set('selected-index', tab.get('index'));
  },

  /**
   * Registers the TabListComponent instance.
   *
   * @method registerTabList
   * @private
   */

  registerTabList: function(tabList) {
    this.set('tabList', tabList);
  },

  /**
   * Registers TabPanelComponent instances so related components can access
   * them.
   *
   * @method registerTabPanel
   * @private
   */

  registerTabPanel: function(tabPanel) {
    this.get('tabPanels').addObject(tabPanel);
  },

  unregisterTabPanel: function(tabPanel) {
    this.get('tabPanels').removeObject(tabPanel);
  }

});
},{}]},{},[1])
(1)
});