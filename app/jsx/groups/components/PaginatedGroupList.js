import I18n from 'i18n!student_groups'
import React from 'react'
import InfiniteScroll from 'jsx/groups/mixins/InfiniteScroll'
import Group from 'jsx/groups/components/Group'
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

export default PaginatedGroupList
