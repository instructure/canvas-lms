define([
  'jquery',
  'react',
  './DashboardCard',
  './DraggableDashboardCard',
  './DashboardCardBackgroundStore',
  './MovementUtils'
], ($, React, DashboardCard, DraggableDashboardCard, DashboardCardBackgroundStore, MovementUtils) => {
  const DashboardCardBox = React.createClass({

    displayName: 'DashboardCardBox',

    propTypes: {
      courseCards: React.PropTypes.array,
      reorderingEnabled: React.PropTypes.bool,
      connectDropTarget: React.PropTypes.func
    },

    componentWillMount () {
      this.setState({
        courseCards: this.props.courseCards
      });
    },

    componentDidMount: function(){
      DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated);
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());
    },

    componentWillReceiveProps: function (newProps) {
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());

      this.setState({
        courseCards: newProps.courseCards
      });
    },

    getDefaultProps: function () {
      return {
        courseCards: []
      };
    },

    moveCard (assetString, atIndex) {
      const cardIndex = this.state.courseCards.findIndex(card => card.assetString === assetString);
      let newCards = this.state.courseCards.slice();
      newCards.splice(atIndex, 0, newCards.splice(cardIndex, 1)[0]);
      newCards = newCards.map((card, index) => {
        const newCard = Object.assign({}, card);
        newCard.position = index;
        return newCard;
      });
      this.setState({
        courseCards: newCards
      }, () => {
        MovementUtils.updatePositions(this.state.courseCards, window.ENV.current_user_id);
      });
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

    getOriginalIndex (assetString) {
      return this.state.courseCards.findIndex(c => c.assetString === assetString);
    },

    render: function () {
      const Component = (this.props.reorderingEnabled) ? DraggableDashboardCard : DashboardCard;
      const cards = this.state.courseCards.map((card, index) => {
        const position = (card.position != null) ? card.position : this.getOriginalIndex.bind(this, card.assetString)
        return (
          <Component
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
            reorderingEnabled={this.props.reorderingEnabled}
            position={position}
            currentIndex={index}
            moveCard={this.moveCard}
            totalCards={this.state.courseCards.length}
          />
        );
      });

      const dashboardCardBox = (
        <div className="ic-DashboardCard__box">
          {cards}
        </div>
      );

      if (this.props.reorderingEnabled) {
        const { connectDropTarget } = this.props;
        return connectDropTarget(dashboardCardBox);
      }

      return dashboardCardBox;
    }
  });

  return DashboardCardBox;
});
