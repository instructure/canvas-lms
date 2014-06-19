"use strict";
var Component = require("ember").Component;
var computed = require("ember").computed;

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