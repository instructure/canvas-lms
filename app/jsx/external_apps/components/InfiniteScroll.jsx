/** @jsx React.DOM */

define([
  'react'
], function(React) {

  function topPosition(domElt) {
    if (!domElt) {
      return 0;
    }
    return domElt.offsetTop + topPosition(domElt.offsetParent);
  }

  return React.createClass({
    displayName: 'InfiniteScroll',

    getDefaultProps() {
      return {
        pageStart: 0,
        hasMore: false,
        loadMore: function () {},
        threshold: 250
      };
    },

    componentDidMount() {
      this.pageLoaded = this.props.pageStart;
      this.attachScrollListener();
    },

    componentDidUpdate() {
      this.attachScrollListener();
    },

    render() {
      var props = this.props;
      return (
        <div>
          {this.props.children}
          {this.props.hasMore ? this.props.loader : null}
        </div>
      );
    },

    handleWindowScroll() {
      var el = this.getDOMNode();
      var scrollTop = (window.pageYOffset !== undefined) ? window.pageYOffset : (document.documentElement || document.body.parentNode || document.body).scrollTop;
      if (topPosition(el) + el.offsetHeight - scrollTop - window.innerHeight < Number(this.props.threshold)) {
        this.detachScrollListener();
        // call loadMore after detachScrollListener to allow
        // for non-async loadMore functions
        this.props.loadMore(this.pageLoaded += 1);
      }
    },

    attachScrollListener() {
      if (!this.props.hasMore) {
        return;
      }
      window.addEventListener('scroll', this.handleWindowScroll);
      window.addEventListener('resize', this.handleWindowScroll);
      this.handleWindowScroll();
    },

    detachScrollListener() {
      window.removeEventListener('scroll', this.handleWindowScroll);
      window.removeEventListener('resize', this.handleWindowScroll);
    },

    componentWillUnmount() {
      this.detachScrollListener();
    }

  });
});