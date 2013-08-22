$LOAD_PATH << Pathname.new(File.absolute_path __FILE__) + "../../.."
require 'lib/ember_bundle'

describe EmberBundle do
  before :each do
    @bundle = EmberBundle.new('inbox', {
      :files => [
        "app/coffeescripts/ember/inbox/config/app.coffee",
        "app/coffeescripts/ember/inbox/config/routes.coffee",
        "app/coffeescripts/ember/inbox/models/conversation.coffee",
        "app/coffeescripts/ember/inbox/routes/application_route.coffee",
        "app/coffeescripts/ember/inbox/routes/conversation_route.coffee"
      ],
      :templates => [
        "app/coffeescripts/ember/inbox/templates/application.hbs",
        "app/coffeescripts/ember/inbox/templates/conversation.hbs",
        "app/coffeescripts/ember/inbox/templates/index.hbs"
      ]
    })
  end

  describe '::parse_app_from_file' do
    it 'parses app name from a file inside the bundle (for guard)' do
      EmberBundle::parse_app_from_file("app/coffeescripts/ember/inbox/config/app.coffee").should == 'inbox'
    end
  end

  describe '#initialize' do
    it 'creates an array of files to require' do
      @bundle.paths.should == [
        "Ember",
        "compiled/ember/inbox/config/app",
        "compiled/ember/inbox/config/routes",
        "compiled/ember/inbox/models/conversation",
        "compiled/ember/inbox/routes/application_route",
        "compiled/ember/inbox/routes/conversation_route",
        "compiled/ember/inbox/templates/application",
        "compiled/ember/inbox/templates/conversation",
        "compiled/ember/inbox/templates/index"
      ]
    end

    it 'creates an array of objects to assign to the app namespace' do
      @bundle.objects.should == %w(Ember App routes Conversation ApplicationRoute ConversationRoute)
    end

    it 'matches the order of the require paths and objects' do
      @bundle.objects[0].should == "Ember"
      @bundle.paths[0].should == "Ember"
      @bundle.objects[1].should == "App"
      @bundle.paths[1].should == "compiled/ember/inbox/config/app"
      @bundle.objects[2].should == "routes"
      @bundle.paths[2].should == "compiled/ember/inbox/config/routes"
      @bundle.objects[3].should == "Conversation"
      @bundle.paths[3].should == "compiled/ember/inbox/models/conversation"
      @bundle.objects[4].should == "ApplicationRoute"
      @bundle.paths[4].should == "compiled/ember/inbox/routes/application_route"
      @bundle.objects[5].should == "ConversationRoute"
      @bundle.paths[5].should == "compiled/ember/inbox/routes/conversation_route"
    end
  end

  describe "#build_output" do
    it "looks like this" do
      @bundle.build_output.should == <<-END
# this is auto-generated
define ["Ember", "compiled/ember/inbox/config/app", "compiled/ember/inbox/config/routes", "compiled/ember/inbox/models/conversation", "compiled/ember/inbox/routes/application_route", "compiled/ember/inbox/routes/conversation_route", "compiled/ember/inbox/templates/application", "compiled/ember/inbox/templates/conversation", "compiled/ember/inbox/templates/index"], (Ember, App, routes, Conversation, ApplicationRoute, ConversationRoute) ->

  App.reopen
    Conversation: Conversation
    ApplicationRoute: ApplicationRoute
    ConversationRoute: ConversationRoute
END
    end
  end

  describe '#parse_object_name' do
    it 'parses ember object names from file paths' do
      root = 'app/coffeescripts/ember/inbox'
      @bundle.parse_object_name("#{root}/components/x_foo_component.coffee").should == 'XFooComponent'
      @bundle.parse_object_name("#{root}/controllers/foo/bar_controller.coffee").should == 'FooBarController'
      @bundle.parse_object_name("#{root}/models/foo.coffee").should == 'Foo'
      @bundle.parse_object_name("#{root}/routes/foo_route.coffee").should == 'FooRoute'
      @bundle.parse_object_name("#{root}/views/foo_view.coffee").should == 'FooView'
    end

    it 'parses really deeply nested paths' do
      path = 'app/coffeescripts/ember/inbox/controllers/foo/bar/baz/quux_controller.coffee'
      @bundle.parse_object_name(path).should == 'FooBarBazQuuxController'
    end
  end

  describe '#parse_require_path' do
    it 'parses require path from file path' do
      path = 'app/coffeescripts/ember/inbox/controllers/foo/bar_controller.coffee'
      @bundle.parse_require_path(path).should == 'compiled/ember/inbox/controllers/foo/bar_controller'
      path = 'app/coffeescripts/ember/inbox/templates/components/x-foo.hbs'
      @bundle.parse_require_path(path).should == 'compiled/ember/inbox/templates/components/x-foo'
    end
  end

  describe '#assignable_objects' do
    it 'grabs only the files ember expects to be assigned to the App namespace' do
      paths = [
        "app/coffeescripts/ember/inbox/config/app.coffee",
        "app/coffeescripts/ember/inbox/config/routes.coffee",
        "app/coffeescripts/ember/inbox/models/conversation.coffee",
        "app/coffeescripts/ember/inbox/routes/application_route.coffee",
        "app/coffeescripts/ember/inbox/routes/conversation_route.coffee"
      ]
      expected = [
        "app/coffeescripts/ember/inbox/models/conversation.coffee",
        "app/coffeescripts/ember/inbox/routes/application_route.coffee",
        "app/coffeescripts/ember/inbox/routes/conversation_route.coffee"
      ]
      @bundle.assignable_paths(paths).should == expected
    end
  end
end

