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
      expect(EmberBundle::parse_app_from_file("app/coffeescripts/ember/inbox/config/app.coffee")).to eq 'inbox'
    end
  end

  describe '#initialize' do
    it 'creates an array of files to require' do
      expect(@bundle.paths).to eq [
        "ember",
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
      expect(@bundle.objects).to eq %w(Ember App routes Conversation ApplicationRoute ConversationRoute)
    end

    it 'matches the order of the require paths and objects' do
      expect(@bundle.objects[0]).to eq "Ember"
      expect(@bundle.paths[0]).to eq "ember"
      expect(@bundle.objects[1]).to eq "App"
      expect(@bundle.paths[1]).to eq "compiled/ember/inbox/config/app"
      expect(@bundle.objects[2]).to eq "routes"
      expect(@bundle.paths[2]).to eq "compiled/ember/inbox/config/routes"
      expect(@bundle.objects[3]).to eq "Conversation"
      expect(@bundle.paths[3]).to eq "compiled/ember/inbox/models/conversation"
      expect(@bundle.objects[4]).to eq "ApplicationRoute"
      expect(@bundle.paths[4]).to eq "compiled/ember/inbox/routes/application_route"
      expect(@bundle.objects[5]).to eq "ConversationRoute"
      expect(@bundle.paths[5]).to eq "compiled/ember/inbox/routes/conversation_route"
    end
  end

  describe "#build_output" do
    it "looks like this" do
      expect(@bundle.build_output).to eq <<-END
# this is auto-generated
define ["ember", "compiled/ember/inbox/config/app", "compiled/ember/inbox/config/routes", "compiled/ember/inbox/models/conversation", "compiled/ember/inbox/routes/application_route", "compiled/ember/inbox/routes/conversation_route", "compiled/ember/inbox/templates/application", "compiled/ember/inbox/templates/conversation", "compiled/ember/inbox/templates/index"], (Ember, App, routes, Conversation, ApplicationRoute, ConversationRoute) ->

  App.reopen({
    Conversation: Conversation
    ApplicationRoute: ApplicationRoute
    ConversationRoute: ConversationRoute
  })
END
    end
  end

  describe '#parse_object_name' do
    it 'parses ember object names from file paths' do
      root = 'app/coffeescripts/ember/inbox'
      expect(@bundle.parse_object_name("#{root}/components/x_foo_component.coffee")).to eq 'XFooComponent'
      expect(@bundle.parse_object_name("#{root}/controllers/foo/bar_controller.coffee")).to eq 'FooBarController'
      expect(@bundle.parse_object_name("#{root}/models/foo.coffee")).to eq 'Foo'
      expect(@bundle.parse_object_name("#{root}/routes/foo_route.coffee")).to eq 'FooRoute'
      expect(@bundle.parse_object_name("#{root}/views/foo_view.coffee")).to eq 'FooView'
    end

    it 'parses really deeply nested paths' do
      path = 'app/coffeescripts/ember/inbox/controllers/foo/bar/baz/quux_controller.coffee'
      expect(@bundle.parse_object_name(path)).to eq 'FooBarBazQuuxController'
    end
  end

  describe '#parse_require_path' do
    it 'parses require path from file path' do
      path = 'app/coffeescripts/ember/inbox/controllers/foo/bar_controller.coffee'
      expect(@bundle.parse_require_path(path)).to eq 'compiled/ember/inbox/controllers/foo/bar_controller'
      path = 'app/coffeescripts/ember/inbox/templates/components/x-foo.hbs'
      expect(@bundle.parse_require_path(path)).to eq 'compiled/ember/inbox/templates/components/x-foo'
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
      expect(@bundle.assignable_paths(paths)).to eq expected
    end
  end
end

