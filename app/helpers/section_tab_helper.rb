module SectionTabHelper
  def available_section_tabs(context)
    AvailableSectionTabs.new(
      context, @current_user, @domain_root_account, session
    ).to_a
  end

  def section_tabs
    @section_tabs ||= begin
      if @context && available_section_tabs(@context).any?
        content_tag(:nav, {
          :role => 'navigation',
          :'aria-label' => 'context'
        }) do
          concat(content_tag(:ul, id: 'section-tabs') do
            available_section_tabs(@context).map do |tab|
              section_tab_tag(tab, @context, @active_tab)
            end
          end)
        end
      end
    end
    raw(@section_tabs)
  end

  def section_tab_tag(tab, context, active_tab)
    concat(SectionTabTag.new(self, tab, context, active_tab).to_html)
  end

  def bz_sidebar_nav
      module_item_id = params[:module_item_id]
      link = []
      if module_item_id
        outer_list = HtmlElement.new('ul')
        outer_list.id = 'bz-module-nav'
        previous_list = nil
        is_next = false
        @context.context_modules.each do |context_module|
          next if context_module.workflow_state != 'active'

          main_module_list_item = HtmlElement.new('li')
          module_list_item = main_module_list_item

          module_list_header = HtmlElement.new('span', module_list_item)
          module_list_header.add_class("bz-nav-module-name") 
          module_list_header.text_content = context_module.name

          module_list_stack = []

          current_indent = -1
          last_header_item = nil
          possible_items = context_module.content_tags_visible_to(@current_user)
          has_active = false
          last_item_element = main_module_list_item
          possible_items.each do |item|
            while item.indent > current_indent
              module_list_stack.push module_list_item
              module_list_item = HtmlElement.new('ul', last_item_element)
              current_indent+=1
            end
            while item.indent < current_indent
              module_list_item = module_list_stack.pop 
              last_item_element = module_list_item
              current_indent-=1
              last_header_item = nil # we went up a level, so no longer appropriate to copy links
            end

            item_element = HtmlElement.new('li', module_list_item)
            last_item_element = item_element
            item_element.add_class(item.content_type)

            liclass = ''
            if item.id.to_i == module_item_id.to_i
              item_element.add_class('active')
              parent = item_element.parent
              while(parent)
                parent.add_class('active-parent')
                parent = parent.parent
              end
              has_active = true
            end

            if item.content_type == 'ContextModuleSubHeader'
              a = HtmlElement.new('span', item_element)
              a.text_content = item.title
              last_header_item = a
            else
              a = HtmlElement.new('a', item_element)
              a.href = "/courses/#{item.context_id}/modules/items/#{item.id}"
              unless last_header_item.nil?
                last_header_item.tag_name = 'a'
                last_header_item.href = "/courses/#{item.context_id}/modules/items/#{item.id}"
                last_header_item = nil
              end
              a.add_class(liclass)
              a.text_content = item.title
            end
          end

          if is_next
            main_module_list_item.add_class('bz-next-module')
            main_module_list_item.simplify_for_nav
            outer_list.add_child(main_module_list_item)
            is_next = false
            break
          end

          # I only want to how the active module to keep
          # the nav from being overloaded for the uer
          if has_active
            unless previous_list.nil?
              previous_list.add_class('bz-previous-module')
              previous_list.simplify_for_nav
              outer_list.add_child(previous_list)
            end
            outer_list.add_child(main_module_list_item)
            is_next = true
          end

          previous_list = main_module_list_item
        end
        link << outer_list.to_html
      end
      link.join('')
  end

  class AvailableSectionTabs
    def initialize(context, current_user, domain_root_account, session)
      @context = context
      @current_user = current_user
      @domain_root_account = domain_root_account
      @session = session
    end
    attr_reader :context, :current_user, :domain_root_account, :session

    def to_a
      return [] unless context.respond_to?(:tabs_available)

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        new_collaborations_enabled = context.feature_enabled?(:new_collaborations) if context.respond_to?(:feature_enabled?)

        context.tabs_available(current_user, {
          session: session,
          root_account: domain_root_account
        }).select { |tab|
          tab_has_required_attributes?(tab)
        }.reject { |tab|
          if tab_is?(tab, 'TAB_COLLABORATIONS')
            new_collaborations_enabled ||
              !Collaboration.any_collaborations_configured?(@context)
          elsif tab_is?(tab, 'TAB_COLLABORATIONS_NEW')
            !new_collaborations_enabled
          elsif tab_is?(tab, 'TAB_CONFERENCES')
            !WebConference.config
          end
        }
      end
    end

    private
    def cache_key
      [ context, current_user, domain_root_account,
        Lti::NavigationCache.new(domain_root_account),
        "section_tabs_hash", I18n.locale, domain_root_account.feature_enabled?(:use_new_styles)
      ].cache_key
    end

    def tab_has_required_attributes?(tab)
      tab[:href] && tab[:label]
    end

    def tab_is?(tab, const_name)
      context.class.const_defined?(const_name) &&
        tab[:id] == context.class.const_get(const_name)
    end
  end

  class SectionTabTag
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def initialize(parent, tab, context, active_tab=nil)
      @tab = SectionTabPresenter.new(tab, context)
      @active_tab = active_tab

      @parent = parent
    end

    def a_classes
      [ @tab.css_class.downcase.replace_whitespace('-') ].tap do |a|
        a << 'active' if @tab.active?(@active_tab)
      end
    end

    def a_attributes
      { href: @tab.path,
        class: a_classes }.tap do |h|
        if @tab.screenreader?
          h[:'aria-label'] = @tab.screenreader
        end
      end
    end

    def a_tag
      content_tag(:a, a_attributes) do
        concat(@tab.label)
        concat(span_tag)

        if @tab.css_class.downcase == 'modules'
          concat(raw(@parent.bz_sidebar_nav))
        end
      end
    end

    def li_classes
      [ 'section' ].tap do |a|
        a << 'section-tab-hidden' if @tab.hide?
      end
    end

    def span_tag
      if @tab.hide?
        content_tag(:span, I18n.t('* No content has been added'), {
          id: 'inactive_nav_link',
          class: 'screenreader-only'
        })
      end
    end

    def to_html
      content_tag(:li, a_tag, {
        class: li_classes
      })
    end
  end
end
