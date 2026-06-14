import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import EmberObject from "@ember/object";

export default class DiscourseItemshopRoute extends DiscourseRoute {
  model() {
    if (!this.currentUser?.admin) {
      return { rewards: [], redemptions: [] };
    }

    return Promise.all([
      ajax("/admin/plugins/itemshop/rewards.json"),
      ajax("/admin/plugins/itemshop/redemptions.json")
    ]).then(([rewards, redemptions]) => {
      return EmberObject.create({
        rewards: rewards,
        redemptions: redemptions
      });
    });
  }
}
