require "../helper"

module Engine::Model
  describe AdfsStrat do
    it "saves a AdfsStrat" do
      strat = Generator.adfs_strat.save!
      AdfsStrat.find(strat.id).should_not be_nil
    end
  end
end
