/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'old_unsupported_dont_use_react',
  'jsx/groups/mixins/InfiniteScroll',
  'jsx/groups/components/Group'

], (I18n, React, InfiniteScroll, Group) => {
  var PaginatedGroupList = React.createClass({
    mixins: [InfiniteScroll],

    loadMore() {
      this.props.loadMore();
    },

    render() {
      var groups = this.props.groups.map(g => <Group key={g.id}
                                                     group={g}
                                                     onLeave={() => this.props.onLeave(g)}
                                                     onJoin={() => this.props.onJoin(g)}
                                                     onManage={() => this.props.onManage(g)} />);
      return (
        <div role="list" aria-label={I18n.t("Groups")}>
          {groups}
        </div>);
    }
  });

  return PaginatedGroupList;
});
