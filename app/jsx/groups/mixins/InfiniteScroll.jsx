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
      var el = this.getDOMNode();
      var scrollTop = (window.pageYOffset !== undefined) ? window.pageYOffset : (document.documentElement || document.body.parentNode || document.body).scrollTop;
      if (this.topPosition(el) + el.offsetHeight - scrollTop - window.innerHeight < 100) {
        this.loadMore();
      }
    }, 100),

    attachScroll() {
      window.addEventListener('scroll', this.loadMoreIfNeeded);
      window.addEventListener('resize', this.loadMoreIfNeeded);
      this.loadMoreIfNeeded();
    },

    detachScroll() {
      window.removeEventListener('scroll', this.loadMoreIfNeeded);
      window.removeEventListener('resize', this.loadMoreIfNeeded);
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
