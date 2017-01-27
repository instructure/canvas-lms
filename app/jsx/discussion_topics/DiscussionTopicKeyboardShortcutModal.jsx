import React from 'react'
import KeyboardShortcutModal from 'jsx/shared/KeyboardShortcutModal'
import I18n from 'i18n!react_files'

  var SHORTCUTS = [
    { keycode: 'j', description: I18n.t('Next Message') },
    { keycode: 'k', description: I18n.t('Previous Message') },
    { keycode: 'e', description: I18n.t('Edit Current Message') },
    { keycode: 'd', description: I18n.t('Delete Current Message') },
    { keycode: 'r', description: I18n.t('Reply to Current Message') },
    { keycode: 'n', description: I18n.t('Reply to Topic') }
  ];

  var DiscussionTopicKeyboardShortcutModal = React.createClass({
    render() {
      return <KeyboardShortcutModal {...this.props} shortcuts={SHORTCUTS} />;
    }
  });

export default DiscussionTopicKeyboardShortcutModal
