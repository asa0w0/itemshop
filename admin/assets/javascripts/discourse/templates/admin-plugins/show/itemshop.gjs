import RouteTemplate from "ember-route-template";
import AdminItemshop from "../../../../admin/components/admin-itemshop";

export default RouteTemplate(
  <template>
    <AdminItemshop @model={{@model}} />
  </template>
);
