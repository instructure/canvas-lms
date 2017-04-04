import I18n from 'i18n!blueprint_course_sidebar'
import React, { Component } from 'react'
import Tray from 'instructure-ui/lib/components/Tray'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import Heading from 'instructure-ui/lib/components/Heading'
import IconCopyLine from 'instructure-icons/react/Line/IconCopyLine'
import IconXSolid from 'instructure-icons/react/Solid/IconXSolid'

export default class BlueprintCourseSidebar extends Component {
  constructor (props) {
    super(props)
    this.state = {
      isOpen: false,
    }
  }

  handleOpen = () => {
    this.setState({ isOpen: true })
  }

  handleClose = () => {
    this.setState({ isOpen: false })
  }

  render () {
    return (
      <div className="bcs__wrapper">
        <div className="bcs__trigger">
          <Button variant="icon" onClick={this.handleOpen}>
            <Typography color="primary-inverse" size="large">
              <IconCopyLine title={I18n.t('Open sidebar')} />
            </Typography>
          </Button>
        </div>
        <Tray
          label={I18n.t('Blueprint Settings')}
          isDismissable={false}
          isOpen={this.state.isOpen}
          placement="right"
        >
          <div className="bcs__content">
            <header className="bcs__header">
              <Heading color="primary-inverse" level="h3">
                <div className="bcs__close-wrapper">
                  <Button variant="icon" onClick={this.handleClose} ref={(c) => { this.closeBtn = c }}>
                    <Typography color="primary-inverse" size="small">
                      <IconXSolid title={I18n.t('Close sidebar')} />
                    </Typography>
                  </Button>
                </div>
                <IconCopyLine />&nbsp;{I18n.t('Blueprint')}
              </Heading>
            </header>
          </div>
        </Tray>
      </div>
    )
  }
}
