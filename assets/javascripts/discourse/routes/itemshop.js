import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class ItemshopRoute extends DiscourseRoute {
  @service router;

  model() {
    return ajax("/itemshop.json")
      .then((response) => response)
      .catch(() => this.router.replaceWith("/404"));
  }
}
