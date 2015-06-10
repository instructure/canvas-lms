require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

context "accessing public content" do
  before :each do
    course(:active_all => true)
    @course.update_attribute(:is_public, true)
    @course.update_attribute(:is_public_to_auth_users, true)
  end

  def test_public_access
    enable_cache do
      Timecop.freeze(10.seconds.ago) do
        yield
        expect(response).to be_success
      end

      Timecop.freeze(8.seconds.ago) do
        @course.update_attribute(:is_public, false)
        @course.touch_content_if_public_visibility_changed(:is_public => [true, false])

        yield
        assert_unauthorized
      end

      user
      user_session(@user)

      Timecop.freeze(5.seconds.ago) do
        yield
        expect(response).to be_success
      end

      @course.update_attribute(:is_public_to_auth_users, false)
      @course.touch_content_if_public_visibility_changed(:is_public_to_auth_users => [true, false])

      yield
      assert_unauthorized
    end
  end

  it "should show assignments" do
    assignment = @course.assignments.create!(:name => "blah")

    test_public_access do
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
    end
  end

  it "should show quizzes" do
    quiz = @course.quizzes.create!(:name => "blah")
    quiz.publish!

    test_public_access do
      get "/courses/#{@course.id}/quizzes/#{quiz.id}"
    end
  end

  it "should show wiki pages" do
    page = @course.wiki.wiki_pages.create!(:title => "stuff")

    test_public_access do
      get "/courses/#{@course.id}/pages/#{page.url}"
    end
  end
end