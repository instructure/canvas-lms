/** @jsx React.DOM */

define([
  'jquery',
  'react',
  './DashboardCard'
], function($, React, DashboardCard) {

  var DashboardCardBox = React.createClass({
    displayName: 'DashboardCardBox',

    propTypes: {
      courseCards: React.PropTypes.array
    },

    getDefaultProps: function () {
      return {
        courseCards: []
      };
    },

    render: function () {
      var cards = this.props.courseCards.map(function(card) {
        return (
          <div className="col-xs-6 col-lg-4 card">
            <DashboardCard shortName={card.shortName}
              courseCode={card.courseCode}
              id={card.id}
              href={card.href}
              links={card.links}
              term={card.term}
            />
          </div>
        );
      });
      return (
        <div className="ic-DashboardCard_Box grid-row">
          {cards}
        </div>
      );
    }
  });

  return DashboardCardBox;
});
