require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SearchController, :type => :integration do
  before do
    course_with_teacher(:active_course => true, :active_enrollment => true, :user => user_with_pseudonym(:active_user => true))
    @course.update_attribute(:name, "the course")
    @course.default_section.update_attributes(:name => "the section")
    @other_section = @course.course_sections.create(:name => "the other section")
    @me = @user

    @bob = student_in_course(:name => "bob")
    @billy = student_in_course(:name => "billy")
    @jane = student_in_course(:name => "jane")
    @joe = student_in_course(:name => "joe")
    @tommy = student_in_course(:name => "tommy", :section => @other_section)
  end

  def student_in_course(options = {})
    section = options.delete(:section)
    u = User.create(options)
    enrollment = @course.enroll_user(u, 'StudentEnrollment', :section => section)
    enrollment.workflow_state = 'active'
    enrollment.save
    u.associated_accounts << Account.default
    u
  end

  context "recipients" do
    before do
      @group = @course.groups.create(:name => "the group")
      @group.users = [@me, @bob, @joe]
    end

    it "should return recipients" do
      json = api_call(:get, "/api/v1/search/recipients.json?search=o",
              { :controller => 'search', :action => 'recipients', :format => 'json', :search => 'o' })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6},
        {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course"},
        {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course"},
        {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course"},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients for a given course" do
      json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
        {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients for a given group" do
      json = api_call(:get, "/api/v1/search/recipients.json?context=group_#{@group.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :context => "group_#{@group.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}}
      ]
    end

    it "should return recipients for a given section" do
      json = api_call(:get, "/api/v1/search/recipients.json?context=section_#{@course.default_section.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :context => "section_#{@course.default_section.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients found by id" do
      json = api_call(:get, "/api/v1/search/recipients?user_id=#{@bob.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :user_id => @bob.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
      ]
    end

    it "should ignore other parameters when searching by id" do
      json = api_call(:get, "/api/v1/search/recipients?user_id=#{@bob.id}&search=asdf",
              { :controller => 'search', :action => 'recipients', :format => 'json', :user_id => @bob.id.to_s, :search => "asdf" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
      ]
    end

    it "should return recipients by id if contactable, or if a shared conversation is referenced" do
      other = User.create(:name => "other personage")
      json = api_call(:get, "/api/v1/search/recipients?user_id=#{other.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :user_id => other.id.to_s })
      json.should == []
      # now they have a conversation in common
      c = Conversation.initiate([@user.id, other.id], true)
      json = api_call(:get, "/api/v1/search/recipients?user_id=#{other.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :user_id => other.id.to_s })
      json.should == []
      # ... but it has to be explicity referenced via from_conversation_id
      json = api_call(:get, "/api/v1/search/recipients?user_id=#{other.id}&from_conversation_id=#{c.id}",
              { :controller => 'search', :action => 'recipients', :format => 'json', :user_id => other.id.to_s, :from_conversation_id => c.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => other.id, "name" => "other personage", "common_courses" => {}, "common_groups" => {}},
      ]
    end

    context "observers" do
      def observer_in_course(options = {})
        section = options.delete(:section)
        associated_user = options.delete(:associated_user)
        u = User.create(options)
        enrollment = @course.enroll_user(u, 'ObserverEnrollment', :section => section)
        enrollment.associated_user = associated_user
        enrollment.workflow_state = 'active'
        enrollment.save
        u.associated_accounts << Account.default
        u
      end

      before do
        @bobs_mom = observer_in_course(:name => "bob's mom", :associated_user => @bob)
        @lonely = observer_in_course(:name => "lonely observer")
      end

      it "should show all observers to a teacher" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                        { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bobs_mom.id, "name" => "bob's mom", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @lonely.id, "name" => "lonely observer", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
                            {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
                        ]
      end

      it "should not show non-linked students to observers" do
        json = api_call_as_user(@bobs_mom, :get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                        { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bobs_mom.id, "name" => "bob's mom", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}}
                        ]

        json = api_call_as_user(@lonely, :get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                        { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @lonely.id, "name" => "lonely observer", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}}
                        ]
      end

      it "should not show non-linked observers to students" do
        json = api_call_as_user(@bob, :get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bobs_mom.id, "name" => "bob's mom", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            # must not include lonely observer here
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
                            {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
                        ]

        json = api_call_as_user(@billy, :get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            # must not include bob's mom here
                            {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            # must not include lonely observer here
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
                            {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
                        ]
      end
    end

    context "synthetic contexts" do
      it "should return synthetic contexts within a course" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "course_#{@course.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1},
          {"id" => "course_#{@course.id}_students", "name" => "Students", "type" => "context", "user_count" => 5},
          {"id" => "course_#{@course.id}_sections", "name" => "Course Sections", "type" => "context", "item_count" => 2},
          {"id" => "course_#{@course.id}_groups", "name" => "Student Groups", "type" => "context", "item_count" => 1}
        ]
      end

      it "should return synthetic contexts within a section" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=section_#{@course.default_section.id}&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "section_#{@course.default_section.id}", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@course.default_section.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1},
          {"id" => "section_#{@course.default_section.id}_students", "name" => "Students", "type" => "context", "user_count" => 4}
        ]
      end

      it "should return groups within a course" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}_groups", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3}
        ]
      end

      it "should return sections within a course" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}_sections&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}_sections", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@other_section.id}", "name" => @other_section.name, "type" => "context", "user_count" => 1},
          {"id" => "section_#{@course.default_section.id}", "name" => @course.default_section.name, "type" => "context", "user_count" => 5}
        ]
      end
    end

    context "pagination" do
      it "should not paginate if no type is specified" do
        # it's a synthetic result (we might a few of each type), making
        # pagination pretty tricksy. so we don't allow it
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should be_nil
      end

      it "should paginate users and return proper pagination headers" do
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should eql(%{</api/v1/search/recipients.json?search=cletus&type=user&page=2&per_page=3>; rel="next",</api/v1/search/recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="first"})

        # get the next page
        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&page=2&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :type => 'user', :page => '2', :per_page => '3'})
        json.size.should eql 1
        response.headers['Link'].should eql(%{</api/v1/search/recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="prev",</api/v1/search/recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="first"})
      end

      it "should allow fetching all users iff a context is specified" do
        # for admins in particular, there may be *lots* of messageable users,
        # so we don't allow retrieval of all of them unless a context is given
        11.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&per_page=-1",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '-1'})
        json.size.should eql 10
        response.headers['Link'].should eql(%{</api/v1/search/recipients.json?search=cletus&type=user&page=2&per_page=10>; rel="next",</api/v1/search/recipients.json?search=cletus&type=user&page=1&per_page=10>; rel="first"})

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&context=course_#{@course.id}&per_page=-1",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :context => "course_#{@course.id}", :type => 'user', :per_page => '-1'})
        json.size.should eql 11
        response.headers['Link'].should be_nil
      end

      it "should paginate contexts and return proper pagination headers" do
        4.times{
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "ofcourse")
        }

        json = api_call(:get, "/api/v1/search/recipients.json?search=ofcourse&type=context&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should eql(%{</api/v1/search/recipients.json?search=ofcourse&type=context&page=2&per_page=3>; rel="next",</api/v1/search/recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="first"})

        # get the next page
        json = api_call(:get, "/api/v1/search/recipients.json?search=ofcourse&type=context&page=2&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :page => '2', :per_page => '3'})
        json.size.should eql 1
        response.headers['Link'].should eql(%{</api/v1/search/recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="prev",</api/v1/search/recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="first"})
      end

      it "should allow fetching all contexts" do
        4.times{
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "ofcourse")
        }

        json = api_call(:get, "/api/v1/search/recipients.json?search=ofcourse&type=context&per_page=-1",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :per_page => '-1'})
        json.size.should eql 4
        response.headers['Link'].should be_nil
      end
    end
  end

end
