require "./helper"

module PlaceOS::Model
  describe Repository do
    it "saves a Repository" do
      repo = Generator.repository.save!
      Repository.find(repo.id.as(String)).should_not be_nil
    end

    it "removes dependent Drivers on destroy" do
      repo = Generator.repository(type: Repository::Type::Driver).save!

      drivers = 3.times.to_a.map {
        Generator.driver(repo: repo).save!
      }

      Repository.find(repo.id.as(String)).should_not be_nil
      repo.destroy
      Driver.get_all(drivers.compact_map { |d| d.id }).to_a.should be_empty
    end
  end
end
