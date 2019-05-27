require "../helper"

module Engine::Model
  describe OauthStrat do
    it "saves a OauthStrat" do
      strat = Generator.oauth_strat.save!
      OauthStrat.find(strat.id).should_not be_nil
    end
  end
end
