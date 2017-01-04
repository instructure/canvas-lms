require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizQuestionBuilder do
  describe '#build_submission_questions' do
    before :once do
      course_with_student
    end

    before do
      # question artifacts from specs will stick around since we use
      # before(:once) to define the @quiz, so.. to spare ourselves weirdness:
      Quizzes::QuizQuestion.generated.destroy_all
    end

    let :questions do
      @quiz.reload
      @quiz.generate_quiz_data

      subject.build_submission_questions(@quiz.id, @quiz.stored_questions)
    end

    it 'should use a local question' do
      questions = subject.build_submission_questions(1, [
        {
          id: 1,
          name: 'some question',
          question_type: 'essay_question'
        }
      ])

      expect(questions.count).to eq(1)
      expect(questions[0][:id]).to eq(1)
    end

    context 'with a question bank entry' do
      before(:once) do
        @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
        @quiz = @course.quizzes.create!
      end

      it 'should pull questions from a bank' do
        aqs = [
          assessment_question_model(bank: @bank, name: 'Group Question 1'),
          assessment_question_model(bank: @bank, name: 'Group Question 2'),
          assessment_question_model(bank: @bank, name: 'Group Question 3')
        ]

        @group = @quiz.quiz_groups.create!({
          name: "question group a",
          pick_count: 2,
          question_points: 5.0,
          assessment_question_bank_id: @bank.id
        })

        # it should pick 2 questions from that bank
        expect(questions.count).to eq(2)

        # verify the correct questions were pulled:
        source_aq_ids = aqs.map(&:id)
        pulled_aq_ids = questions.map { |q| q[:assessment_question_id] }
        expect((pulled_aq_ids | source_aq_ids).sort).to eq(source_aq_ids.sort)

        # it generates quiz questions for every AQ it pulls out of the bank:
        expect(@quiz.quiz_questions.count).to eq(2)
        expect(@quiz.quiz_questions.generated.count).to eq(2)
        expect(@quiz.quiz_questions.pluck(:id).sort).
          to eq(questions.map { |q| q[:id] }.sort)
      end

      it 'should duplicate questions to fill the group' do
        aq = assessment_question_model(bank: @bank, name: 'Group Question 1')

        @group = @quiz.quiz_groups.create!({
                                               name: "question group a",
                                               pick_count: 5,
                                               question_points: 5.0,
                                               assessment_question_bank_id: @bank.id
                                           })

        # it should pick 2 questions from that bank
        expect(questions.count).to eq(5)

        # verify the correct questions were pulled:
        expect(questions.map { |q| q[:assessment_question_id] }).to eq [aq.id] * 5

        # it generates quiz questions for every AQ it pulls out of the bank:
        expect(@quiz.quiz_questions.count).to eq(5)
        expect(@quiz.quiz_questions.generated.count).to eq(5)
        expect(@quiz.quiz_questions.pluck(:id).sort).
            to eq(questions.map { |q| q[:id] }.sort)
      end

      it "should duplicate questions from a bank" do
        assessment_question_model(bank: @bank)

        # both groups pull from the same bank
        @quiz.quiz_groups.create!({
          name: "question group a",
          pick_count: 1,
          question_points: 5.0,
          assessment_question_bank_id: @bank.id
        })

        @quiz.quiz_groups.create!({
          name: "question group b",
          pick_count: 1,
          question_points: 5.0,
          assessment_question_bank_id: @bank.id
        })

        expect(questions.count).to eq 2
        expect(questions[0][:id]).not_to eq(questions[1][:id]),
          "a duplicated question is still created as a separate QuizQuestion entity"
      end
    end

    context 'with a quiz group' do
      before(:once) do
        @quiz = @course.quizzes.create!
        @group = @quiz.quiz_groups.create!({
          name: 'Quiz Group 1',
          pick_count: 1,
          question_points: 2.5
        })
      end

      it 'should use a question defined locally in a group' do
        @qq = @quiz.quiz_questions.create!({
          quiz_group_id: @group.id,
          question_data: {
            question_type: 'essay_question',
            question_text: 'qq1'
          }
        })

        expect(questions.count).to eq(1)
        expect(questions[0][:id]).to eq(@qq.id)
      end

      context 'linked to a question bank' do
        before(:once) do
          @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')

          @group.update_attribute(:assessment_question_bank_id, @bank.id)
        end

        it 'should pull questions from the bank a group is linked to' do
          aqs = [
            assessment_question_model(bank: @bank),
            assessment_question_model(bank: @bank),
          ]

          expect(questions.count).to eq(1)
          expect(aqs.map(&:id)).to include(questions[0][:assessment_question_id])

          quiz_questions = @quiz.quiz_questions.generated.to_a
          expect(quiz_questions.count).to eq(1)
          expect(quiz_questions.first.id).to eq questions[0][:id]
        end

        context 'when the pick count is higher than the available questions' do
          it 'should duplicate as many questions as needed' do
            aqs = [
              @bank.assessment_questions.create!({
                question_data: {
                  question_text: 'bq1',
                  question_type: 'essay_question'
                }
              }),

              @bank.assessment_questions.create!({
                question_data: {
                  question_text: 'bq2',
                  question_type: 'essay_question'
                }
              })
            ]

            @group.update_attribute(:pick_count, 3)

            expect(questions.count).to eq(3)
            expect(questions.map { |q| q[:question_text] }.sort.uniq).to eq([
              'bq1', 'bq2'
            ])

            expect(questions.map { |q| q[:id] }.uniq.count).to eq(3),
              "it links to 3 distinct QuizQuestion objects"

            expect(@quiz.quiz_questions.generated.count).to eq(3)
          end
        end
      end
    end

    context 'with both banks and groups' do
      it 'previously picked questions should still show up' do
        @quiz = @course.quizzes.create!
        @bank = @course.assessment_question_banks.create!
        subject.options[:shuffle_questions] = false

        aq1 = @bank.assessment_questions.create!({
          question_data: {
            question_text: 'bank question 1',
            question_type: 'essay_question'
          }
        })

        aq2 = @bank.assessment_questions.create!({
          question_data: {
            question_text: 'bank question 2',
            question_type: 'essay_question'
          }
        })

        group1 = @quiz.quiz_groups.create!({
          name: "linked group",
          pick_count: 2,
          question_points: 1,
          assessment_question_bank_id: @bank.id
        })

        group2 = @quiz.quiz_groups.create!({
          name: "standalone group",
          pick_count: 2,
          question_points: 1
        })

        @quiz.add_assessment_questions([ aq1 ], group2)
        @quiz.quiz_questions.create!({
          quiz_group: group2,
          question_data: {
            question_type: 'essay_question',
            question_text: 'group question'
          }
        })

        expect(questions.count).to eq(4)
        expect(@quiz.quiz_questions.generated.count).to eq(2)
        expect([
          [ 'bank question 1', 'bank question 1', 'bank question 2', 'group question' ],
          [ 'bank question 1', 'bank question 2', 'group question', 'group question' ],
        ]).to include(questions.map { |q| q[:question_text] }.sort)
      end
    end
  end

  describe '#shuffle_answers' do
    let(:question) { { :answers => answers } }
    let(:answers) { ['a', 'b', 'c'] }

    context "on a shuffle answers question" do
      before { subject.options[:shuffle_answers] = true }

      context "on a non-shuffleable question type" do
        before { subject.stubs(:shuffleable_question_type?).returns(false) }

        it "doesn't shuffle" do
          expect(subject.shuffle_answers(question)).to eq answers
        end
      end

      context "on a shuffleable question type" do
        before { subject.stubs(:shuffleable_question_type?).returns(true) }

        it "returns the same answers, not necessarily in the same order" do
          expect(subject.shuffle_answers(question).sort).to eq answers.sort
        end

        it "shuffles" do
          answers.expects(:sort_by)
          subject.shuffle_answers(question)
        end
      end
    end

    context "on a non-shuffle answers question" do
      it "doesn't shuffle" do
        expect(subject.shuffle_answers(question)).to eq answers
      end
    end
  end

  describe '#shuffle_matches' do
    let(:question) { { :matches => matches } }
    let(:matches) { ['a', 'b', 'c'] }

    it "shuffles matches for a matching question" do
      subject.options[:shuffle_answers] = true
      matches.expects(:sort_by)
      subject.shuffle_matches(question)
    end

    it "still shuffles even if shuffle_answers option is off" do
      subject.options[:shuffle_answers] = false
      matches.expects(:sort_by)
      subject.shuffle_matches(question)
    end
  end
end
