import React, { Component } from 'react';
import themeable from '@instructure/ui-themeable/lib';

import styles from './styles.css';
import theme from './theme.js';

class ${COMPONENT} extends Component {
  render () {
    return (
      <div className={styles.root} />
    );
  }
}

export default themeable(theme, styles)(${COMPONENT});
