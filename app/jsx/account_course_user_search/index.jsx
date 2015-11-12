define([
  "react",
  "i18n!account_course_user_search",
  "bower/react-tabs/dist/react-tabs",
  "underscore",
  "./CoursesPane",
  "./UsersPane",
  "./CoursesStore",
  "./TermsStore",
  "./AccountsTreeStore",
  "./UsersStore"
], function(React, I18n, ReactTabs, _, CoursesPane, UsersPane, CoursesStore, TermsStore, AccountsTreeStore, UsersStore) {

  var { Tab, Tabs, TabList, TabPanel } = ReactTabs;
  var { string, bool, shape } = React.PropTypes;

  var stores = [CoursesStore, TermsStore, AccountsTreeStore, UsersStore];

  var App = React.createClass({
    propTypes: {
      accountId: string.isRequired,
      permissions: shape({
        theme_editor: bool.isRequired
      }).isRequired
    },

    getInitialState() {
      return {
        selectedTab: 0
      }
    },

    componentWillMount() {
      stores.forEach((s) => s.reset({accountId: this.props.accountId}));
    },

    handleSelected(selectedTab) {
      this.setState({selectedTab});
    },

    render() {
      var { permissions, accountId } = this.props;

      var tabs = [];
      var panels = [];
      if (permissions.can_read_course_list) {
        tabs.push(<Tab>{I18n.t("Courses")}</Tab>);
        panels.push(
          <TabPanel>
            <CoursesPane />
          </TabPanel>
        );
      }
      if (permissions.can_read_roster) {
        tabs.push(<Tab>{I18n.t("People")}</Tab>);
        panels.push(
          <TabPanel>
            <UsersPane accountId={accountId}/>
          </TabPanel>
        );
      }

      return (
        <div>
          <div className="pad-box-mini no-sides grid-row middle-xs margin-none">
            <div className="col-xs-8 padding-none">
              <h1>{I18n.t("Search")}</h1>
            </div>
            <div className="col-xs-4 padding-none align-right">
              <div>
                {/* TODO: figure out a way for plugins to inject stuff like
                  <a href="" className="btn button-group">{I18n.t("Analytics")}</a>
                  w/o defining them here
                  */}
                {
                  permissions.theme_editor &&
                  <a href={`/accounts/${accountId}/theme_editor`} className="btn button-group">{I18n.t("Theme Editor")}</a>
                }
              </div>
            </div>
          </div>

          <Tabs
            onSelect={this.handleSelected}
            selectedIndex={this.state.selectedTab}
          >
            <TabList>
              {tabs}
            </TabList>
            {panels}
          </Tabs>
        </div>
      );
    }
  });

  return App;
});
