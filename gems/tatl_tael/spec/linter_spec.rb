require 'spec_helper'

describe TatlTael::Linter do
  shared_examples "yields" do |raw_changes, ensure_method|
    let(:changes) { raw_changes.map { |c| double(c) } }

    it "yields" do
      expect { |b| subject.send(ensure_method, &b) }.to yield_with_no_args
    end
  end

  shared_examples "does not yield" do |raw_changes, ensure_method|
    let(:changes) { raw_changes.map { |c| double(c) } }

    it "does not yield" do
      expect { |b| subject.send(ensure_method, &b) }.not_to yield_with_no_args
    end
  end

  shared_examples "change combos" do |change_path, spec_path, ensure_method|
    context "not deletion" do
      context "no spec changes" do
        include_examples "yields",
                         [{ path: change_path, deleted?: false }], ensure_method
      end
      context "has spec non deletions" do
        include_examples "does not yield",
                         [{ path: change_path, deleted?: false },
                          { path: spec_path, deleted?: false }], ensure_method
      end
      context "has spec deletions" do
        include_examples "yields",
                         [{ path: change_path, deleted?: false },
                          { path: spec_path, deleted?: true }], ensure_method
      end
    end
    context "deletion" do
      include_examples "does not yield",
                       [{ path: change_path, deleted?: true }], ensure_method
    end
  end

  let(:subject) { TatlTael::Linter.new(git_dir: ".") }

  APP_COFFEE_PATH        = "app/coffeescripts/calendar/CalendarEvent.coffee"
  APP_COFFEE_BUNDLE_PATH = "app/coffeescripts/bundles/account_authorization_configs.coffee"
  COFFEE_SPEC_PATH       = "spec/coffeescripts/calendar/CalendarSpec.coffee"

  APP_JSX_PATH           = "app/jsx/dashboard_card/DashboardCardAction.jsx"
  JSX_SPEC_PATH          = "spec/javascripts/jsx/dashboard_card/DashboardCardActionSpec.coffee"

  APP_RB_PATH            = "app/controllers/accounts_controller.rb"
  APP_RB_SPEC_PATH       = "spec/controllers/accounts_controller_spec.rb"
  LIB_RB_PATH            = "lib/reporting/counts_report.rb"
  LIB_RB_SPEC_PATH       = "spec/lib/reporting/counts_report_spec.rb"

  APP_ERB_PATH           = "app/views/announcements/index.html.erb"
  OTHER_ERB_PATH         = "spec/formatters/error_context/html_page_formatter/template.html.erb"
  PUBLIC_JS_PATH         = "public/javascripts/eportfolios/eportfolio_section.js"
  PUBLIC_JS_SPEC_PATH    = "spec/javascripts/jsx/eportfolios/eportfolioSectionSpec.jsx"

  PUBLIC_BOWER_JS_PATH   = "public/javascripts/bower/axios/dist/axios.amd.js"
  PUBLIC_ME_JS_PATH      = "public/javascripts/mediaelement/mep-feature-speed-instructure.js"
  PUBLIC_VENDOR_JS_PATH  = "public/javascripts/vendor/bootstrap/bootstrap-dropdown.js"
  SELENIUM_SPEC_PATH     = "spec/selenium/announcements/announcements_student_spec.rb"

  before(:each) do
    allow(subject).to receive(:changes).and_return(changes)
  end

  describe "#ensure_coffee_specs" do
    context "coffee changes" do
      include_examples "change combos",
                       APP_COFFEE_PATH,
                       COFFEE_SPEC_PATH,
                       :ensure_coffee_specs

      context "bundles" do
        include_examples "does not yield",
                         [{ path: APP_COFFEE_BUNDLE_PATH, deleted?: false }],
                         :ensure_coffee_specs
      end

      context "with jsx spec changes" do
        include_examples "change combos",
                         APP_COFFEE_PATH,
                         JSX_SPEC_PATH,
                         :ensure_coffee_specs
      end
    end
  end

  describe "#ensure_public_js_specs" do
    include_examples "change combos",
                     PUBLIC_JS_PATH,
                     PUBLIC_JS_SPEC_PATH,
                     :ensure_public_js_specs

    context "in excluded public sub dirs" do
      context "bower" do
        include_examples "does not yield",
                         [{ path: PUBLIC_BOWER_JS_PATH, deleted?: false }],
                         :ensure_public_js_specs
      end
      context "mediaelement" do
        include_examples "does not yield",
                         [{ path: PUBLIC_ME_JS_PATH, deleted?: false }],
                         :ensure_public_js_specs
      end
      context "vendor" do
        include_examples "does not yield",
                         [{ path: PUBLIC_VENDOR_JS_PATH, deleted?: false }],
                         :ensure_public_js_specs
      end
    end
  end

  describe "#ensure_jsx_specs" do
    include_examples "change combos",
                     APP_JSX_PATH,
                     JSX_SPEC_PATH,
                     :ensure_jsx_specs
  end

  describe "#ensure_ruby_specs" do
    context "app" do
      include_examples "change combos",
                       APP_RB_PATH,
                       APP_RB_SPEC_PATH,
                       :ensure_ruby_specs
    end

    context "lib" do
      include_examples "change combos",
                       LIB_RB_PATH,
                       LIB_RB_SPEC_PATH,
                       :ensure_ruby_specs
    end
  end

  describe "#ensure_no_unnecessary_selenium_specs" do
    context "has selenium specs" do
      context "needs public js specs" do
        context "has no public js specs" do
          include_examples "yields",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: PUBLIC_JS_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end

        context "has public js specs" do
          include_examples "does not yield",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: PUBLIC_JS_PATH, deleted?: false },
                            { path: PUBLIC_JS_SPEC_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end
      end

      context "needs coffee specs" do
        context "has no coffee specs" do
          include_examples "yields",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_COFFEE_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end

        context "has coffee specs" do
          include_examples "does not yield",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_COFFEE_PATH, deleted?: false },
                            { path: COFFEE_SPEC_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end
      end

      context "needs jsx specs" do
        context "has no jsx specs" do
          include_examples "yields",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_JSX_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end

        context "has jsx specs" do
          include_examples "does not yield",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_JSX_PATH, deleted?: false },
                            { path: JSX_SPEC_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end
      end

      context "needs ruby specs" do
        context "has no ruby specs" do
          include_examples "yields",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_RB_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end

        context "has ruby specs" do
          include_examples "does not yield",
                           [{ path: SELENIUM_SPEC_PATH, deleted?: false },
                            { path: APP_RB_PATH, deleted?: false },
                            { path: APP_RB_SPEC_PATH, deleted?: false }],
                           :ensure_no_unnecessary_selenium_specs
        end
      end
    end

    context "has no selenium specs" do
      include_examples "does not yield",
                       [{ path: PUBLIC_VENDOR_JS_PATH, deleted?: false }],
                       :ensure_no_unnecessary_selenium_specs
    end
  end

  describe "#ban_new_erb" do
    context "app views erb additions exist" do
      let(:changes) { [double(path: APP_ERB_PATH, added?: true)] }

      it "yields" do
        expect { |b| subject.ban_new_erb(&b) }.to yield_with_no_args
      end
    end

    context "other erb additions exist" do
      let(:changes) { [double(path: OTHER_ERB_PATH, added?: true)] }

      it "yields" do
        expect { |b| subject.ban_new_erb(&b) }.not_to yield_with_no_args
      end
    end

    context "erb non additions exist" do
      let(:changes) { [double(path: APP_ERB_PATH, added?: false)] }

      it "does not yield" do
        expect { |b| subject.ban_new_erb(&b) }.not_to yield_with_no_args
      end
    end

    context "no erb changes exist" do
      let(:changes) { [double(path: PUBLIC_VENDOR_JS_PATH, added?: true)] }

      it "does not yield" do
        expect { |b| subject.ban_new_erb(&b) }.not_to yield_with_no_args
      end
    end
  end
end
