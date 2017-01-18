DataFixup::FixCorruptAssessmentQuestionsFromCnvs19292 = Struct.new(:question_types, :bug_start_date, :bug_end_date) do
  LOG_PREFIX = "FIX_19292_CORRUPTION - "

  def self.run(question_types, bug_start_date = false, bug_end_date = false, noop = false)
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

    runner = self.new(question_types, bug_start_date, bug_end_date)

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


  # From beta-slave cluster1:canvas
  #
  # SELECT "assessment_questions".*
  # FROM "assessment_questions"
  # INNER JOIN "assessment_question_banks"
  #   ON "assessment_question_banks"."id" = "assessment_questions"."assessment_question_bank_id"
  # INNER JOIN "quiz_groups"
  #   ON "quiz_groups"."assessment_question_bank_id" = "assessment_question_banks"."id"
  # INNER JOIN "quizzes"
  #   ON "quizzes"."id" = "quiz_groups"."quiz_id"
  # INNER JOIN quiz_questions
  #   ON quiz_questions.assessment_question_id = assessment_questions.id
  #   AND quiz_questions.quiz_id = quizzes.id
  # WHERE (
  #   quiz_questions.updated_at > assessment_questions.updated_at
  # ) AND (
  #   assessment_questions.question_data LIKE '%calculated_question%'
  #   or assessment_questions.question_data LIKE '%numerical_question%'
  #   or assessment_questions.question_data LIKE '%matching_question%'
  #   or assessment_questions.question_data LIKE '%multiple_dropdowns_question%'
  # ) AND (
  #   "quiz_questions"."updated_at" BETWEEN '2015-03-14 00:00:00.000000' AND '2015-03-18 23:59:59.999999'
  # ) /*hostname:perfjob01-vpc.us-east-1.test.insops.net,pid:25167*/  [shard 1 slave]
  #
  # Nested Loop  (cost=407129.00..5724084.55 rows=1 width=1208)
  #   Join Filter: ((quiz_questions.updated_at > assessment_questions.updated_at) AND (assessment_question_banks.id = assessment_questions.assessment_question_bank_id))
  #   ->  Hash Join  (cost=407129.00..4856412.29 rows=61094 width=32)
  #         Hash Cond: (quizzes.id = quiz_groups.quiz_id)
  #         ->  Hash Join  (cost=199980.18..4617145.44 rows=166925 width=32)
  #               Hash Cond: (quiz_questions.quiz_id = quizzes.id)
  #               ->  Seq Scan on quiz_questions  (cost=0.00..4405912.76 rows=166925 width=24)
  #                     Filter: ((updated_at >= '2015-03-14 00:00:00'::timestamp without time zone) AND (updated_at <= '2015-03-18 23:59:59.999999'::timestamp without time zone))
  #               ->  Hash  (cost=174965.19..174965.19 rows=1524719 width=8)
  #                     ->  Seq Scan on quizzes  (cost=0.00..174965.19 rows=1524719 width=8)
  #         ->  Hash  (cost=200173.28..200173.28 rows=558043 width=24)
  #               ->  Hash Join  (cost=122692.85..200173.28 rows=558043 width=24)
  #                     Hash Cond: (quiz_groups.assessment_question_bank_id = assessment_question_banks.id)
  #                     ->  Seq Scan on quiz_groups  (cost=0.00..36016.07 rows=1348907 width=16)
  #                     ->  Hash  (cost=76883.71..76883.71 rows=2792171 width=8)
  #                           ->  Seq Scan on assessment_question_banks  (cost=0.00..76883.71 rows=2792171 width=8)
  #   ->  Index Scan using assessment_questions_pkey on assessment_questions  (cost=0.00..14.18 rows=1 width=1208)
  #         Index Cond: (id = quiz_questions.assessment_question_id)
  #         Filter: ((question_data ~~ '%calculated_question%'::text) OR (question_data ~~ '%numerical_question%'::text) OR (question_data ~~ '%matching_question%'::text) OR (question_data ~~ '%multiple_dropdowns_question%'::text))
  #
  # SELECT COUNT(*) gives 1616 records in 306503.2ms
  #
  # Update each AssessmentQuestion to increment version_number, this will
  # cause associated QuizQuestions to update on next Quiz take
  def fix_assessment_questions
    return false unless question_types.present?

    question_type_queries = question_types.map do |qt|
      "assessment_questions.question_data LIKE '%#{qt}%'"
    end.join(" or ")

    query = AssessmentQuestion
            .joins(:assessment_question_bank => {:quiz_groups => :quiz})
            .joins("INNER JOIN #{Quizzes::QuizQuestion.quoted_table_name}
                      ON quiz_questions.assessment_question_id = assessment_questions.id
                      AND quiz_questions.quiz_id = quizzes.id
                  ")
            .where("quiz_questions.updated_at > assessment_questions.updated_at")
            .where(question_type_queries)

    if bug_start_date && bug_end_date
      query = query
              .where(quiz_questions: {updated_at: bug_start_date..bug_end_date})
    end

    Shackles.activate(:slave) do
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
