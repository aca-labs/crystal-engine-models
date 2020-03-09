require "./helper"

module PlaceOS::Model
  describe Authority do
    it "saves an Authority" do
      inst = Generator.authority.save!
      Authority.find!(inst.id).id.should eq inst.id
    end

    it "find_by_domain" do
      domain = "#{Faker::Hacker.noun}-#{Faker::Hacker.noun}"
      authority = Generator.authority(domain).save!
      found = Authority.find_by_domain(authority.domain)
      found.try(&.id).should eq authority.id
    end
  end
end
