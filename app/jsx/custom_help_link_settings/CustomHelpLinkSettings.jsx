define([
  'react',
  'i18n!custom_help_link',
  'jquery',
  './CustomHelpLinkIcons',
  './CustomHelpLink',
  './CustomHelpLinkForm',
  './CustomHelpLinkMenu',
  './CustomHelpLinkPropTypes',
  './CustomHelpLinkConstants',
  'compiled/jquery.rails_flash_notifications'
], function(
    React,
    I18n,
    jquery,
    CustomHelpLinkIcons,
    CustomHelpLink,
    CustomHelpLinkForm,
    CustomHelpLinkMenu,
    CustomHelpLinkPropTypes,
    CustomHelpLinkConstants
  ) {

  let counter = 0; // counter to ensure unique ids for links

  const CustomHelpLinkSettings = React.createClass({
    propTypes: {
      name: React.PropTypes.string,
      links: React.PropTypes.arrayOf(CustomHelpLinkPropTypes.link),
      defaultLinks: React.PropTypes.arrayOf(CustomHelpLinkPropTypes.link),
      icon: React.PropTypes.string
    },
    getDefaultProps () {
      return {
        name: I18n.t('Help'),
        icon: 'questionMark',
        links: []
      };
    },
    getInitialState () {
      // set ids to the original index so that we can have unique keys
      const links = this.props.links.map((link) => {
        counter++;

        return {
          ...link,
          id: 'link' + counter,
          available_to: link.available_to || [],
          state: link.state || 'active'
        }
      });

      return {
        links,
        editing: null // id of link that is being edited
      };
    },
    getDefaultLinks () {
      const linkTexts = this.state.links.map(link => link.text);

      return this.props.defaultLinks.map((link) => {
        return {
          ...link,
          is_disabled: linkTexts.indexOf(link.text) > -1
        };
      });
    },

    // define handlers here so that we don't create one for each render
    handleMoveUp (link) {
      this.move(link, -1);
    },
    handleMoveDown (link) {
      this.move(link, 1, this.focus.bind(this, link.id));
    },
    handleEdit (link) {
      this.edit(link);
    },
    handleRemove (link) {
      this.remove(link);
    },
    handleAdd (link) {
      this.add(link);
    },
    handleFormSave (link) {
      if (this.validate(link)) {
        this.update(link);
      }
    },
    handleFormCancel (link) {
      if (link.text) {
        this.cancelEdit(link);
      } else {
        this.remove(link);
      }
    },

    nextFocusable (start) {
      const links = this.state.links;

      const nextIndex = function (i) {
        return (i < links.length - 1) ? i + 1 : 0;
      }

      let focusable;
      let index = nextIndex(start);

      while (!focusable && index !== start) {
        const id = links[index].id

        if (this.links[id].focusable()) {
          focusable = id;
        }

        index = nextIndex(index);
      }

      return focusable || 'addLink'
    },

    focus (linkId, action) {
      const link = this.links[linkId];

      link.focus(action);
    },
    cancelEdit (link) {
      this.setState({
        editing: null
      }, this.focus.bind(this, link.id, 'edit'));
    },
    edit (link) {
      this.setState({
        editing: link.id
      }, this.focus.bind(this, link.id));
    },
    add (link) {
      counter++;

      const links = [...this.state.links];
      const id = 'link' + counter;

      links.splice(0, 0, {
        ...link,
        state: (link.type === 'default') ? link.state : 'new',
        id: id,
        type: link.type || 'custom'
      });

      this.setState({
        links,
        editing: (link.type === 'default') ? this.state.editing : id
      }, this.focus.bind(this, id));
    },
    update (link) {
      const links = [...this.state.links];

      links[link.index] = {
        ...link,
        state: (link.text) ? 'active' : link.state
      };

      this.setState({
        links,
        editing: null
      }, this.focus.bind(this, link.id, 'edit'));
    },
    remove (link) {
      const links = [...this.state.links];
      const editing = this.state.editing;

      links.splice(link.index, 1);

      this.setState({
        links,
        editing: (editing === link.id) ? null : editing
      }, this.focus.bind(this, this.nextFocusable(link.index)));
    },
    move (link, change) {
      const links = [...this.state.links];

      links.splice(link.index + change, 0, links.splice(link.index, 1)[0]);

      this.setState({
        links: links
      });
    },

    validate (link) {
      if (!link.text) {
        $.flashError(I18n.t('Please enter a name for this link.'));
        return false;
      } else if (!link.url || !/((http|ftp)s?:\/\/)|(tel\:)|(mailto\:).+/.test(link.url) ) {
        $.flashError(I18n.t('Please enter a valid URL. Protocol is required (e.g. http://, https://, ftp://, tel:, mailto:).'));
        return false;
      } else if (!link.available_to || link.available_to.length < 1) {
        $.flashError(I18n.t('Please select a user role for this link.'))
        return false;
      } else {
        return true;
      }
    },

    renderForm (link) {
      return (
        <CustomHelpLinkForm
          ref={(c) => this.links[link.id] = c}
          key={link.id}
          link={link}
          onSave={this.handleFormSave}
          onCancel={this.handleFormCancel}
        />
      );
    },
    renderLink (link) {
      const { links } = this.state;
      const { index, type, text, id } = link;
      const nextLink = links[index+1];
      return (
        <CustomHelpLink
          ref={(c) => this.links[link.id] = c}
          key={id}
          link={link}
          onMoveUp={index === 0 ? null : this.handleMoveUp}
          onMoveDown={index === links.length - 1 ? null : this.handleMoveDown}
          onRemove={this.handleRemove}
          onEdit={type === 'default' ? null : this.handleEdit}
        />
      );
    },
    render () {
      const {
        name,
        icon
      } = this.props;

      this.links = {};

      return (
        <fieldset>
          <legend>{ I18n.t('Help menu options') }</legend>
          <div className="ic-Form-group ic-Form-group--horizontal">
            <label className="ic-Form-control">
              <span className="ic-Label">
                { I18n.t('Name') }
              </span>
              <input type="text"
                className="ic-Input"
                required
                aria-required="true"
                name="account[settings][help_link_name]"
                defaultValue={name} />
            </label>
            <CustomHelpLinkIcons defaultValue={icon} />
            <div className="ic-Form-control ic-Form-control--top-align-label">
              <span className="ic-Label">
                { I18n.t('Help menu links') }
              </span>
              <div className="ic-Forms-component">
                { this.state.links.length > 0 ? (
                  <ol className="ic-Sortable-list">
                    {
                      this.state.links.map((link, index) => {
                        const linkWithIndex = {
                          ...link,
                          index: index // this is needed for moving up/down
                        }
                        return (linkWithIndex.id === this.state.editing) ?
                          this.renderForm(linkWithIndex) :
                          this.renderLink(linkWithIndex);
                      })
                    }
                  </ol>
                  ) : (
                    <span>
                      <input type="hidden" name="account[custom_help_links][0][text]" value="" />
                      <input type="hidden" name="account[custom_help_links][0][state]" value="deleted" />
                    </span>
                  )
                }
                <div className="ic-Sortable-list-add-new">
                  <CustomHelpLinkMenu
                    ref={(c) => this.links.addLink = c}
                    links={this.getDefaultLinks()}
                    onChange={this.handleAdd}
                  />
                </div>
              </div>
            </div>
          </div>
        </fieldset>
      );
    }
  });

  return CustomHelpLinkSettings;
});
