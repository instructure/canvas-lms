define([
  'reflux',
  'underscore',
  'jsx/gradebook/grid/actions/sectionsActions',
  'compiled/userSettings'
], function(Reflux, _, SectionsActions, userSettings) {
  var SectionsStore = Reflux.createStore({
    listenables: [SectionsActions],

    init() {
      this.state = {
        sections: null,
        error: null,
        selected: this.sectionOnLoad()
      };
    },

    getInitialState() {
      if (this.state === undefined) {
        this.init();
      }

      return this.state;
    },

    onLoadCompleted(sectionData) {
      var allSectionsOption;

      allSectionsOption = {
        id: '0',
        name: 'All Sections'
      };

      sectionData.unshift(allSectionsOption);

      this.state.sections = sectionData;
      this.trigger(this.state);
    },

    onLoadFailed(error) {
      this.state.error = error;
      this.trigger(this.state);
    },

    onSelectSection(sectionId) {
      this.state.selected = sectionId;
      this.trigger(this.state);
    },

    sectionOnLoad() {
      var defaultSectionId = '0';
      return userSettings.contextGet('grading_show_only_section') || defaultSectionId;
    },

    selected() {
      var selectedId, currentSection, sections;

      selectedId = this.state.selected;
      sections = this.state.sections;

      currentSection = _.find(sections, section => section.id === selectedId);

      return currentSection;
    },
  });

  return SectionsStore;
});
