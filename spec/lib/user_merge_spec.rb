
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe UserMerge do
  describe 'with simple users' do
    let!(:user1) { user_model }
    let!(:user2) { user_model }
    let(:course1) { course(:active_all => true) }
    let(:course2) { course(:active_all => true) }

    it 'should delete the old user' do
      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload
      expect(user1).not_to be_deleted
      expect(user2).to be_deleted
    end

    it "should move pseudonyms to the new user" do
      user2.pseudonyms.create!(:unique_id => 'sam@yahoo.com')
      UserMerge.from(user2).into(user1)
      user2.reload
      expect(user2.pseudonyms).to be_empty
      user1.reload
      expect(user1.pseudonyms.map(&:unique_id)).to be_include('sam@yahoo.com')
    end

    it "should use avatar information from merged user if none exists" do
      user2.avatar_image = {'type' => 'external', 'url' => 'https://example.com/image.png'}
      user2.save!

      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload

      [:avatar_image_source, :avatar_image_url, :avatar_image_updated_at, :avatar_state].each do |attr|
        expect(user1[attr]).to eq user2[attr]
      end
    end

    it "should not overwrite avatar information already in place" do
      user1.avatar_state = 'locked'
      user1.save!
      user2.avatar_image = {'type' => 'external', 'url' => 'https://example.com/image.png'}
      user2.save!

      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload
      expect(user1.avatar_state).not_to eq user2.avatar_state
    end

    it "should move access tokens to the new user" do
      at = AccessToken.create!(:user => user2, :developer_key => DeveloperKey.default)
      UserMerge.from(user2).into(user1)
      at.reload
      expect(at.user_id).to eq user1.id
    end

    it "should move submissions to the new user (but only if they don't already exist)" do
      a1 = assignment_model
      s1 = a1.find_or_create_submission(user1)
      s1.submission_type = "online_quiz"
      s1.save!
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!
      a2 = assignment_model
      s3 = a2.find_or_create_submission(user2)
      s3.submission_type = "online_quiz"
      s3.save!
      expect(user2.submissions.length).to eql(2)
      expect(user1.submissions.length).to eql(1)
      UserMerge.from(user2).into(user1)
      user2.reload
      user1.reload
      expect(user2.submissions.length).to eql(1)
      expect(user2.submissions.first.id).to eql(s2.id)
      expect(user1.submissions.length).to eql(2)
      expect(user1.submissions.map(&:id)).to be_include(s1.id)
      expect(user1.submissions.map(&:id)).to be_include(s3.id)
    end

    it "should overwrite submission objects that do not contain actual student submissions (e.g. what_if grades)" do
      a1 = assignment_model
      s1 = a1.find_or_create_submission(user1)
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!

      UserMerge.from(user2).into(user1)

      expect(user1.reload.submissions).to eq [s2.reload]
      expect(user2.reload.submissions).to eq []

      user1.destroy
      user2.destroy

      user1 = user_model
      user2 = user_model
      a2 = assignment_model
      s3 = a2.find_or_create_submission(user1)
      s3.submission_type = "online_quiz"
      s3.save!
      s4 = a2.find_or_create_submission(user2)

      UserMerge.from(user2).into(user1)

      expect(user1.reload.submissions).to eq [s3.reload]
      expect(user2.reload.submissions).to eq [s4.reload]
    end

    it "should move quiz submissions to the new user (but only if they don't already exist)" do
      q1 = quiz_model
      qs1 = q1.generate_submission(user1)
      qs2 = q1.generate_submission(user2)

      q2 = quiz_model
      qs3 = q2.generate_submission(user2)

      expect(user1.quiz_submissions.length).to eql(1)
      expect(user2.quiz_submissions.length).to eql(2)

      UserMerge.from(user2).into(user1)

      user2.reload
      user1.reload

      expect(user2.quiz_submissions.length).to eql(1)
      expect(user2.quiz_submissions.first.id).to eql(qs2.id)

      expect(user1.quiz_submissions.length).to eql(2)
      expect(user1.quiz_submissions.map(&:id)).to be_include(qs1.id)
      expect(user1.quiz_submissions.map(&:id)).to be_include(qs3.id)
    end

    it "should move ccs to the new user (but only if they don't already exist)" do
      # unconfirmed => active conflict
      user1.communication_channels.create!(:path => 'a@instructure.com')
      user2.communication_channels.create!(:path => 'A@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => unconfirmed conflict
      user1.communication_channels.create!(:path => 'b@instructure.com') { |cc| cc.workflow_state = 'active' }
      user2.communication_channels.create!(:path => 'B@instructure.com')
      # active => active conflict
      user1.communication_channels.create!(:path => 'c@instructure.com') { |cc| cc.workflow_state = 'active' }
      user2.communication_channels.create!(:path => 'C@instructure.com') { |cc| cc.workflow_state = 'active' }
      # unconfirmed => unconfirmed conflict
      user1.communication_channels.create!(:path => 'd@instructure.com')
      user2.communication_channels.create!(:path => 'D@instructure.com')
      # retired => unconfirmed conflict
      user1.communication_channels.create!(:path => 'e@instructure.com') { |cc| cc.workflow_state = 'retired' }
      user2.communication_channels.create!(:path => 'E@instructure.com')
      # unconfirmed => retired conflict
      user1.communication_channels.create!(:path => 'f@instructure.com')
      user2.communication_channels.create!(:path => 'F@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => active conflict
      user1.communication_channels.create!(:path => 'g@instructure.com') { |cc| cc.workflow_state = 'retired' }
      user2.communication_channels.create!(:path => 'G@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => retired conflict
      user1.communication_channels.create!(:path => 'h@instructure.com') { |cc| cc.workflow_state = 'active' }
      user2.communication_channels.create!(:path => 'H@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => retired conflict
      user1.communication_channels.create!(:path => 'i@instructure.com') { |cc| cc.workflow_state = 'retired' }
      user2.communication_channels.create!(:path => 'I@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # <nothing> => active
      user2.communication_channels.create!(:path => 'j@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => <nothing>
      user1.communication_channels.create!(:path => 'k@instructure.com') { |cc| cc.workflow_state = 'active' }
      # <nothing> => unconfirmed
      user2.communication_channels.create!(:path => 'l@instructure.com')
      # unconfirmed => <nothing>
      user1.communication_channels.create!(:path => 'm@instructure.com')
      # <nothing> => retired
      user2.communication_channels.create!(:path => 'n@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => <nothing>
      user1.communication_channels.create!(:path => 'o@instructure.com') { |cc| cc.workflow_state = 'retired' }

      UserMerge.from(user1).into(user2)
      user1.reload
      user2.reload
      expect(user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq [
          ['A@instructure.com', 'active'],
          ['C@instructure.com', 'active'],
          ['D@instructure.com', 'unconfirmed'],
          ['E@instructure.com', 'unconfirmed'],
          ['G@instructure.com', 'active'],
          ['I@instructure.com', 'retired'],
          ['b@instructure.com', 'active'],
          ['f@instructure.com', 'unconfirmed'],
          ['h@instructure.com', 'active'],
          ['j@instructure.com', 'active'],
          ['k@instructure.com', 'active'],
          ['l@instructure.com', 'unconfirmed'],
          ['m@instructure.com', 'unconfirmed'],
          ['n@instructure.com', 'retired'],
          ['o@instructure.com', 'retired']
      ]
      expect(user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq [
          ['a@instructure.com', 'retired'],
          ['c@instructure.com', 'retired'],
          ['d@instructure.com', 'retired'],
          ['e@instructure.com', 'retired'],
          ['g@instructure.com', 'retired'],
          ['i@instructure.com', 'retired'],
      ]
      %w{B@instructure.com F@instructure.com H@instructure.com}.each do |path|
        expect(CommunicationChannel.where(user_id: [user1, user2]).by_path(path).detect { |cc| cc.path == path }).to be_nil
      end
    end

    it "should move and uniquify enrollments" do
      enrollment1 = course1.enroll_user(user1)
      enrollment2 = course1.enroll_student(user2, enrollment_state: 'active')
      section = course1.course_sections.create!
      enrollment3 = course1.enroll_student(user1,
                                           enrollment_state: 'invited',
                                           allow_multiple_enrollments: true,
                                           section: section)
      enrollment4 = course1.enroll_teacher(user1)

      UserMerge.from(user1).into(user2)
      enrollment1.reload
      expect(enrollment1.user).to eq user1
      expect(enrollment1).to be_deleted
      enrollment2.reload
      expect(enrollment2).to be_active
      expect(enrollment2.user).to eq user2
      enrollment3.reload
      expect(enrollment3).to be_invited
      enrollment4.reload
      expect(enrollment4.user).to eq user2
      expect(enrollment4).to be_invited

      user1.reload
      expect(user1.enrollments).to eq [enrollment1]
    end

    it "should remove conflicting module progressions" do
      course1.enroll_user(user1)
      course1.enroll_user(user2, 'StudentEnrollment', enrollment_state:'active')
      assignment = course1.assignments.create!(title:"some assignment")
      assignment2 = course1.assignments.create!(title:"some second assignment")
      context_module = course1.context_modules.create!(name:"some module")
      context_module2 = course1.context_modules.create!(name:"some second module")
      tag = context_module.add_item(id:assignment, type:'assignment')
      tag2 = context_module2.add_item(id:assignment2, type:'assignment')

      context_module.completion_requirements = {tag.id => {type:'must_view'}}
      context_module2.completion_requirements = {tag2.id => {type:'min_score', min_score:5}}
      context_module.save
      context_module2.save

      #have a conflicting module_progrssion
      assignment2.grade_student(user1, :grade => "10")
      assignment2.grade_student(user2, :grade => "4")

      #have a duplicate module_progression
      context_module.update_for(user1, :read, tag)
      context_module.update_for(user2, :read, tag)

      #it should work
      expect { UserMerge.from(user1).into(user2) }.to_not raise_error

      #it should have deleted or moved the module progressions for User1 and kept the completed ones for user2
      expect(ContextModuleProgression.where(user_id:user1, context_module_id:[context_module, context_module2]).count).to eq 0
      expect(ContextModuleProgression.where(user_id:user2, context_module_id:[context_module, context_module2],workflow_state:'completed').count).to eq 2
    end

    it "should remove observer enrollments that observe themselves (target)" do
      enrollment1 = course1.enroll_user(user1, 'StudentEnrollment', enrollment_state: 'active')
      enrollment2 = course1.enroll_user(user2, 'ObserverEnrollment', enrollment_state: 'active', associated_user_id: user1.id)

      UserMerge.from(user1).into(user2)
      expect(enrollment1.reload.user).to eql user2
      expect(enrollment2.reload.workflow_state).to eql 'deleted'
    end

    it "should remove observer enrollments that observe themselves (source)" do
      enrollment1 = course1.enroll_user(user1, 'StudentEnrollment', enrollment_state: 'active')
      enrollment2 = course1.enroll_user(user2, 'ObserverEnrollment', enrollment_state: 'active', associated_user_id: user1.id)

      UserMerge.from(user2).into(user1)
      expect(enrollment1.reload.user).to eql user1
      expect(enrollment2.reload.workflow_state).to eql 'deleted'
    end

    it "should move and uniquify observee enrollments" do
      course2
      course1.enroll_user(user1)
      course1.enroll_user(user2)

      observer1 = user_with_pseudonym
      observer2 = user_with_pseudonym
      user1.observers << observer1 << observer2
      user2.observers << observer2
      expect(ObserverEnrollment.count).to eql 3
      Enrollment.where(user_id: observer2, associated_user_id: user1).update_all(workflow_state: 'completed')

      UserMerge.from(user1).into(user2)
      expect(user1.observee_enrollments.size).to eql 1 #deleted
      expect(user1.observee_enrollments.active_or_pending).to be_empty
      expect(user2.observee_enrollments.size).to eql 2
      expect(user2.observee_enrollments.active_or_pending.size).to eql 2
      expect(observer1.observer_enrollments.active_or_pending.size).to eql 1
      expect(observer2.observer_enrollments.active_or_pending.size).to eql 1
    end

    it "should move and uniquify observers" do
      observer1 = user_model
      observer2 = user_model
      user1.observers << observer1 << observer2
      user2.observers << observer2

      UserMerge.from(user1).into(user2)
      user1.reload
      expect(user1.observers).to be_empty
      user2.reload
      expect(user2.observers.sort_by(&:id)).to eql [observer1, observer2]
    end

    it "should move and uniquify observed users" do
      student1 = user_model
      student2 = user_model
      user1.observed_users << student1 << student2
      user2.observed_users << student2

      UserMerge.from(user1).into(user2)
      user1.reload
      expect(user1.observed_users).to be_empty
      user2.reload
      expect(user2.observed_users.sort_by(&:id)).to eql [student1, student2]
    end

    it "should move conversations to the new user" do
      c1 = user1.initiate_conversation([user, user]) # group conversation
      c1.add_message("hello")
      c1.update_attribute(:workflow_state, 'unread')
      c2 = user1.initiate_conversation([user]) # private conversation
      c2.add_message("hello")
      c2.update_attribute(:workflow_state, 'unread')
      old_private_hash = c2.conversation.private_hash

      UserMerge.from(user1).into(user2)
      expect(c1.reload.user_id).to eql user2.id
      expect(c1.conversation.participants).not_to include(user1)
      expect(user1.reload.unread_conversations_count).to eql 0

      expect(c2.reload.user_id).to eql user2.id
      expect(c2.conversation.participants).not_to include(user1)
      expect(c2.conversation.private_hash).not_to eql old_private_hash
      expect(user2.reload.unread_conversations_count).to eql 2
    end

    it "should point other user's observers to the new user" do
      observer = user_model
      course1.enroll_student(user1)
      oe = course1.enroll_user(observer, 'ObserverEnrollment')
      oe.update_attribute(:associated_user_id, user1.id)
      UserMerge.from(user1).into(user2)
      expect(oe.reload.associated_user_id).to eq user2.id
    end

    it "should move appointments" do
      enrollment1 = course1.enroll_user(user1, 'StudentEnrollment', :enrollment_state => 'active')
      enrollment2 = course1.enroll_user(user2, 'StudentEnrollment', :enrollment_state => 'active')
      ag = AppointmentGroup.create(:title => "test",
       :contexts => [course1],
       :participants_per_appointment => 1,
       :min_appointments_per_participant => 1,
       :new_appointments => [
         ["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"],
         ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]
       ]
      )
      res1 = ag.appointments.first.reserve_for(user1, @teacher)
      res2 = ag.appointments.last.reserve_for(user2, @teacher)
      UserMerge.from(user1).into(user2)
      res1.reload
      expect(res1.context_id).to eq user2.id
      expect(res1.context_code).to eq user2.asset_string
    end

    it "should move user attachments and handle duplicates" do
      attachment1 = Attachment.create!(:user => user1, :context => user1, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
      attachment2 = Attachment.create!(:user => user1, :context => user1, :filename => "test.txt", :uploaded_data => StringIO.new("notfirst"))
      attachment3 = Attachment.create!(:user => user2, :context => user2, :filename => "test.txt", :uploaded_data => StringIO.new("first"))

      UserMerge.from(user1).into(user2)
      run_jobs

      expect(user2.attachments.count).to eq 2
      expect(user2.attachments.not_deleted.count).to eq 2

      expect(user2.attachments.not_deleted.detect{|a| a.md5 == attachment1.md5}).to eq attachment3

      new_attachment = user2.attachments.not_deleted.detect{|a| a.md5 == attachment2.md5}
      expect(new_attachment.display_name).not_to eq "test.txt" # attachment2 should be copied and renamed because it has unique file data
    end

    it "should move discussion topics and entries" do
      topic = course1.discussion_topics.create!(user: user2)
      entry = topic.discussion_entries.create!(user: user2)

      UserMerge.from(user2).into(user1)

      expect(topic.reload.user).to eq user1
      expect(entry.reload.user).to eq user1
    end

    it "should freshen moved topics" do
      topic = course1.discussion_topics.create!(user: user2)
      now = Time.at(5.minutes.from_now.to_i) # truncate milliseconds
      Timecop.freeze(now) do
        UserMerge.from(user2).into(user1)
        expect(topic.reload.updated_at).to eq now
      end
    end

    it "should freshen topics with moved entries" do
      topic = course1.discussion_topics.create!(user: user1)
      entry = topic.discussion_entries.create!(user: user2)
      now = Time.at(5.minutes.from_now.to_i) # truncate milliseconds
      Timecop.freeze(now) do
        UserMerge.from(user2).into(user1)
        expect(topic.reload.updated_at).to eq now
      end
    end
  end

  it "should update account associations" do
    account1 = account_model
    account2 = account_model
    pseudo1 = (user1 = user_with_pseudonym :account => account1).pseudonym
    pseudo2 = (user2 = user_with_pseudonym :account => account2).pseudonym
    subsubaccount1 = (subaccount1 = account1.sub_accounts.create!).sub_accounts.create!
    subsubaccount2 = (subaccount2 = account2.sub_accounts.create!).sub_accounts.create!
    course_with_student(:account => subsubaccount1, :user => user1)
    course_with_student(:account => subsubaccount2, :user => user2)

    expect(user1.associated_accounts.map(&:id).sort).to eq [account1, subaccount1, subsubaccount1].map(&:id).sort
    expect(user2.associated_accounts.map(&:id).sort).to eq [account2, subaccount2, subsubaccount2].map(&:id).sort

    expect(pseudo1.user).to eq user1
    expect(pseudo2.user).to eq user2

    UserMerge.from(user1).into(user2)

    pseudo1, pseudo2 = [pseudo1, pseudo2].map{|p| Pseudonym.find(p.id)}
    user1, user2 = [user1, user2].map{|u| User.find(u.id)}

    expect(pseudo1.user).to eq pseudo2.user
    expect(pseudo1.user).to eq user2

    expect(user1.associated_accounts.map(&:id).sort).to eq []
    expect(user2.associated_accounts.map(&:id).sort).to eq [account1, account2, subaccount1, subaccount2, subsubaccount1, subsubaccount2].map(&:id).sort
  end

  context "versions" do
    let!(:user1) { user_model }
    let!(:user2) { user_model }

    context "submissions" do
      it "updates the versions table" do
        other_user = user_model

        a1 = assignment_model(:submission_types => 'online_text_entry')
        a1.submit_homework(user2, {
          :submission_type => 'online_text_entry',
          :body => 'hi'
        })
        s1 = a1.submit_homework(user2, {
          :submission_type => 'online_text_entry',
          :body => 'hi again'
        })
        s_other = a1.submit_homework(other_user, {
          :submission_type => 'online_text_entry',
          :body => 'hi again'
        })

        expect(s1.versions.count).to eql(2)
        s1.versions.each{ |v| expect(v.model.user_id).to eql(user2.id) }
        expect(s_other.versions.first.model.user_id).to eql(other_user.id)

        UserMerge.from(user2).into(user1)
        s1 = Submission.find(s1.id)
        s_other.reload

        expect(s1.versions.count).to eql(2)
        s1.versions.each{ |v| expect(v.model.user_id).to eql(user1.id) }
        expect(s_other.versions.first.model.user_id).to eql(other_user.id)
      end

      it "updates the submission_versions table" do
        assignment = assignment_model(submission_types: 'online_text_entry')
        assignment.submit_homework(user2, {
          submission_type: 'online_text_entry',
          body: 'submission whoo'
        })
        submission = assignment.submit_homework(user2, {
          submission_type: 'online_text_entry',
          body: 'another submission!'
        })

        versions = SubmissionVersion.where(version_id: submission.versions)

        expect(versions.count).to eql(2)
        versions.each { |v| expect(v.user_id).to eql(user2.id) }
        UserMerge.from(user2).into(user1)

        versions.reload
        expect(versions.count).to eql(2)
        versions.each { |v| expect(v.user_id).to eql(user1.id) }
      end
    end

    it "should update quiz submissions" do
      quiz_with_graded_submission([], user: user2)
      qs1 = @quiz_submission
      quiz_with_graded_submission([], user: user2)
      qs2 = @quiz_submission
      Version.where(:versionable_type => "Quizzes::QuizSubmission", :versionable_id => qs2).update_all(:versionable_type => "QuizSubmission")

      expect(qs1.versions).to be_present
      qs1.versions.each{ |v| expect(v.model.user_id).to eql(user2.id) }
      expect(qs2.versions).to be_present
      qs2.versions.each{ |v| expect(v.model.user_id).to eql(user2.id) }

      UserMerge.from(user2).into(user1)
      qs1.reload
      qs2.reload

      expect(qs1.versions).to be_present
      qs1.versions.each{ |v| expect(v.model.user_id).to eql(user1.id) }
      expect(qs2.versions).to be_present
      qs2.versions.each{ |v| expect(v.model.user_id).to eql(user1.id) }
    end

    it "should update other appropriate versions" do
      course(:active_all => true)
      wiki_page = @course.wiki.wiki_pages.create(:title => "Hi", :user_id => user2.id)
      ra = rubric_assessment_model(:context => @course, :user => user2)

      expect(wiki_page.versions).to be_present
      wiki_page.versions.each{ |v| expect(v.model.user_id).to eql(user2.id) }
      expect(ra.versions).to be_present
      ra.versions.each{ |v| expect(v.model.user_id).to eql(user2.id) }

      UserMerge.from(user2).into(user1)
      wiki_page.reload
      ra.reload

      expect(wiki_page.versions).to be_present
      wiki_page.versions.each{ |v| expect(v.model.user_id).to eql(user1.id) }
      expect(ra.versions).to be_present
      ra.versions.each{ |v| expect(v.model.user_id).to eql(user1.id) }
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should merge a user across shards" do
      user1 = user_with_pseudonym(:username => 'user1@example.com', :active_all => 1)
      p1 = @pseudonym
      cc1 = @cc
      @shard1.activate do
        account = Account.create!
        @user2 = user_with_pseudonym(:username => 'user2@example.com', :active_all => 1, :account => account)
        @p2 = @pseudonym
      end

      @shard2.activate do
        UserMerge.from(user1).into(@user2)
      end

      expect(user1).to be_deleted
      expect(p1.reload.user).to eq @user2
      expect(cc1.reload).to be_retired
      @user2.reload
      expect(@user2.communication_channels.to_a.map(&:path).sort).to eq ['user1@example.com', 'user2@example.com']
      expect(@user2.all_pseudonyms).to eq [@p2, p1]
      expect(@user2.associated_shards).to eq [@shard1, Shard.default]
    end

    it "should associate the user with all shards" do
      user1 = user_with_pseudonym(:username => 'user1@example.com', :active_all => 1)
      p1 = @pseudonym
      cc1 = @cc
      @shard1.activate do
        account = Account.create!
        @p2 = account.pseudonyms.create!(:unique_id => 'user1@exmaple.com', :user => user1)
      end

      @shard2.activate do
        account = Account.create!
        @user2 = user_with_pseudonym(:username => 'user2@example.com', :active_all => 1, :account => account)
        @p3 = @pseudonym
        UserMerge.from(user1).into(@user2)
      end

      expect(@user2.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1, @shard2].sort_by(&:id)
      expect(@user2.all_pseudonyms.sort_by(&:id)).to eq [p1, @p2, @p3].sort_by(&:id)
    end

    it "should move ccs to the new user (but only if they don't already exist)" do
      user1 = user_model
      @shard1.activate do
        @user2 = user_model
      end

      # unconfirmed => active conflict
      user1.communication_channels.create!(:path => 'a@instructure.com')
      @user2.communication_channels.create!(:path => 'A@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => unconfirmed conflict
      user1.communication_channels.create!(:path => 'b@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'B@instructure.com')
      # active => active conflict
      user1.communication_channels.create!(:path => 'c@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'C@instructure.com') { |cc| cc.workflow_state = 'active' }
      # unconfirmed => unconfirmed conflict
      user1.communication_channels.create!(:path => 'd@instructure.com')
      @user2.communication_channels.create!(:path => 'D@instructure.com')
      # retired => unconfirmed conflict
      user1.communication_channels.create!(:path => 'e@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'E@instructure.com')
      # unconfirmed => retired conflict
      user1.communication_channels.create!(:path => 'f@instructure.com')
      @user2.communication_channels.create!(:path => 'F@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => active conflict
      user1.communication_channels.create!(:path => 'g@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'G@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => retired conflict
      user1.communication_channels.create!(:path => 'h@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'H@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => retired conflict
      user1.communication_channels.create!(:path => 'i@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'I@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # <nothing> => active
      @user2.communication_channels.create!(:path => 'j@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => <nothing>
      user1.communication_channels.create!(:path => 'k@instructure.com') { |cc| cc.workflow_state = 'active' }
      # <nothing> => unconfirmed
      @user2.communication_channels.create!(:path => 'l@instructure.com')
      # unconfirmed => <nothing>
      user1.communication_channels.create!(:path => 'm@instructure.com')
      # <nothing> => retired
      @user2.communication_channels.create!(:path => 'n@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => <nothing>
      user1.communication_channels.create!(:path => 'o@instructure.com') { |cc| cc.workflow_state = 'retired' }

      @shard2.activate do
        UserMerge.from(user1).into(@user2)
      end

      user1.reload
      @user2.reload
      expect(@user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq [
          ['A@instructure.com', 'active'],
          ['C@instructure.com', 'active'],
          ['D@instructure.com', 'unconfirmed'],
          ['E@instructure.com', 'unconfirmed'],
          ['G@instructure.com', 'active'],
          ['I@instructure.com', 'retired'],
          ['b@instructure.com', 'active'],
          ['f@instructure.com', 'unconfirmed'],
          ['h@instructure.com', 'active'],
          ['j@instructure.com', 'active'],
          ['k@instructure.com', 'active'],
          ['l@instructure.com', 'unconfirmed'],
          ['m@instructure.com', 'unconfirmed'],
          ['n@instructure.com', 'retired'],
          ['o@instructure.com', 'retired']
      ]
      # on cross shard merges, the deleted user retains all CCs (pertinent ones were
      # duplicated over to the surviving shard)
      expect(user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq [
          ['a@instructure.com', 'retired'],
          ['b@instructure.com', 'retired'],
          ['c@instructure.com', 'retired'],
          ['d@instructure.com', 'retired'],
          ['e@instructure.com', 'retired'],
          ['f@instructure.com', 'retired'],
          ['g@instructure.com', 'retired'],
          ['h@instructure.com', 'retired'],
          ['i@instructure.com', 'retired'],
          ['k@instructure.com', 'retired'],
          ['m@instructure.com', 'retired'],
          ['o@instructure.com', 'retired']
      ]
    end

    it "should not fail copying retired sms channels" do
      user1 = User.create!
      @shard1.activate do
        @user2 = User.create!
      end

      cc1 = @user2.communication_channels.sms.create!(:path => 'abc')
      cc1.retire!
      @user2.reload

      UserMerge.from(@user2).into(user1)
      expect(user1.communication_channels.reload.length).to eq 1
      cc2 = user1.communication_channels.first
      expect(cc2.path).to eq 'abc'
      expect(cc2.workflow_state).to eq 'retired'
    end

    it "should move user attachments and handle duplicates" do
      course
      root_attachment = Attachment.create(:context => @course, :filename => "unique_name1.txt",
                                          :uploaded_data => StringIO.new("root_attachment_data"))

      user1 = User.create!
      # should not copy because it's identical to @user2_attachment1
      user1_attachment1 = Attachment.create!(:user => user1, :context => user1, :filename => "shared_name1.txt",
                                             :uploaded_data => StringIO.new("shared_data"))
      # copy should have root_attachment directed to @user2_attachment2, and be renamed
      user1_attachment2 = Attachment.create!(:user => user1, :context => user1, :filename => "shared_name2.txt",
                                             :uploaded_data => StringIO.new("shared_data2"))
      # should copy as a root_attachment (even though it isn't one currently)
      user1_attachment3 = Attachment.create!(:user => user1, :context => user1, :filename => "unique_name2.txt",
                                             :uploaded_data => StringIO.new("root_attachment_data"))
      user1_attachment3.content_type = "text/plain"
      user1_attachment3.save!
      expect(user1_attachment3.root_attachment).to eq root_attachment

      @shard1.activate do
        new_account = Account.create!
        @user2 = user_with_pseudonym(:account => new_account)

        @user2_attachment1 = Attachment.create!(:user => @user2, :context => @user2, :filename => "shared_name1.txt",
                                                :uploaded_data => StringIO.new("shared_data"))

        @user2_attachment2 = Attachment.create!(:user => @user2, :context => @user2, :filename => "unique_name3.txt",
                                                :uploaded_data => StringIO.new("shared_data2"))

        @user2_attachment3 = Attachment.create!(:user => @user2, :context => @user2, :filename => "shared_name2.txt",
                                                :uploaded_data => StringIO.new("unique_data"))
      end

      UserMerge.from(user1).into(@user2)
      run_jobs

      expect(@user2.attachments.not_deleted.count).to eq 5

      new_user2_attachment1 = @user2.attachments.not_deleted.detect{|a| a.md5 == user1_attachment2.md5 && a.id != @user2_attachment2.id}
      expect(new_user2_attachment1.root_attachment).to eq @user2_attachment2
      expect(new_user2_attachment1.display_name).not_to eq user1_attachment2.display_name #should rename
      expect(new_user2_attachment1.namespace).not_to eq user1_attachment1.namespace

      new_user2_attachment2 = @user2.attachments.not_deleted.detect{|a| a.md5 == user1_attachment3.md5}
      expect(new_user2_attachment2.root_attachment).to be_nil
      expect(new_user2_attachment2.content_type).to eq "text/plain"
    end

    context "manual invitation" do
      it "should not keep a temporary invitation in cache for an enrollment deleted after a user merge" do
        email = 'foo@example.com'

        enable_cache do
          course
          @course.offer!

          # create an active enrollment (usually through an SIS import)
          user1 = user_with_pseudonym(:username => email, :active_all => true)
          @course.enroll_user(user1).accept!

          # manually invite the same email address into the course
          # if open_registration is set on the root account, this creates a new temporary user
          user2 = user_with_communication_channel(:username => email, :user_state => "creation_pending")
          @course.enroll_user(user2)

          # cache the temporary invitations
          expect(user1.temporary_invitations).not_to be_empty

          # when the user follows the confirmation link, they will be prompted to merge into the other user
          UserMerge.from(user2).into(user1)

          # should not hold onto the now-deleted invitation
          # (otherwise it will retrieve it in CoursesController#fetch_enrollment,
          # which causes the login loop in CoursesController#accept_enrollment)
          user1.reload
          expect(user1.temporary_invitations).to be_empty
        end
      end
    end
  end

end
