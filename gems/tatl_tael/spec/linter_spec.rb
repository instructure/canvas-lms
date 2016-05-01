require 'spec_helper'

describe TatlTael::Linter do
  shared_examples "yields" do |raw_changes|
    let(:changes) { raw_changes.map { |c| double(c) } }

    it "yields" do
      expect { |b| subject.ensure_specs(&b) }.to yield_with_no_args
    end
  end

  shared_examples "does not yield" do |raw_changes|
    let(:changes) { raw_changes.map { |c| double(c) } }

    it "does not yield" do
      expect { |b| subject.ensure_specs(&b) }.not_to yield_with_no_args
    end
  end

  shared_examples "change combos" do |change_path|
    context "not deletion" do
      context "no spec changes" do
        include_examples "yields",
                         [{ path: change_path, deleted?: false }]
      end
      context "has spec non deletions" do
        include_examples "does not yield",
                         [{ path: change_path, deleted?: false },
                          { path: SPEC_CHANGE, deleted?: false }]
        include_examples "does not yield",
                         [{ path: change_path, deleted?: false },
                          { path: SPEC_CANVAS_CHANGE, deleted?: false }]
        include_examples "does not yield",
                         [{ path: change_path, deleted?: false },
                          { path: TEST_CHANGE, deleted?: false }]
      end
      context "has spec deletions" do
        include_examples "yields",
                         [{ path: change_path, deleted?: false },
                          { path: SPEC_CHANGE, deleted?: true }]
        include_examples "yields",
                         [{ path: change_path, deleted?: false },
                          { path: SPEC_CANVAS_CHANGE, deleted?: true }]
        include_examples "yields",
                         [{ path: change_path, deleted?: false },
                          { path: TEST_CHANGE, deleted?: true }]
      end
    end
    context "deletion" do
      include_examples "does not yield",
                       [{ path: change_path, deleted?: true }]
    end
  end

  let(:subject) { TatlTael::Linter.new(git_dir: ".") }

  SPEC_CHANGE           = "spec/controllers/accounts_controller_spec.rb"
  SPEC_CANVAS_CHANGE    = "spec_canvas/selenium/analytics_course_view_spec.rb"
  TEST_CHANGE           = "gems/acts_as_list/test/list_test.rb"

  APP_RB_PATH           = "app/controllers/accounts_controller.rb"
  APP_ERB_PATH          = "app/views/announcements/index.html.erb"
  APP_JSX_PATH          = "app/jsx/editor/SwitchEditorControl.jsx"
  APP_COFFEE_PATH       = "app/coffeescripts/calendar/CalendarEvent.coffee"
  LIB_RB_PATH           = "lib/api_routes.rb"
  PUBLIC_HTML_PATH      = "public/partials/_license_help.html"
  PUBLIC_JS_PATH        = "public/javascripts/account_settings.js"
  PUBLIC_BOWER_JS_PATH  = "public/javascripts/bower/axios/dist/axios.amd.js"
  PUBLIC_ME_JS_PATH     = "public/javascripts/mediaelement/mep-feature-speed-instructure.js"
  PUBLIC_VENDOR_JS_PATH = "public/javascripts/vendor/bootstrap/bootstrap-dropdown.js"

  before(:each) do
    allow(subject).to receive(:changes).and_return(changes)
  end

  describe "#ensure_specs" do
    context "in app" do
      context "has ruby changes" do
        include_examples "change combos", APP_RB_PATH
      end
      context "has erb changes" do
        include_examples "change combos", APP_ERB_PATH
      end
      context "has jsx changes" do
        include_examples "change combos", APP_JSX_PATH
      end
      context "has coffee changes" do
        include_examples "change combos", APP_COFFEE_PATH
      end
    end

    context "in lib" do
      context "has ruby changes" do
        include_examples "change combos", LIB_RB_PATH
      end
    end

    context "in public" do
      context "has html changes" do
        include_examples "change combos", PUBLIC_HTML_PATH
      end
      context "has js changes" do
        include_examples "change combos", PUBLIC_JS_PATH
      end
    end

    context "in excluded public sub dirs" do
      context "bower" do
        include_examples "does not yield",
                         [{ path: PUBLIC_BOWER_JS_PATH, deleted?: false }]
      end
      context "mediaelement" do
        include_examples "does not yield",
                         [{ path: PUBLIC_ME_JS_PATH, deleted?: false }]
      end
      context "vendor" do
        include_examples "does not yield",
                         [{ path: PUBLIC_VENDOR_JS_PATH, deleted?: false }]
      end
    end
  end

  describe "#ban_new_erb" do
    context "erb additions exist" do
      let(:changes) { [double(path: "yarg.erb", added?: true)] }

      it "yields" do
        expect { |b| subject.ban_new_erb(&b) }.to yield_with_no_args
      end
    end

    context "erb non additions exist" do
      let(:changes) { [double(path: "yarg.erb", added?: false)] }

      it "does not yield" do
        expect { |b| subject.ban_new_erb(&b) }.not_to yield_with_no_args
      end
    end

    context "no erb changes exist" do
      let(:changes) { [double(path: "yarg.js", added?: true)] }

      it "does not yield" do
        expect { |b| subject.ban_new_erb(&b) }.not_to yield_with_no_args
      end
    end
  end
end
