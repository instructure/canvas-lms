Feature.register('submissions_folder' => {
  display_name: -> { I18n.t('Submissions Folder') },
  description: -> { I18n.t('Upload files submitted with assignments to a special read-only Submissions folder') },
  applies_to: 'RootAccount',
  state: 'hidden',
  custom_transition_proc: ->(user, context, from_state, transitions) {
    if from_state == 'on'
      transitions['off'] = { 'locked' => true, 'message' => I18n.t('This feature cannot be disabled once it has been turned on.') }
    else
      transitions['on'] = { 'locked' => false, 'message' => I18n.t('Once this feature is enabled, you will not be able to turn it off again.  Ensure you are ready to enable the Submissions Folder before proceeding.') }
    end
  }
})
