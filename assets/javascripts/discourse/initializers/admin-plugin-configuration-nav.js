import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "itemshop-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser || !currentUser.admin) {
      return;
    }

    withPluginApi("1.1.0", (api) => {
      api.addAdminPluginConfigurationNav("itemshop", [
        {
          label: "itemshop.admin.title",
          route: "adminPlugins.show.itemshop",
        },
      ]);
    });
  },
};
