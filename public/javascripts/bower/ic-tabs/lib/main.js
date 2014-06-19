import TabComponent       from './tab';
import TabListComponent   from './tab-list';
import TabPanelComponent  from './tab-panel';
import TabsComponent      from './tabs';
import tabsCssTemplate    from './tabs-css';
import { Application }    from 'ember';

Application.initializer({
  name: 'ic-tabs',
  initialize: function(container) {
    container.register('component:ic-tab',       TabComponent);
    container.register('component:ic-tab-list',  TabListComponent);
    container.register('component:ic-tab-panel', TabPanelComponent);
    container.register('component:ic-tabs',      TabsComponent);
    container.register('template:components/ic-tabs-css', tabsCssTemplate);
  }
});

export {
  TabComponent,
  TabListComponent,
  TabPanelComponent,
  TabsComponent
};

