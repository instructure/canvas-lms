/** @jsx React.DOM */

define([
  'underscore'
], (_) => {
  var InfiniteScroll = {
    topPosition(el) {
      if (!el) {
        return 0;
      }
      return el.offsetTop + this.topPosition(el.offsetParent);
    },

    loadMoreIfNeeded: _.throttle(function() {
      var atBottom = false;
      if (this.scrollElement) {
        atBottom = this.scrollElement.scrollTop + this.scrollElement.clientHeight + 100 >= this.scrollElement.scrollHeight;
      } else {
        var el = this.getDOMNode();
        var scrollTop = (window.pageYOffset !== undefined) ? window.pageYOffset : (document.documentElement || document.body.parentNode || document.body).scrollTop;
        atBottom = this.topPosition(el) + el.offsetHeight - scrollTop - window.innerHeight < 100;
      }
      if (atBottom) {
        this.loadMore();
      }
    }, 100),

    attachScroll() {
      if (this.refs.scrollElement) {
        this.scrollElement = this.refs.scrollElement.getDOMNode();
      }
      (this.scrollElement || window).addEventListener('scroll', this.loadMoreIfNeeded);
      (this.scrollElement || window).addEventListener('resize', this.loadMoreIfNeeded);
      this.loadMoreIfNeeded();
    },

    detachScroll() {
      (this.scrollElement || window).removeEventListener('scroll', this.loadMoreIfNeeded);
      (this.scrollElement || window).removeEventListener('resize', this.loadMoreIfNeeded);
      this.scrollElement = null;
    },

    componentDidMount() {
      this.attachScroll();
    },

    componentDidUpdate() {
      this.attachScroll();
    },

    componentWillUnmount() {
      this.detachScroll();
    },

  };
  return InfiniteScroll;
});
