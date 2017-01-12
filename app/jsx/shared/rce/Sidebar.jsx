define([
  'jquery',
  'jsx/shared/rce/serviceRCELoader',
  'jsx/shared/rce/featureFlag',

  // for legacy pathways
  'wikiSidebar'
], function($, serviceRCELoader, featureFlag, wikiSidebar) {

  function loadServiceSidebar(callback) {
    serviceRCELoader.loadSidebarOnTarget($("#editor_tabs").get(0), callback)
  }

  function loadLegacySidebar(callback) {
    wikiSidebar.init()
    callback(wikiSidebar)
  }

  const Sidebar = {
    /**
     * variables to track singleton state and initialization status
     *
     * @private
     */
    instance: undefined,
    initializing: false,
    subscriptions: {},

    /**
     * initialize the sidebar. safe to call multiple times; if the sidebar is
     * already initialized or currently initializing, it won't be started
     * again. can also pass callbacks to execute any time the sidebar is shown
     * (`show`) or hidden (`hide`).
     *
     * @public
     */
    init(subscriptions={}) {
      if (!this.instance && !this.initializing) {
        this.initializing = true
        let callback = (sidebar) => {
          this.initializing = false
          this.instance = sidebar
        }
        if (featureFlag()) {
          loadServiceSidebar(callback)
        } else {
          loadLegacySidebar(callback)
        }
      }
      this.subscriptions = subscriptions
    },

    /**
     * show the sidebar, if initialized. no-op if the sidebar is not
     * initialized or even if it's currently initializing. if shown, triggers
     * any callbacks registered for `show` on init.
     *
     * @public
     */
    show() {
      if (this.instance) {
        this.instance.show()
        if (this.subscriptions.show) {
          this.subscriptions.show()
        }
      }
    },

    /**
     * hide the sidebar, if initialized. no-op if the sidebar is not
     * initialized or even if it's currently initializing. if hidden, triggers
     * any callbacks registered for `hide` on init.
     *
     * @public
     */
    hide() {
      if (this.instance) {
        this.instance.hide()
        if (this.subscriptions.hide) {
          this.subscriptions.hide()
        }
      }
    },

    /**
     * reset, for specs
     *
     * @private
     */
    reset() {
      this.instance = undefined
      this.initializing = false
      this.subscriptions = {}
    }
  }

  return Sidebar
})
