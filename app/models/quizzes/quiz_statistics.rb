#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Quizzes::QuizStatistics < ActiveRecord::Base
  self.table_name = :quiz_statistics

  attr_accessible :includes_all_versions, :anonymous, :report_type

  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  has_one :csv_attachment, :class_name => 'Attachment', :as => 'context',
    :dependent => :destroy
  has_one :progress, :as => 'context', :dependent => :destroy

  scope :report_type, lambda { |type| where(:report_type => type) }

  REPORTS = %w[student_analysis item_analysis].freeze

  validates_inclusion_of :report_type, :in => REPORTS

  def report
    @report ||= begin
                  report_class = case report_type.to_s
                                 when 'item_analysis' then
                                   Quizzes::QuizStatistics::ItemAnalysis
                                 when 'student_analysis' then
                                   Quizzes::QuizStatistics::StudentAnalysis
                                 end
                  report_class.new(self)
                end
  end

  def generate_csv
    display_name = t('#quizzes.quiz_statistics.statistics_filename', "%{quiz_title} %{quiz_type} %{report_type} Report",
                     :quiz_title => quiz.title,
                     :quiz_type => quiz.readable_type,
                     :report_type => readable_type
                    ) + ".csv"
                    build_csv_attachment(:filename => "quiz_#{report_type}_report.csv",
                                         :display_name => display_name,
                                         :uploaded_data => StringIO.new(report.to_csv)
                                        ).tap { |a|
                                          a.content_type = 'text/csv'
                                          a.save!
                                          complete_progress
                                        }
  end

  def generate_csv_in_background
    return if csv_attachment
    start_progress
    strand_id = Shard.birth.activate { quiz_id }
    send_later_enqueue_args :generate_csv, :strand => "quiz_statistics_#{strand_id}"
  end

  def start_progress
    return if progress
    build_progress(:tag => self.class.name, :completion => 0)
    progress.start
  end

  def update_progress(i, n)
    # TODO: smarter updates?  maybe 10 updates isn't enough for quizzes with
    # hundreds of submissions
    increment = 10
    percent = (i.to_f / n * 100).round

    if (percent / increment) > (progress.completion / increment)
      progress.update_completion! percent
    end
  end

  def complete_progress
    progress.complete
    progress.save!
  end

  def readable_type
    case report_type
    when 'item_analysis' then
      t('#quizzes.quiz_statistics.types.item_analysis', 'Item Analysis')
    when 'student_analysis' then
      t('#quizzes.quiz_statistics.types.student_analysis', 'Student Analysis')
    end
  end

  set_policy do
    given { |user, session| quiz.grants_right?(user, session, :read_statistics) }
    can :read
  end

  class Quizzes::QuizStatistics::Report
    extend Forwardable

    def_delegators :quiz_statistics, :quiz, :includes_all_versions?, :anonymous?, :start_progress, :update_progress

    attr_reader :quiz_statistics

    def initialize(quiz_statistics)
      @quiz_statistics = quiz_statistics
    end

  end

end
