import React from 'react'
import I18n from 'i18n!masquerade'

import Modal, {ModalHeader, ModalBody} from 'instructure-ui/lib/components/Modal'
import Container from 'instructure-ui/lib/components/Container'
import Typography from 'instructure-ui/lib/components/Typography'
import Link from 'instructure-ui/lib/components/Link'
import Spinner from 'instructure-ui/lib/components/Spinner'

import MasqueradeMask from './MasqueradeMask'
import MasqueradePanda from './MasqueradePanda'

export default class MasqueradeModal extends React.Component {
  static propTypes = {
    user: React.PropTypes.shape({
      short_name: React.PropTypes.string,
      id: React.PropTypes.oneOfType([React.PropTypes.number, React.PropTypes.string])
    }).isRequired
  }

  constructor (props) {
    super(props)

    this.state = {
      isLoading: false
    }
  }

  componentWillMount () {
    if (window.location.href === document.referrer) {
      this.setState({isLoading: true})
      window.location.href = '/'
    }
  }

  handleModalRequestClose = () => {
    if (!document.referrer) {
      window.location.href = '/'
    } else {
      window.history.back()
    }
    this.setState({isLoading: true})
  }

  handleMasqueradeClick = () => {
    this.setState({isLoading: true})
  }

  render () {
    const user = this.props.user

    return (
      <span>
        <Modal
          onRequestClose={this.handleModalRequestClose}
          transition="fade"
          size="fullscreen"
          label={I18n.t('Act as User')}
          closeButtonLabel={I18n.t('Close')}
          isOpen
        >
          <ModalHeader>
            <Typography size="large">
              {I18n.t('Act as User')}
            </Typography>
          </ModalHeader>
          <ModalBody>
            {this.state.isLoading ?
              <div className="MasqueradeModal__loading">
                <Spinner title={I18n.t('Loading')} />
              </div>
            :
              <div className="MasqueradeModal__body">
                <div className="MasqueradeModal__svg">
                  <MasqueradePanda />
                </div>
                <div className="MasqueradeModal__svg">
                  <MasqueradeMask />
                </div>
                <div className="MasqueradeModal__text">
                  <Container
                    textAlign="center"
                    size="small"
                  >
                    <Container
                      textAlign="center"
                      padding="0 0 xSmall 0"
                    >
                      <Typography
                        size="x-large"
                        weight="light"
                      >
                        {I18n.t('Act as %{name}', { name: user.short_name })}
                      </Typography>
                    </Container>
                    <Typography
                      lineHeight="condensed"
                      size="small"
                    >
                      {I18n.t('"Act as" is essentially logging in as this user ' +
                        'without a password. You will be able to take any action ' +
                        'as if you were this user, and from other users\' points ' +
                        'of views, it will be as if this user performed them.')}
                    </Typography>
                    <br />
                    <Container
                      textAlign="center"
                      padding="small 0 0 0"
                    >
                      <Link
                        href={`/users/${user.id}/masquerade`}
                        data-method="post"
                        onClick={this.handleMasqueradeClick}
                      >
                        <Typography weight="bold">
                          {I18n.t('Act as User')}
                        </Typography>
                      </Link>
                    </Container>
                  </Container>
                </div>
              </div>
            }
          </ModalBody>
        </Modal>
      </span>
    )
  }
}
