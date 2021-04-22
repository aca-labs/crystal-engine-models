require "./helper"

module PlaceOS::Model
  describe Repository do
    it "saves a Repository" do
      repo = Generator.repository.save!
      Repository.find(repo.id.as(String)).should_not be_nil
    end

    describe "validation" do
      context "folder_name" do
        it "enforces valid path characters" do
          repo = Generator.repository

          repo.folder_name = "no spaces please"
          repo.valid?.should be_false
          repo.errors.first.to_s.should eq("folder_name is invalid")

          repo.errors.clear

          repo.folder_name = "no_spaces_here"
          repo.valid?.should be_true
        end
      end
      context "url" do
        it "ensures scheme is present" do
          repo = Generator.repository

          repo.uri = "iqoherlk9dgaJUNK"
          repo.valid?.should be_false
          repo.errors.first.to_s.should eq("uri is an invalid URI")
          repo.errors.clear

          repo.uri = "https://good.stuff"
          repo.valid?.should be_true
        end
      end
    end

    it "removes dependent Drivers on destroy" do
      repo = Generator.repository(type: Repository::Type::Driver).save!

      drivers = 3.times.to_a.map {
        Generator.driver(repo: repo).save!
      }

      Repository.find(repo.id.as(String)).should_not be_nil
      repo.destroy
      Driver.find_all(drivers.compact_map &.id).to_a.should be_empty
    end
  end
end
