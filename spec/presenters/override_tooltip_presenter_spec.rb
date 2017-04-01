require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OverrideTooltipPresenter do
  describe '#selector' do
    it 'returns a unique selector for the assignment' do
      assignment = Assignment.new
      assignment.context = course_factory
      assignment.save

      presenter = OverrideTooltipPresenter.new(assignment)

      expect(presenter.selector).to eq "assignment_#{assignment.id}"
    end

    it 'returns a unique selector for the quiz' do
      quiz = Quizzes::Quiz.new(title: 'some quiz')
      quiz.context = course_factory
      quiz.save

      presenter = OverrideTooltipPresenter.new(quiz)

      expect(presenter.selector).to eq "quiz_#{quiz.id}"
    end
  end
end
