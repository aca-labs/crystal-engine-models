require "./helper"

module PlaceOS::Model
  describe Module do
    describe "persistence" do
      Driver::Role.values.each do |role|
        it "saves a #{role} module" do
          driver = Generator.driver(role: role)
          mod = Generator.module(driver: driver).save!
          mod.persisted?.should be_true
        end
      end
    end

    describe "merge_settings" do
      it "obeys logic module settings hierarchy" do
        driver = Generator.driver(role: Driver::Role::Logic).save!
        driver_settings_string = %(value: 0\nscreen: 0\nfrangos: 0\nchop: 0)
        driver_settings = Generator.settings(driver: driver, settings_string: driver_settings_string).save!

        control_system = Generator.control_system.save!
        control_system_settings_string = %(frangos: 1)
        control_system_settings = Generator.settings(control_system: control_system, settings_string: control_system_settings_string).save!

        zone = Generator.zone.save!
        zone_settings_string = %(screen: 1)
        zone_settings = Generator.settings(zone: zone, settings_string: zone_settings_string).save!

        control_system.zones = [zone.id.as(String)]
        control_system.update!

        mod = Generator.module(driver: driver, control_system: control_system)
        mod.save!

        module_settings_string = %(value: 2\n)
        module_settings = Generator.settings(mod: mod, settings_string: module_settings_string).save!

        merged_settings = JSON.parse(mod.merge_settings).as_h.transform_values { |v| v.as_i }

        # Module > Driver
        merged_settings["value"].should eq 2
        # Module > Zone > Driver
        merged_settings["screen"].should eq 1
        # Module > ControlSystem > Driver
        merged_settings["frangos"].should eq 1
        # Driver
        merged_settings["chop"].should eq 0

        {driver, zone, control_system, mod}.each &.destroy
        {control_system_settings, driver_settings, module_settings, zone_settings}.each do |setting|
          Settings.find(setting.id.as(String)).should be_nil
        end
      end

      it "obeys driver-module settings hierarchy" do
        driver = Generator.driver(role: Model::Driver::Role::Service).save!
        driver_settings_string = %(value: 0\nscreen: 0\nfrangos: 0\nchop: 0)
        driver_settings = Generator.settings(driver: driver, settings_string: driver_settings_string).save!

        control_system = Generator.control_system.save!
        control_system_settings_string = %(frangos: 1)
        control_system_settings = Generator.settings(control_system: control_system, settings_string: control_system_settings_string).save!

        zone = Generator.zone.save!
        zone_settings_string = %(screen: 1)
        zone_settings = Generator.settings(zone: zone, settings_string: zone_settings_string).save!

        control_system.zones = [zone.id.as(String)]
        control_system.update!

        mod = Generator.module(driver: driver, control_system: control_system).save!

        module_settings_string = %(value: 2\n)
        module_settings = Generator.settings(mod: mod, settings_string: module_settings_string).save!

        merged_settings = JSON.parse(mod.merge_settings).as_h.transform_values { |v| v.as_i }

        # Module > Driver
        merged_settings["value"].should eq 2
        # Module > Driver
        merged_settings["screen"].should eq 0
        # Module > Driver
        merged_settings["frangos"].should eq 0
        # Driver
        merged_settings["chop"].should eq 0

        {driver, zone, control_system, mod}.each &.destroy
        {control_system_settings, driver_settings, module_settings, zone_settings}.each do |setting|
          Settings.find(setting.id.as(String)).should be_nil
        end
      end
    end
  end
end
