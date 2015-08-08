require 'active_support'
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizRegrader::Answer do

  let(:points) { 15 }

  let(:question) do
    stub(:id => 1, :question_data => {:id => 1,
                                      :regrade_option => 'full_credit',
                                      :points_possible => points},
                   :quiz_group => nil)
  end

  let(:question_regrade) do
    stub(:quiz_question  => question,
         :regrade_option => "full_credit")
  end

  let(:answer) do
    { :question_id => 1, :points => points, :text => ""}
  end

  let(:wrapper) do
    Quizzes::QuizRegrader::Answer.new(answer, question_regrade)
  end

  def mark_original_answer_as!(correct)
    answer[:correct] = case correct
      when :correct then true
      when :wrong   then false
      when :partial then "partial"
    end

    answer[:points] = case correct
      when :correct then 15
      when :wrong   then 0
      when :partial then 5
    end
  end

  def assert_answer_has_regrade_option!(regrade_option)
    expect(answer[:regrade_option]).to eq regrade_option
  end

  def score_question_as!(correct)
    correct = case correct
      when :correct then true
      when :wrong   then false
      when :partial then "partial"
    end

    points = case correct
      when true      then 15
      when false     then 0
      when "partial" then 10
    end

    sent_params = {}
    Quizzes::SubmissionGrader.expects(:score_question).with do |*args|
      sent_params, sent_answer_data = args
      if question.question_data[:question_type] == 'multiple_answers_question'
        answer.each do |k,v|
          next unless /answer/ =~ k
          key = "question_#{question.id}_#{k}"
          expect(sent_answer_data[key]).to eq v
        end
      else
        expect(sent_answer_data).to eq answer.merge("question_#{question.id}" => answer[:text])
      end
    end.returns(sent_params.merge(:points => points, :correct => correct)).at_least_once
  end

  describe "#initialize" do

    it 'saves a reference to the passed answer hash' do
      expect(wrapper.answer).to eq answer
    end

    it 'saves a reference to the passed question hash' do
      expect(wrapper.question).to eq question
    end

    it 'raises an error if the question has an unrecognized regrade_option' do
      question_regrade = stub(:quiz_question  => question,
                              :regrade_option => "be_a_jerk")

      expect { Quizzes::QuizRegrader::Answer.new(answer, question_regrade) }.to raise_error
    end

    it 'does not raise an error if question has recognized regrade_option' do
      question_regrade = stub(:quiz_question  => question,
                              :regrade_option => "current_correct_only")

      Quizzes::QuizRegrader::Answer::REGRADE_OPTIONS.each do |regrade_option|
        expect { Quizzes::QuizRegrader::Answer.new(answer, question_regrade) }.to_not raise_error
      end
    end
  end

  describe '#regrade!' do

    context 'full_credit regrade option' do

      it 'returns the points possible for the question if the answer was not correct before' do
        mark_original_answer_as!(:wrong)
        score_question_as!(:correct)
        answer[:points] = 0
        expect(wrapper.regrade!).to eq points
        assert_answer_has_regrade_option!('full_credit')
      end

      it 'returns 0 if answer was previously correct' do
        mark_original_answer_as!(:correct)
        score_question_as!(:wrong)
        expect(wrapper.regrade!).to eq 0
        assert_answer_has_regrade_option!('full_credit')
      end
    end

    context 'current_and_previous_correct regrade option' do

      before { wrapper.regrade_option = 'current_and_previous_correct' }

      it 'returns 0 if previously correct' do
        mark_original_answer_as!(:correct)
        score_question_as!(:wrong)
        expect(wrapper.regrade!).to eq 0
        assert_answer_has_regrade_option!('current_and_previous_correct')
      end

      it 'returns points possible if previously wrong but now correct' do
        mark_original_answer_as!(:wrong)
        score_question_as!(:correct)

        expect(wrapper.regrade!).to eq points
        assert_answer_has_regrade_option!('current_and_previous_correct')
      end

      it 'returns points possible - previous score if previously partial correct' do
        mark_original_answer_as!(:partial)
        previous_score = answer[:points]
        score_question_as!(:correct)
        expect(wrapper.regrade!).to eq points - previous_score
        assert_answer_has_regrade_option!('current_and_previous_correct')
      end

      it 'returns 0 if previously wrong and wrong now' do
        mark_original_answer_as!(:wrong)
        score_question_as!(:wrong)
        expect(wrapper.regrade!).to eq 0
        assert_answer_has_regrade_option!('current_and_previous_correct')
      end
    end

    context 'current_correct_only regrade option' do

      before { wrapper.regrade_option = 'current_correct_only' }

      it 'returns points_possible - points if previously wrong but now correct' do
        mark_original_answer_as!(:wrong)
        score_question_as!(:correct)
        expect(wrapper.regrade!).to eq points
        assert_answer_has_regrade_option!('current_correct_only')
      end

      it 'returns 0 if previously correct and correct after regrading' do
        mark_original_answer_as!(:correct)
        score_question_as!(:correct)
        expect(wrapper.regrade!).to eq 0
        assert_answer_has_regrade_option!('current_correct_only')
      end

      it 'returns difference if previously partial and partial after regrading' do
        mark_original_answer_as!(:partial)
        score_question_as!(:partial)
        expect(wrapper.regrade!).to eq 5
        assert_answer_has_regrade_option!('current_correct_only')
      end

      it 'returns -points if prev correct but wrong after regrading' do
        mark_original_answer_as!(:correct)
        score_question_as!(:wrong)
        expect(wrapper.regrade!).to eq -points
        assert_answer_has_regrade_option!('current_correct_only')
      end

      it 'works with multiple_answer_questions' do
        question.question_data.merge!(:question_type => 'multiple_answers_question')
        answer.merge!(:answer_1 => "0", :answer_2 => "1")
        mark_original_answer_as!(:correct)
        score_question_as!(:correct)
        expect(wrapper.regrade!).to eq 0
        assert_answer_has_regrade_option!('current_correct_only')
      end
    end

    context 'no_regrade option' do
      before { wrapper.regrade_option = 'no_regrade' }

      it 'returns 0 when regrading' do
        mark_original_answer_as!(:correct)
        expect(wrapper.regrade!).to eq 0
      end
    end

    context 'disabled option' do
      before { wrapper.regrade_option = 'disabled' }

      it 'returns 0 when regrading' do
        mark_original_answer_as!(:correct)
        expect(wrapper.regrade!).to eq 0
      end
    end
  end

end
