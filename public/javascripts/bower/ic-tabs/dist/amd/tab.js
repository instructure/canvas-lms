define(
  ["ember","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Component = __dependency1__.Component;
    var computed = __dependency1__.computed;

    var alias = computed.alias;

    __exports__["default"] = Component.extend({

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
  });