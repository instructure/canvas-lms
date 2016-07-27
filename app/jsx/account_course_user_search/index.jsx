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

  const AccountCourseUserSearch = React.createClass({
    propTypes: {
      accountId: string.isRequired,
      permissions: shape({
        theme_editor: bool.isRequired,
        analytics: bool.isRequired
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
      const { timezones, permissions, accountId } = this.props;

      var tabs = [];
      var panels = [];
      if (permissions.can_read_course_list) {
        tabs.push(<Tab key='courses'>{I18n.t("Courses")}</Tab>);
        panels.push(
          <TabPanel key='coursePanel'>
            <CoursesPane roles={this.props.roles} addUserUrls={this.props.addUserUrls} />
          </TabPanel>
        );
      }
      if (permissions.can_read_roster) {
        tabs.push(<Tab key='people'>{I18n.t("People")}</Tab>);
        panels.push(
          <TabPanel key='peoplePanel'>
            <UsersPane store={this.props.store} />
          </TabPanel>
        );
      }

      return (
        <div>
          <div className="ic-Action-header">
            <div className="ic-Action-header__Primary">
              <h1 className="ic-Action-header__Heading">{I18n.t("Search")}</h1>
            </div>
            <div className="ic-Action-header__Secondary">
              {
                permissions.analytics &&
                <a href={`/accounts/${accountId}/analytics`} className="Button">{I18n.t("Analytics")}</a>
              }
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

  return AccountCourseUserSearch;
});
