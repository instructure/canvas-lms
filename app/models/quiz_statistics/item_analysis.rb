class QuizStatistics::ItemAnalysis

  def initialize(quiz)
    @quiz = quiz
  end

  attr_reader :quiz

  def save!
    quiz.csv_attachments.create!(
      :uploaded_data => StringIO.new(csv),
      :filename => filename
    )
  end

  def filename
    "quiz-item-analysis-#{Time.now.to_i}.csv"
  end

  def csv
    @csv ||=
      FasterCSV.generate do |csv|
        stats = QuizStatistics::ItemAnalysis::Summary.new(quiz)
        headers = [
          I18n.t('csv.question.id',                  'Question Id'),
          I18n.t('csv.question.title',               'Question Title'),
          I18n.t('csv.answered.student.count',       'Answered Student Count'),
          I18n.t('csv.top.student.count',            'Top Student Count'),
          I18n.t('csv.middle.student.count',         'Middle Student Count'),
          I18n.t('csv.bottom.student.count',         'Bottom Student Count'),
          I18n.t('csv.quiz.question.count',          'Quiz Question Count'),
          I18n.t('csv.correct.student.count',        'Correct Student Count'),
          I18n.t('csv.wrong.student.count',          'Wrong Student Count'),
          I18n.t('csv.correct.student.ratio',        'Correct Student Ratio'),
          I18n.t('csv.wrong.student.ratio',          'Wrong Student Ratio'),
          I18n.t('csv.correct.top.student.count',    'Correct Top Student Count'),
          I18n.t('csv.correct.middle.student.count', 'Correct Middle Student Count'),
          I18n.t('csv.correct.bottom.student.count', 'Correct Bottom Student Count'),
          I18n.t('csv.variance',                     'Variance'),
          I18n.t('csv.standard.deviation',           'Standard Deviation'),
          I18n.t('csv.difficulty.index',             'Difficulty Index'),
          I18n.t('csv.alpha',                        'Alpha'),
          I18n.t('csv.point.biserial',               'Point Biserial of Correct')
        ]
        point_biserial_max_count = stats.map {|item| item.point_biserials.size }.max
        (point_biserial_max_count - 1).times do |i|
          headers << I18n.t("csv.point.distractor", 'Point Biserial of Distractor %{num}', :num => i + 2)
        end
        csv << headers
        stats.each do |item|
          row = [
            item.question[:id],
            item.question_text,
            item.num_respondents,
            item.num_respondents(:top),
            item.num_respondents(:middle),
            item.num_respondents(:bottom),
            stats.size,
            item.num_respondents(:correct),
            item.num_respondents(:incorrect),
            item.ratio_for(:correct),
            item.ratio_for(:incorrect),
            item.num_respondents(:top, :correct),
            item.num_respondents(:middle, :correct),
            item.num_respondents(:bottom, :correct),
            item.variance,
            item.standard_deviation,
            item.difficulty_index,
            stats.alpha
          ]
          point_biserial_max_count.times do |i|
            row << item.point_biserials[i]
          end
          csv << row
        end
      end
  end

end
