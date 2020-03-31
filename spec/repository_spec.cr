require "./helper"

module PlaceOS::Model
  describe Repository do
    it "saves a Repository" do
      repo = Generator.repository.save!
      Repository.find(repo.id.as(String)).should_not be_nil
    end
  end
end
