require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SearchController, type: :request do
  before do
    @account = Account.default
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
        {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {}},
        {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {}},
        {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {}},
        {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {}},
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

    it "should return recipients found by sis id" do
      p = Pseudonym.create(account: @account, user: @bob, unique_id: 'bob@example.com')
      p.sis_user_id = 'abc123'
      p.save!
      json = api_call(:get, "/api/v1/search/recipients?user_id=sis_user_id:abc123",
                      { :controller => 'search', :action => 'recipients', :format => 'json', :user_id=>"sis_user_id:abc123" })
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
      c = Conversation.initiate([@user, other], true)
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
                            {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bobs_mom.id, "name" => "bob's mom", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
                            {"id" => @lonely.id, "name" => "lonely observer", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
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
                            {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
                            {"id" => @lonely.id, "name" => "lonely observer", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}}
                        ]
      end

      it "should not show non-linked observers to students" do
        json = api_call_as_user(@bob, :get, "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
                            {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
                            {"id" => @bobs_mom.id, "name" => "bob's mom", "common_courses" => {@course.id.to_s => ["ObserverEnrollment"]}, "common_groups" => {}},
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
          {"id" => "course_#{@course.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1, "permissions" => {}},
          {"id" => "course_#{@course.id}_students", "name" => "Students", "type" => "context", "user_count" => 5, "permissions" => {}},
          {"id" => "course_#{@course.id}_sections", "name" => "Course Sections", "type" => "context", "item_count" => 2},
          {"id" => "course_#{@course.id}_groups", "name" => "Student Groups", "type" => "context", "item_count" => 1}
        ]
      end

      it "should return synthetic contexts within a section" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=section_#{@course.default_section.id}&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "section_#{@course.default_section.id}", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@course.default_section.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1, "permissions" => {}},
          {"id" => "section_#{@course.default_section.id}_students", "name" => "Students", "type" => "context", "user_count" => 4, "permissions" => {}}
        ]
      end

      it "should return groups within a course" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}_groups", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "permissions" => {}}
        ]
      end

      it "should return sections within a course" do
        json = api_call(:get, "/api/v1/search/recipients.json?context=course_#{@course.id}_sections&synthetic_contexts=1",
                { :controller => 'search', :action => 'recipients', :format => 'json', :context => "course_#{@course.id}_sections", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@other_section.id}", "name" => @other_section.name, "type" => "context", "user_count" => 1, "permissions" => {}},
          {"id" => "section_#{@course.default_section.id}", "name" => @course.default_section.name, "type" => "context", "user_count" => 5, "permissions" => {}}
        ]
      end
    end

    context "permissions" do
      it "should return valid permission data" do
        json = api_call(:get, "/api/v1/search/recipients.json?search=the%20o&permissions[]=send_messages_all",
                { :controller => 'search', :action => 'recipients', :format => 'json', :search => 'the o', :permissions => ["send_messages_all"] })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {"send_messages_all" => true}},
          {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {"send_messages_all" => true}},
          {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {"send_messages_all" => true}},
          {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {"send_messages_all" => true}}
        ]
      end

      it "should not return invalid permission data" do
        json = api_call(:get, "/api/v1/search/recipients.json?search=the%20o&permissions[]=foo_bar",
                { :controller => 'search', :action => 'recipients', :format => 'json', :search => 'the o', :permissions => ["foo_bar"] })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {}},
          {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {}},
          {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {}},
          {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {}}
        ]
      end
    end

    context "pagination" do
      it "should paginate even if no type is specified" do
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should_not be_nil
      end

      it "should paginate users and return proper pagination headers" do
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '3'})
        json.size.should eql 3
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'cletus'
          l['type'].should == 'user'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'next', 'first']

        # get the next page
        json = follow_pagination_link('next', :controller => 'search', :action => 'recipients')
        json.size.should eql 1
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'cletus'
          l['type'].should == 'user'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'first', 'last']
      end

      it "should paginate contexts and return proper pagination headers" do
        4.times{
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "ofcourse")
        }

        json = api_call(:get, "/api/v1/search/recipients.json?search=ofcourse&type=context&per_page=3",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :per_page => '3'})
        json.size.should eql 3
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'ofcourse'
          l['type'].should == 'context'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'next', 'first']

        # get the next page
        json = follow_pagination_link('next', :controller => 'search', :action => 'recipients')
        json.size.should eql 1
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'ofcourse'
          l['type'].should == 'context'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'first', 'last']
      end

      it "should ignore invalid per_page" do
        11.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/search/recipients.json?search=cletus&type=user&per_page=-1",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '-1'})
        json.size.should eql 10
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'cletus'
          l['type'].should == 'user'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'next', 'first']

        # get the next page
        json = follow_pagination_link('next', :controller => 'search', :action => 'recipients')
        json.size.should eql 1
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'cletus'
          l['type'].should == 'user'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'first', 'last']
      end

      it "should paginate combined context/user results" do
        # 6 courses, 6 users, 12 items total
        course_ids = []
        user_ids = []
        6.times do
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "term")
          student = student_in_course(:name => "term")
          course_ids << @course.asset_string
          user_ids << student.id
        end

        json = api_call(:get, "/api/v1/search/recipients.json?search=term&per_page=4",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :search => 'term', :per_page => '4'})
        json.size.should eql 4
        json.map{ |item| item['id'] }.should == course_ids[0...4]
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'term'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'next', 'first']

        # get the next page
        json = follow_pagination_link('next', :controller => 'search', :action => 'recipients')
        json.size.should eql 4
        json.map{ |item| item['id'] }.should == course_ids[4...6] + user_ids[0...2]
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'term'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'next', 'first']

        # get the final page
        json = follow_pagination_link('next', :controller => 'search', :action => 'recipients')
        json.size.should eql 4
        json.map{ |item| item['id'] }.should == user_ids[2...6]
        links = Api.parse_pagination_links(response.headers['Link'])
        links.each do |l|
          l[:uri].to_s.should match(%r{api/v1/search/recipients})
          l['search'].should == 'term'
        end
        links.map{ |l| l[:rel] }.should == ['current', 'first', 'last']
      end
    end

    describe "sorting contexts" do
      it "should sort contexts by workflow state first when searching" do
        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
        course1 = @course
        course1.update_attribute(:name, "Context Alpha")
        @enrollment.update_attribute(:workflow_state, 'completed')

        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
        course2 = @course
        course2.update_attribute(:name, "Context Beta")

        json = api_call(:get, "/api/v1/search/recipients.json?type=context&search=Context&include_inactive=1",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :type => 'context', :search => 'Context', :include_inactive => '1'})
        json.map{ |item| item['id'] }.should == [course2.asset_string, course1.asset_string]
      end

      it "should sort contexts by type second when searching" do
        @course.update_attribute(:name, "Context Beta")
        @group.update_attribute(:name, "Context Alpha")
        json = api_call(:get, "/api/v1/search/recipients.json?type=context&search=Context",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :type => 'context', :search => 'Context'})
        json.map{ |item| item['id'] }.should == [@course.asset_string, @group.asset_string]
      end

      it "should sort contexts by name third when searching" do
        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
        course1 = @course
        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
        course2 = @course

        course1.update_attribute(:name, "Context Beta")
        course2.update_attribute(:name, "Context Alpha")

        json = api_call(:get, "/api/v1/search/recipients.json?type=context&search=Context",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :type => 'context', :search => 'Context'})
        json.map{ |item| item['id'] }.should == [course2.asset_string, course1.asset_string]
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should find top-level groups from any shard" do
        @me.associate_with_shard(@shard1)
        @me.associate_with_shard(@shard2)
        @bob.associate_with_shard(@shard1)
        @joe.associate_with_shard(@shard2)

        group1 = nil
        @shard1.activate{
          group1 = Group.create(:context => Account.create!, :name => "shard 1 group")
          group1.add_user(@me)
          group1.add_user(@bob)
        }

        group2 = nil
        @shard2.activate{
          group2 = Group.create(:context => Account.create!, :name => "shard 2 group")
          group2.users = [@me, @joe]
          group2.save!
        }

        json = api_call(:get, "/api/v1/search/recipients.json?type=group&search=group",
                        {:controller => 'search', :action => 'recipients', :format => 'json', :type => 'group', :search => 'group'})
        ids = json.map{ |item| item['id'] }
        ids.should include(group1.asset_string)
        ids.should include(group2.asset_string)
      end
    end
  end

end
