define([
  'react',
  'i18n!react_collaborations'
], (React, i18n) => {
  class LoadMore extends React.Component {

    static propTypes = {
      hasMore: React.PropTypes.bool.isRequired,
      loadMore: React.PropTypes.func.isRequired,
      isLoading: React.PropTypes.bool,
      children: React.PropTypes.any
    }

    componentDidUpdate (oldProps) {
      let oldCount = React.Children.count(oldProps.children)
      let newCount = React.Children.count(this.props.children)
      // not first results and not on delete
      if (oldCount > 0 && newCount > oldCount) {
        let element = this.refs.parent.querySelector(`*:nth-child(${oldCount + 1}) .lor-result a`)
        if (element) {
          element.focus()
        }
      }
    }

    render () {
      const hasChildren = React.Children.count(this.props.children) > 0
      const opacity = this.props.isLoading ? 1 : 0

      return (
        <div className='LoadMore' ref='parent'>
          {this.props.children}

          {this.props.hasMore && !this.props.isLoading &&
            <div className='LoadMore-button'>
              <button className='Button--link' onClick={this.props.loadMore}>
                {i18n.t('Load more results')}
              </button>
            </div>
          }

          {hasChildren && this.props.hasMore &&
            <div
              aria-hidden={!this.props.isLoading}
              className='LoadMore-loader'>
            </div>
          }
        </div>
      )
    }
  };

  LoadMore.propTypes = {
    hasMore: React.PropTypes.bool.isRequired,
    loadMore: React.PropTypes.func.isRequired,
    isLoading: React.PropTypes.bool,
    children: React.PropTypes.any
  };

  return LoadMore;
});
