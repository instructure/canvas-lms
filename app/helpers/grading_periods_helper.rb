module GradingPeriodsHelper
  def grading_period_set_title(set, root_account_name)
    if set.title.present?
      set.title
    else
      I18n.t("Grading Period Set for %{account_name}", account_name: root_account_name)
    end
  end
end
