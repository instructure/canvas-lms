import $ from 'jquery';
import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView';
import FeatureFlagCollection from 'compiled/collections/FeatureFlagCollection';
import FeatureFlag from 'compiled/models/FeatureFlag';

let flags;

QUnit.module('FeatureFlagAdminView', {
  setup () {
    window.ENV.context_asset_string = 'user_1';
    flags = [
      new FeatureFlag({
        feature: 'high_constrast',
        id: 'high_constrast',
        display_name: 'High Contrast',
        appliesTo: 'user',
        feature_flag: {
          feature: 'high_constrast',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      }),
      new FeatureFlag({
        feature: 'underline_links',
        id: 'underline_links',
        display_name: 'Underline Links',
        appliesTo: 'user',
        feature_flag: {
          feature: 'underline_links',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      }),
      new FeatureFlag({
        feature: 'new_user_tutorial_on_off',
        id: 'new_user_tutorial_on_off',
        display_name: 'New User Tutorials',
        appliesTo: 'user',
        feature_flag: {
          feature: 'new_user_tutorial_on_off',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      })
    ];
  }
});

test('it does not render feature flags that are passed in via the hiddenFlags option', () => {
  const hiddenFlags = ['new_user_tutorial_on_off']

  const view = new FeatureFlagAdminView({
    el: '#fixtures',
    hiddenFlags
  });

  view.collection = new FeatureFlagCollection(flags)
  view.render();
  equal($('li.feature-flag').length, 2);
  equal($('.new_user_tutorial_on_off').length, 0);
});

test('it renders all feature flags if you do not pass a hiddenFlags option', () => {
  const view = new FeatureFlagAdminView({el: '#fixtures'});

  view.collection = new FeatureFlagCollection(flags)
  view.render();
  equal($('li.feature-flag').length, 3);
})
