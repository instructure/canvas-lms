define([
  'react',
  'jquery',
  'jsx/theme_editor/CollectionView',
  'jsx/theme_editor/ThemeCard',
  'jquery.ajaxJSON'
], (React, jQuery, CollectionView, ThemeCard) => {

  let elem, props

  module('CollectionView', {
    setup () {
      elem = document.createElement('div')
      props = {
        sharedBrandConfigs: [{
          account_id: 123,
          name: 'Account-shared Theme',
          id: 123,
          brand_config: {
            md5: '00112233445566778899aabbccddeeff',
            variables: {
              'foo': '#123'
            }
          }
        }],
        activeBrandConfig: {
          md5: '00112233445566778899aabbccddeeff',
          variables: [{}]
        },
        accountID: 'account123',
        brandableVariableDefaults: {
          foo: {
            default: '#321',
            type: 'color',
            variable_name: 'foo'
          },
          otherFoo: {
            default: '$foo',
            type: 'color',
            ovariable_name: 'Other Foo'
          }
        }
      }
    }
  })

  test('brandVariableValue',  function () {
    const c = new CollectionView(props)
    equal(
      c.brandVariableValue({variables: {foo: 'bar'}}, 'foo'),
      'bar',
      'returns explicit values from the brand config'
    )

    this.spy(c, 'brandVariableValue')
    const config = {variables: {}}
    c.brandVariableValue(config, 'otherFoo')
    ok(
      c.brandVariableValue.calledWith(config, 'foo'),
      'gets value for variable name'
    )

    equal(
      c.brandVariableValue(config, 'foo'),
      props.brandableVariableDefaults.foo.default,
      'gets default value'
    )

    const shared = props.sharedBrandConfigs[0].brand_config
    config.parent_md5 = shared.md5
    equal(
      c.brandVariableValue(config, 'foo'),
      shared.variables.foo,
      'get value from parent'
    )
  })

  test('startEditing: from scratch',  function () {
    // chrome doesn't let you stub window.sessionStorage.removeItem so we just have to check manually
    window.sessionStorage.setItem('sharedBrandConfigBeingEdited', 'blah')

    this.stub(jQuery.fn, 'submit') // prevent reloading the page :(
    new CollectionView(props).startEditing({md5ToActivate: 'junk2c3d4e5f67890a1b2c3d4e5f6789'})
    equal(window.sessionStorage.getItem('sharedBrandConfigBeingEdited'), null,
      'removes sharedBrandConfigBeingEdited from session store'
    )
  })

  test('startEditing: working on existing saved theme',  function () {
    window.sessionStorage.removeItem('sharedBrandConfigBeingEdited')
    this.stub(jQuery.fn, 'submit') // prevent reloading the page :(

    new CollectionView(props).startEditing({
      mdd5ToActivate: 'junk2c3d4e5f67890a1b2c3d4e5f6789',
      sharedBrandConfigToStartEditing: {foo: 'bar'}
    })
    equal(window.sessionStorage.getItem('sharedBrandConfigBeingEdited'), '{"foo":"bar"}',
      'sets json encoded brand config in the session store'
    )
  })

  test('deteteSharedBrandConfig', function () {
    const id = 'abc123'
    this.mock(jQuery).expects('ajaxJSON').withArgs(`/api/v1/shared_brand_configs/${id}`, 'DELETE')
    const c = new CollectionView(props)
    c.deleteSharedBrandConfig(id)
  })

  test('isActiveBrandConfig',  function () {
    let c = new CollectionView(props)
    ok(
      c.isActiveBrandConfig({md5: props.activeBrandConfig.md5}),
      'true when called with a config with the same md5 as the active config'
    )
    notOk(
      c.isActiveBrandConfig({md5: 'foo'}),
      'false when called with a config with a md5 different from the active config'
    )
    delete props.activeBrandConfig
    c = new CollectionView(props)
    notOk(
      c.isActiveBrandConfig({md5: 'foo'}),
      'false when there is no active brand config'
    )
  })

  test('isDeletable', function () {
    const c = new CollectionView(props)
    const config = props.sharedBrandConfigs[0]
    config.account_id = 'different'
    config.md5 = 'different'
    notOk(
      c.isDeletable(config),
      'false if config has a different account id'
    )

    config.account_id = props.accountID
    config.brand_config.md5 = props.activeBrandConfig.md5
    notOk(
      c.isDeletable(config),
      'false if it is the active brand config'
    )

    config.brand_config.md5 = 'different'
    ok(
      c.isDeletable(config),
      'true if not active and has the same account id'
    )
  })

  test('thingsToShow always includes the active theme', function ()  {
    let c = new CollectionView(props)
    equal(
      c.thingsToShow().accountSpecificThemes.length,
      props.sharedBrandConfigs.length,
      'does not add a brand config if the active brand config is in shared configs'
    )
    props.activeBrandConfig.md5 = 'different'

    c = new CollectionView(props)
    equal(
      c.thingsToShow().accountSpecificThemes.length,
      props.sharedBrandConfigs.length + 1,
      'adds a brand config if the active brand config is in shared configs'
    )
  })

  test('thingsToShow includes a default global theme', function () {
    let c = new CollectionView(props)
    ok(
      c.thingsToShow().globalThemes.filter(t => t.name === 'Default Template')[0],
      'has default template in global themes'
    )
  })

  test('thingsToShow groups themes with the same account id as account specific', () => {
    props.sharedBrandConfigs.forEach(bc => bc.account_id == props.accountID)
    let c = new CollectionView(props)
    equal(
      c.thingsToShow().accountSpecificThemes.length,
      props.sharedBrandConfigs.length,
      'accountSpecificThemes has the expected number of themes'
    )
  })

  test('thingsToShow groups themes with different account id as global', function () {
    props.sharedBrandConfigs.forEach(bc => bc.account_id == 'otheraccount')
    let c = new CollectionView(props)
    equal(
      c.thingsToShow().globalThemes.length,
      props.sharedBrandConfigs.length,
      'global themeses has the expected number of themes'
    )
  })

  test('thingsToShow returns the active brand config first', function () {
    let c = new CollectionView(props)
    props.sharedBrandConfigs.account_id = props.accountID
    props.sharedBrandConfigs.unshift({
      account_id: props.accountID,
      brand_config: {
        md5: 'other',
        variables: {}
      }
    })
    equal(
      c.thingsToShow().accountSpecificThemes[0],
      props.sharedBrandConfigs[1],
      'active brand config is first'
    )
  })

  test('renderCard renders a ThemeCard', function () {
    const c = new CollectionView(props)
    const config = {
      name: 'Test Theme',
      id: 123,
      brand_config: {}
    }
    const card = c.renderCard(config)
    equal(card.type, ThemeCard, 'returns a theme card')
    equal(card.props.name, config.name, 'passes name prop')
  })

  test('renderCard properly indicates which theme is active', function () {
    const systemTheme = {
      account_id: null, // system themes have a 'null' account_id
      name: 'System-shared Theme',
      brand_config: {
        md5: '00112233445566778899aabbccddeeff', // its md5 matches the "activeBrandConfig"
        variables: {}
      }
    }
    props.sharedBrandConfigs.unshift(systemTheme)

    const c = new CollectionView(props)

    ok(
      c.renderCard(props.sharedBrandConfigs[1]).props.isActiveBrandConfig,
      'Account-shared Theme is marked active since its md5 matches'
    )

    notOk(
      c.renderCard(props.sharedBrandConfigs[0]).props.isActiveBrandConfig,
      'does not mark system theme as active if there is an active account theme too'
    )
  })
})

