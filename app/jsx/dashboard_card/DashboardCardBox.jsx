define([
  'jquery',
  'react',
  './DashboardCard',
  './DashboardCardBackgroundStore'
], function($, React, DashboardCard, DashboardCardBackgroundStore) {
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
      return this.props.courseCards.map(card => card.assetString);
    },

    colorForCard: function(assetString){
      return DashboardCardBackgroundStore.colorForCourse(assetString);
    },

    handleColorChange: function(assetString, newColor){
      DashboardCardBackgroundStore.setColorForCourse(assetString, newColor);
    },

    render: function () {
      var cards = this.props.courseCards.map((card) => {
        return (
          <DashboardCard 
            key={card.id}
            shortName={card.shortName}
            originalName={card.originalName}
            courseCode={card.courseCode}
            id={card.id}
            href={card.href}
            links={card.links}
            term={card.term}
            assetString={card.assetString}
            backgroundColor={this.colorForCard(card.assetString)}
            handleColorChange={this.handleColorChange.bind(this, card.assetString)}
            image={card.image}
            imagesEnabled={card.imagesEnabled}
          />
        );
      });
      return (
        <div className="ic-DashboardCard__box">
          {cards}
        </div>
      );
    }
  });

  return DashboardCardBox;
});
