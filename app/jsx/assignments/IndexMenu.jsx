define([
  'underscore',
  'react',
  'react-dom',
  'i18n!assignment_index_menu',
  'jsx/shared/ExternalToolModalLauncher',
  './actions/IndexMenuActions',
], function (_, React, ReactDOM, I18n, ExternalToolModalLauncher, Actions) {
  return React.createClass({
    displayName: 'IndexMenu',

    propTypes: {
      store: React.PropTypes.object.isRequired,
      contextType: React.PropTypes.string.isRequired,
      contextId: React.PropTypes.number.isRequired,
      setTrigger: React.PropTypes.func.isRequired,
      registerWeightToggle: React.PropTypes.func.isRequired,
    },

    getInitialState () {
      return this.props.store.getState();
    },

    componentWillMount () {
      this.setState(this.getInitialState());
    },

    componentDidMount () {
      this.unsubscribe = this.props.store.subscribe(() => {
        this.setState(this.props.store.getState());
      });

      const toolsUrl = [
        '/api/v1/',
        this.props.contextType,
        's/',
        this.props.contextId,
        '/lti_apps/launch_definitions?placements[]=course_assignments_menu'
      ].join('');

      this.props.store.dispatch(Actions.apiGetLaunches(null, toolsUrl));
      this.props.setTrigger(this.refs.trigger);
      this.props.registerWeightToggle('weightedToggle', this.onWeightedToggle, this);
    },

    componentWillUnmount () {
      this.unsubscribe();
    },

    onWeightedToggle (value) {
      this.props.store.dispatch(Actions.setWeighted(value));
    },

    onLaunchTool (tool) {
      return (e) => {
        e.preventDefault();
        this.props.store.dispatch(Actions.launchTool(tool));
      };
    },

    closeModal () {
      this.props.store.dispatch(Actions.setModalOpen(false));
    },

    renderWeightIcon () {
      if (this.state && this.state.weighted) {
        return <i className="icon-check" />;
      }
      return <i className="icon-blank" />;
    },

    renderTools () {
      return this.state.externalTools.map(tool =>
        <li key={tool.definition_id} role="menuitem">
          <a aria-label={tool.name} href="#" onClick={this.onLaunchTool(tool)}>
            <i className="icon-import"></i>
            { tool.name }
          </a>
        </li>
      );
    },

    render () {
      return (
        <div className="inline-block">
          <a
            className="al-trigger btn"
            id="course_assignment_settings_link"
            role="button"
            tabIndex="0"
            title={I18n.t('Assignments Settings')}
            aria-label={I18n.t('Assignments Settings')}
          >
            <span className="screenreader-only">{I18n.t('Assignments Settings')}</span>
            <i className="icon-settings" /><i className="icon-mini-arrow-down" />
          </a>
          <ul
            className="al-options"
            role="menu"
          >
            <li role="menuitem">
              <a
                ref="trigger"
                href="#" id="assignmentSettingsCog" role="button"
                title={I18n.t('Assignment Groups Weight')}
                data-focus-returns-to="course_assignment_settings_link"
                aria-label={I18n.t('Assignment Groups Weight')}
              >
                { this.renderWeightIcon() }
                { I18n.t('Assignment Groups Weight')}
              </a>
            </li>
            {this.renderTools()}
          </ul>
          <ExternalToolModalLauncher
            tool={this.state.selectedTool}
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}
            contextType={this.props.contextType}
            contextId={this.props.contextId}
            launchType="course_assignments_menu"
            title={this.state.selectedTool && this.state.selectedTool.placements.course_assignments_menu.title}
          />
        </div>
      );
    }
  });
});
