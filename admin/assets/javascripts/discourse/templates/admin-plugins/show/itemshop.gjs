import RouteTemplate from "ember-route-template";
import AdminItemshop from "../../../../admin/components/admin-itemshop";

export default RouteTemplate(
  `<template>
    {{#if @controller.model}}
      <AdminItemshop @model={{@controller.model}} />
    {{else}}
      <p class="warning">Unable to load Itemshop data.</p>
    {{/if}}
   </template>`
);
