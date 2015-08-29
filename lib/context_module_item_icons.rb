module ContextModuleItemIcons
  def self.complete_criterion_message(initial_message, completion_status, past_due)
    if completion_status
      I18n.t('Completed')
    elsif past_due
      "#{I18n.t('Item past due')}. #{initial_message}"
    else
      initial_message
    end
  end

  def self.initial_criterion_message(criterion, submission_status, highest_score)
    case criterion[:type]
    when 'must_submit'
      I18n.t('Must submit assignment')
    when 'must_mark_done'
      I18n.t('Must mark assignment as done')
    when 'must_view'
      I18n.t('Must view assignment')
    when 'min_score'
      min_score_criterion_message(criterion, submission_status, highest_score)
    else
      I18n.t('In progress')
    end
  end

  def self.min_score_criterion_message(criterion, submission_status, highest_score)
    main_message = I18n.t("Must score at least %{points} points", :points => criterion[:min_score])
    if submission_status == :submitted
      "#{I18n.t('You have submitted the assignment')}. #{main_message}"
    elsif submission_status == :fail
      "#{I18n.t('You scored')} #{highest_score}. #{main_message}"
    else
      main_message
    end
  end

  def self.module_item_progress_icon(context_module, context_module_progression, module_item, highest_submission_score)
    return false unless context_module_progression && context_module && module_item

    if !module_item_requirement?(context_module, module_item)
      {css_class: "no-icon", alt: I18n.t("no icon")}
    elsif context_module_progression["workflow_state"] == "completed" &&
          !module_item_completed?(context_module_progression, module_item)
      {css_class: "no-icon", alt: I18n.t("no icon")}
    elsif module_item_completed?(context_module_progression, module_item)
      {css_class: "icon-check", alt: I18n.t("completed icon")}
    elsif past_due_date?(module_item)
      {css_class: "icon-minimize", alt: I18n.t("warning icon")}
    elsif highest_submission_score && highest_submission_score < min_score_requirement(context_module, module_item)
      {css_class: "icon-minimize", alt: I18n.t("warning icon")}
    else
      {css_class: "icon-mark-as-read", alt: I18n.t("in-progress icon")}
    end
  end

  def self.submission_status(context_module, module_item, highest_submission_score)
    return false unless min_score_requirement?(context_module, module_item)
    min_score = min_score_requirement(context_module, module_item)
    submissions = module_item.assignment.submissions

    if highest_submission_score && highest_submission_score < min_score
      :fail
    elsif submissions.length > 0
      :submitted
    end
  end

  def self.module_item_requirement?(context_module, module_item)
    return false unless context_module && module_item
    context_module.completion_requirements.any? {|r| r[:id] == module_item.id}
  end

  def self.module_item_completed?(context_module_progression, module_item)
    return false unless context_module_progression && module_item
    context_module_progression["requirements_met"].any? {|r| r[:id] == module_item.id}
  end

  def self.min_score_requirement?(context_module, module_item)
    return false unless context_module && module_item
    context_module.completion_requirements.any? {|r| r[:id] == module_item.id && r[:type] == 'min_score'}
  end

  def self.past_due_date?(module_item)
    return false unless module_item.content_type == 'Assignment' || module_item.content_type == 'Quizzes::Quiz'

    assignment = module_item.assignment
    return false unless assignment
    submissions = assignment.submissions
    due_date = assignment.due_at

    due_date && Time.zone.now > due_date && submissions.length == 0
  end

  def self.min_score_requirement(context_module, module_item)
    return false unless module_item_requirement?(context_module, module_item)
    index = context_module.completion_requirements.index {|h| h[:id] == module_item.id}
    context_module.completion_requirements[index][:min_score].to_f
  end
end