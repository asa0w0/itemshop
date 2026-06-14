import RouteTemplate from "ember-route-template";
import ItemshopShop from "../components/itemshop-shop";

export default RouteTemplate(
  <template><ItemshopShop @model={{@controller.model}} /></template>
);
