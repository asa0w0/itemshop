export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route(
      "discourse-itemshop",
      { path: "itemshop" }
    );
  },
};
