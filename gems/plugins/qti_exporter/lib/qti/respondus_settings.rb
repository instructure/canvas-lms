module Qti

class RespondusSettings

  attr_reader :doc

  def initialize(doc)
    @doc = doc
  end

  def apply(assessment)
    return unless read_setting('hasSettings') == 'true'
    apply_if_set(assessment, :description, 'instructions')
    apply_if_set(assessment, :allowed_attempts, 'attempts') { |v| v == 'unlimited' ? -1 : v.to_i }
    apply_if_set(assessment, :time_limit, 'timeLimit') { |v| v == 'unlimited' ? nil : v.to_f }
    apply_if_set(assessment, :unlock_at, 'availableFrom') { |v| readtime(v) }
    apply_if_set(assessment, :lock_at, 'availableTo') { |v| readtime(v) }
    apply_if_set(assessment, :access_code, 'password')
    apply_if_set(assessment, :ip_filter, 'ipRestriction') { |v| v == 'unlimited' ? nil : v }
    apply_if_set(assessment, :shuffle_answers, 'shuffleAnswers') { |v| v == 'true' }
    apply_if_set(assessment, :due_at, 'dueDate') { |v| readtime(v) }
    if read_setting('publishNow') == 'true'
      assessment[:available] = true
      assessment[:assignment] = {
        :title => assessment[:title],
        :submission_types => "online_quiz"
      }
    end

    feedback = read_csv_setting('feedbackOptions')
    if feedback.include?('showResults') || feedback.include?('all')
      if feedback.include?('lastAttemptOnly')
         assessment[:hide_results] = 'until_after_last_attempt'
      else
        assessment[:hide_results] = {'never' => '1'}
      end
    elsif feedback.include?('none')
      assessment[:hide_results] = 'always'
    end

    ldb = read_csv_setting('lockDownBrowser')
    assessment['require_lockdown_browser'] = true if ldb.include?('assessment')
    assessment['require_lockdown_browser_for_results'] = true if ldb.include?('results')

    apply_if_set(assessment, :scoring_policy, 'attemptGrading') do |v|
      case v
      when 'last'
        'keep_latest'
      when 'highest'
        'keep_highest'
      else
        nil
      end
    end
  end

  protected

  def apply_if_set(assessment, key, setting_name, &block)
    if setting = read_setting(setting_name)
      assessment[key] = block ? block.call(setting) : setting
    end
  end

  def readtime(v)
    v == 'unlimited' ? nil : Time.at(v.to_i)
  end

  def read_setting(setting_name)
    @doc.at_css("settings setting[name=#{setting_name}]").try(:text)
  end

  def read_csv_setting(setting_name)
    (read_setting(setting_name) || "").split(",")
  end

end

end
