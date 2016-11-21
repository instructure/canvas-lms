define([
  'i18n!format_range',
  './score',
], (I18n, scoreHelper) => {
  const isEnabled = () => ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED || false
  const parseEnvData = () => {
    const activeRules = ENV.CONDITIONAL_RELEASE_ENV && ENV.CONDITIONAL_RELEASE_ENV.active_rules || []
    return {
      triggerAssignments: activeRules.reduce((triggers, rule) => {
        triggers[rule.trigger_assignment] = rule
        return triggers
      }, {}),
      releasedAssignments: activeRules.reduce((released, rule) => {
        rule.scoring_ranges.forEach(range => {
          range.assignment_sets.forEach(set => {
            set.assignments.forEach(asg => {
              const id = asg.assignment_id
              released[id] = released[id] || []
              released[id].push({
                assignment_id: rule.trigger_assignment,
                assignment: rule.trigger_assignment_model,
                upper_bound: range.upper_bound,
                lower_bound: range.lower_bound,
              })
            })
          })
        })
        return released
      }, {}),
    }
  }

  let data = parseEnvData()
  const isTrigger = (asgId) => data.triggerAssignments.hasOwnProperty(asgId)
  const isReleased = (asgId) => data.releasedAssignments.hasOwnProperty(asgId)
  const formatRange = (asgId) => {
    const ranges = data.releasedAssignments[asgId] || []
    if (ranges.length > 1) {
      return I18n.t('Multiple')
    } else if (ranges.length > 0) {
      const range = ranges[0]
      return I18n.t('%{upper} - %{lower}', {
        upper: scoreHelper.transformScore(range.upper_bound, range.assignment, true),
        lower: scoreHelper.transformScore(range.lower_bound, range.assignment, false),
      })
    } else {
      return null
    }
  }

  return {
    isEnabled,
    reloadEnv () {
      data = parseEnvData()
    },
    getItemData (asgId, isGraded = true) {
      asgId = asgId && asgId.toString()
      return isEnabled()
      ? {
        isCyoeAble: asgId && isGraded,
        isTrigger: asgId && isGraded && isTrigger(asgId),
        isReleased: isReleased(asgId),
        releasedLabel: formatRange(asgId),
      }
      : {}
    },
  }
})
