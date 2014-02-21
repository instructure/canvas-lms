define [
  'ember'
  'jquery'
  'i18n!text_helper'
  'jquery.instructure_date_and_time' # fudgeDateForProfileTimezone, friendlyDatetime
], ({ObjectController, computed}, $, I18n) ->

  DueDateTableRowController = ObjectController.extend
    alwaysAvailable: (->
      !@get('lockAt') && !@get('unlockAt')
    ).property('lockAt', 'unlockAt')

    hasLockDateRange: computed.and 'lockAt', 'unlockAt'

    friendlyLockAt: (->
      return '' unless lockAt = @get 'lockAt'
      I18n.t 'until_lock_date', 'From %{date}', date: $.friendlyDatetime lockAt
    ).property('lockAt')

    friendlyUnlockAt: (->
      return '' unless unlockAt = @get 'unlockAt'
      I18n.t 'from_unlock_date', 'From %{date}', date: $.friendlyDatetime unlockAt
    ).property('unlockAt')

    friendlyDateRangeString: (->
      I18n.t 'time.ranges.different_days',
        "%{start_date_and_time} *to* %{end_date_and_time}",
        wrapper: '<span>$1</span>'
        start_date_and_time: @get('friendlyUnlockAt')
        end_date_and_time: @get('friendlyLockAt')
    ).property('hasLockDateRange')
