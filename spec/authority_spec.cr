require "./helper"

module PlaceOS::Model
  Spec.before_each do
    Authority.clear
  end

  describe Authority do
    it "saves an Authority" do
      inst = Generator.authority.save!
      Authority.find!(inst.id.as(String)).id.should eq inst.id
    end

    it "only saves the domain's host" do
      authority = Authority.new
      authority.domain = "https://localhost:8080"
      authority.domain.should eq "localhost"
    end

    it "find_by_domain" do
      domain = "http://localhost:8080"
      authority = Generator.authority(domain).save!
      found = Authority.find_by_domain(domain)
      found.try(&.id).should eq authority.id
    end
  end
end
