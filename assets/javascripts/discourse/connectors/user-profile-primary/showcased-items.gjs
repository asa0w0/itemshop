import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ShowcasedItems extends Component {
  get items() {
    return this.args.outletArgs?.model?.showcased_items || [];
  }

  <template>
    {{#if this.items.length}}
      <div class="user-profile-showcase-panel">
        <h3 class="showcase-title">{{icon "images"}} Vitrine</h3>
        <div class="showcase-grid">
          {{#each this.items as |item|}}
            <div class="showcase-item-card rarity-{{item.reward.rarity}}" title="{{item.reward.name}}: {{item.reward.description}}">
              <div class="showcase-icon-wrapper">
                {{icon item.reward.icon}}
              </div>
              <div class="showcase-item-info">
                <span class="showcase-item-name">{{item.reward.name}}</span>
                <span class="showcase-rarity-badge rarity-{{item.reward.rarity}}">
                  {{i18n (concat "itemshop.shop.rarity_" item.reward.rarity)}}
                </span>
              </div>
            </div>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
