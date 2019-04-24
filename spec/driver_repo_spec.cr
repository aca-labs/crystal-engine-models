require "./helper"

module Engine::Model
  describe DriverRepo do
    it "saves a DriverRepo" do
      repo = Generator.driver_repo.save!
      DriverRepo.find(repo.id).should_not be_nil
    end
  end
end
