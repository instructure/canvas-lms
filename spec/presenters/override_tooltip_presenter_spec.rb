require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OverrideTooltipPresenter do
  describe '#selector' do
    it 'returns a unique selector for the assignment' do
      assignment = Assignment.new
      assignment.context = course
      assignment.save

      presenter = OverrideTooltipPresenter.new(assignment)

      presenter.selector.should == "assignment_#{assignment.id}"
    end

    it 'returns a unique selector for the assignment' do
      quiz = Quizzes::Quiz.new(title: 'some quiz')
      quiz.context = course
      quiz.save

      presenter = OverrideTooltipPresenter.new(quiz)

      presenter.selector.should == "quiz_#{quiz.id}"
    end
  end
end
