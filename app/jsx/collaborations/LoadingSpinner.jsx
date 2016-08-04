define([
  'react',
  'i18n!react_collaborations'
], (React, i18n) => {
  class Spinner extends React.Component {
    render () {
      return (
        <div className='LoadingSpinner LoadingSpinner-medium LoadingSpinner-lightBg'>
          <svg
            className='circle'
            role="img"
            aria-labelledby='LoadingSpinner'>
            <title id='LoadingSpinner'>{i18n.t('Loading collaborations')}</title>
            <g role="presentation">
              <circle className='circleShadow' cx="50%" cy="50%" r='1.75em' />
              <circle className='circleTrack' cx="50%" cy="50%" r='1.75em' />
              <circle className='circleSpin' cx="50%" cy="50%" r='1.75em' />
            </g>
          </svg>
        </div>
      )
    }
  }

  return Spinner
})
