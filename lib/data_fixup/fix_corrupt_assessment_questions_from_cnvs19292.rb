DataFixup::FixCorruptAssessmentQuestionsFromCnvs19292 = Struct.new(:bug_start_date, :bug_end_date) do
  LOG_PREFIX = "FIX_19292_CORRUPTION - "

  def self.run(bug_start_date = false, bug_end_date = false, noop = false)
    if noop
      # Dangerous, but noop should only be executed in isolation.
      connection = ActiveRecord::Base.connection
      def connection.exec_no_cache(sql, *args)
        if sql =~ /INSERT|UPDATE/
          warn '#NOOP'
          return Struct.new(:cmd_tuples, :fields, :nfields, :values, :clear).new(0, [], [], [], true)
        else
          super(sql, *args)
        end
      end

      def connection.exec_cache(sql, *args)
        if sql =~ /INSERT|UPDATE/
          warn '#NOOP'
          return Struct.new(:fields, :nfields, :clear).new([], 0, true)
        else
          super(sql, *args)
        end
      end
    end

    runner = self.new(bug_start_date, bug_end_date)

    result = runner.fix_assessment_questions

    if noop
      # Just in case we weren't in isolation
      def connection.exec_no_cache(*args)
        super(*args)
      end

      def connection.exec_cache(*args)
        super(*args)
      end
    end

    return result
  end

  # SQL
  #   SELECT
  #     "assessment_questions".*
  #   FROM
  #     "assessment_questions"
  #   INNER JOIN
  #     "assessment_question_banks"
  #   ON
  #     "assessment_question_banks"."id" = "assessment_questions"."assessment_question_bank_id"
  #   INNER JOIN
  #     "quiz_groups"
  #   ON
  #     "quiz_groups"."assessment_question_bank_id" = "assessment_question_banks"."id"
  #   INNER JOIN
  #     "quizzes"
  #   ON
  #     "quizzes"."id" = "quiz_groups"."quiz_id"
  #   WHERE (
  #     "quizzes"."updated_at" BETWEEN '2015-03-14 00:00:00.000000' AND '2015-03-18 23:59:59.999999'
  #   ) AND (
  #     assessment_questions.updated_at < '2015-03-18 23:59:59.999999'
  #   ) AND (
  #     assessment_questions.question_data LIKE '%calculated_question%' or
  #     assessment_questions.question_data LIKE '%numerical_question%' or
  #     assessment_questions.question_data LIKE '%matching_question%'
  #   );
  #
  # Explain
  #   Nested Loop  (cost=10.95..368.36 rows=1 width=1604)
  #     ->  Nested Loop  (cost=10.95..79.50 rows=5 width=16)
  #           ->  Hash Join  (cost=10.95..72.84 rows=15 width=8)
  #                 Hash Cond: (quizzes.id = quiz_groups.quiz_id)
  #                 ->  Seq Scan on quizzes  (cost=0.00..60.52 rows=35 width=8)
  #                       Filter: ((updated_at >= '2015-03-14 00:00:00'::timestamp without time zone) AND (updated_at <= '2015-03-18 23:59:59.999999'::timestamp without time zone))
  #                 ->  Hash  (cost=8.20..8.20 rows=220 width=16)
  #                       ->  Seq Scan on quiz_groups  (cost=0.00..8.20 rows=220 width=16)
  #           ->  Index Scan using assessment_question_banks_pkey on assessment_question_banks  (cost=0.00..0.43 rows=1 width=8)
  #                 Index Cond: (id = quiz_groups.assessment_question_bank_id)
  #     ->  Index Scan using question_bank_id_and_position on assessment_questions  (cost=0.00..57.76 rows=1 width=1604)
  #           Index Cond: (assessment_question_bank_id = assessment_question_banks.id)
  #           Filter: ((updated_at < '2015-03-18 23:59:59.999999'::timestamp without time zone) AND ((question_data ~~ '%calculated_question%'::text) OR (question_data ~~ '%numerical_question%'::text) OR (question_data ~~ '%matching_question%'::text)))

  # Update each AssessmentQuestion to increment version_number, this will
  # cause associated QuizQuestions to update on next Quiz take
  def fix_assessment_questions
    query = AssessmentQuestion
            .joins(:assessment_question_bank => {:quiz_groups => :quiz})
            .where("
               assessment_questions.question_data LIKE '%calculated_question%' or
               assessment_questions.question_data LIKE '%numerical_question%' or
               assessment_questions.question_data LIKE '%matching_question%'
            ")

    if bug_start_date && bug_end_date
      query = query
              .where(quizzes: {updated_at: bug_start_date..bug_end_date})
              .where('assessment_questions.updated_at < ?', bug_end_date)
    end

    env = Shackles.environment == :master ? :slave : Shackles.environment
    Shackles.activate(env) do
      query.readonly(false).find_each do |aq|
        Shackles.activate(:master) do
          Rails.logger.info "#{LOG_PREFIX} incrementing version for assessment question #{aq.global_id} from #{aq.version_number}"
          aq.with_versioning(true, &:save!)
        end
      end
    end

    return true
  end
end
