define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jquery',
  'jsx/shared/modal',
  'jsx/theme_editor/SaveThemeButton',
  'jquery.ajaxJSON'
], (React, ReactDOM, TestUtils, jQuery, Modal, SaveThemeButton) => {

  let elem, props

  const isType = (type) => (child) => child.type === type

  QUnit.module('SaveThemeButton Component', {
    setup () {
      elem = document.createElement('div')
      props = {
        accountID: 'account123',
        brandConfigMd5: '00112233445566778899aabbccddeeff',
        sharedBrandConfigBeingEdited: {
          id: 321,
          account_id: 123,
          brand_config: {
            md5: '00112233445566778899aabbccddeeff',
            variables: {
              'some-var': '#123'
            }
          }
        },
        onSave: sinon.stub()
      }
    }
  })

  asyncTest('save', function () {
    let component = ReactDOM.render(<SaveThemeButton {...props} />, elem)
    const updatedBrandConfig = {}
    this.stub(jQuery, 'ajaxJSON').callsArgOnWith(3, component, updatedBrandConfig)
    this.spy(component, 'setState')
    component.save()
    ok(
      jQuery.ajaxJSON.calledWithMatch(props.accountID, 'PUT'),
      'makes a put request with the correct account id'
    )
    ok(
      component.setState.calledWithMatch({modalIsOpen: false}),
      'closes modal'
    )
    ok(
      props.onSave.calledWith(updatedBrandConfig),
      'calls onSave with updated config'
    )

    delete props.sharedBrandConfigBeingEdited
    component = ReactDOM.render(<SaveThemeButton {...props} />, elem)
    jQuery.ajaxJSON.reset()
    component.save()
    ok(component.setState.calledWithMatch({modalIsOpen: true}), 'opens modal')
    notOk(jQuery.ajaxJSON.called, 'does not make a request')

    component.setState({newThemeName: 'theme name'}, () => {
      component.save()
      ok(
        jQuery.ajaxJSON.calledWithMatch(props.accountID, 'POST'),
        'makes a post request with the correct account id'
      )
      start()
    })
  })

  test('modal visibility', function () {
    let shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton {...props} />)
    let modal = shallowRenderer.getRenderOutput().props.children.filter(child => {
      return child.type == Modal
    })[0]
    ok(modal, 'renders a modal')
    notOk(modal.props.isOpen, 'modal is closed')

    this.stub(SaveThemeButton.prototype, 'getInitialState').returns({
      ...SaveThemeButton.prototype.getInitialState(),
      modalIsOpen: true
    })
    shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton {...props} />)
    modal = shallowRenderer.getRenderOutput().props.children.find(isType(Modal))
    ok(modal.props.isOpen, 'modal is open')
  })

  test('disabling button', () => {
    const shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton {...props} />)
    const button = shallowRenderer.getRenderOutput().props.children.find(isType('button'))
    equal(button.props.disabled, false, 'not disabled by default')
  })

  test('disabling button: disabled if userNeedsToPreviewFirst', () => {
    const shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton {...props} userNeedsToPreviewFirst={true} />)
    const button = shallowRenderer.getRenderOutput().props.children.find(isType('button'))
    ok(button.props.disabled)
  })

  test('disabling button: disabled if there are no unsaved changes', () => {
    const shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton
      {...props}
      brandConfigMd5={props.sharedBrandConfigBeingEdited.brand_config_md5}
    />)
    const button = shallowRenderer.getRenderOutput().props.children.find(isType('button'))
    ok(button.props.disabled)
  })

  test('disabling button: disabled if everything is default', () => {
    const shallowRenderer = TestUtils.createRenderer()
    shallowRenderer.render(<SaveThemeButton
      {...props}
      brandConfigMd5={null}
    />)
    const button = shallowRenderer.getRenderOutput().props.children.find(isType('button'))
    ok(button.props.disabled)
  })


})

