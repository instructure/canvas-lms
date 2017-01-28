require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "quizzes" do
  include_context "in-process server selenium tests"

  context "as an admin" do
    it "should show unpublished quizzes to admins without management rights" do
      course_factory(active_all: true)
      quiz = @course.quizzes.create!(:title => "quizz")
      quiz.unpublish!

      role = custom_account_role("other admin", :account => Account.default)
      account_admin_user_with_role_changes(:role => role, :role_changes => {:read_course_content => true} )

      user_with_pseudonym(:user => @admin)
      user_session(@admin)

      get "/courses/#{@course.id}/quizzes"

      expect(f(".quiz")).to include_text(quiz.title)
    end
  end
end
