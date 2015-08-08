/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'underscore',
  './DashboardCard',
  './DashboardCardBackgroundStore'
], function($, React, _, DashboardCard, DashboardCardBackgroundStore) {
  var DashboardCardBox = React.createClass({

    displayName: 'DashboardCardBox',

    propTypes: {
      courseCards: React.PropTypes.array
    },

    componentDidMount: function(){
      DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated);
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());
    },

    componentWillReceiveProps: function(){
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());
    },

    getDefaultProps: function () {
      return {
        courseCards: []
      };
    },

    colorsUpdated: function(){
      if(this.isMounted()){
        this.forceUpdate();
      }
    },

    allCourseAssetStrings: function(){
      return _.map(this.props.courseCards, (card) => card.assetString);
    },

    colorForCard: function(assetString){
      return DashboardCardBackgroundStore.colorForCourse(assetString);
    },

    handleColorChange: function(assetString, newColor){
      DashboardCardBackgroundStore.setColorForCourse(assetString, newColor);
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
              assetString={card.assetString}
              backgroundColor={this.colorForCard(card.assetString)}
              handleColorChange={this.handleColorChange.bind(this, card.assetString)}
            />
          </div>
        );
      }, this);
      return (
        <div className="ic-DashboardCard_Box grid-row">
          {cards}
        </div>
      );
    }
  });

  return DashboardCardBox;
});
