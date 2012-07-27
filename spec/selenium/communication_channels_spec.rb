require File.expand_path(File.dirname(__FILE__) + '/common')

describe "communication channel selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  context "confirm" do
    it "should register the user" do
      u1 = user_with_communication_channel(:user_state => 'creation_pending')
      get "/register/#{u1.communication_channel.confirmation_code}"
      set_value f('#pseudonym_password'), "asdfasdf"
      expect_new_page_load {
        f('#registration_confirmation_form').submit
      }
      f('#identity .logout').should be_present
    end

    it "should allow the user to edit the pseudonym if it's already taken" do
      u1 = user_with_communication_channel(:username => 'asdf@qwerty.com', :user_state => 'creation_pending')
      # d'oh, now it's taken
      u2 = user_with_pseudonym(:username => 'asdf@qwerty.com', :active_user => true)

      get "/register/#{u1.communication_channel.confirmation_code}"
      # they can set it...
      input = f('#pseudonym_unique_id')
      input.should be_present
      set_value input, "asdf@asdf.com"
      set_value f('#pseudonym_password'), "asdfasdf"
      expect_new_page_load {
        f('#registration_confirmation_form').submit
      }

      f('#identity .logout').should be_present
    end
  end
end
