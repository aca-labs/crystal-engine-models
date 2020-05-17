require "./helper"

module PlaceOS::Model
  describe DoorkeeperApplication do
    it "saves an app with a HTTP style" do
      app = DoorkeeperApplication.new
      app.name = "test"
      app.redirect_uri = "http://test.redirect.com.au/"

      begin
        app.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      app.persisted?.should be_true
      app.uid.should eq(Digest::MD5.hexdigest(app.redirect_uri.not_nil!))
    end

    it "saves an app with a random UID" do
      app = DoorkeeperApplication.new
      app.name = "test"
      app.redirect_uri = "appuri://test.redirect.com.au/"

      begin
        app.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      app.persisted?.should be_true
      app.uid.should_not eq(Digest::MD5.hexdigest(app.redirect_uri.not_nil!))
    end

    it "saves an app with a specified UID" do
      app = DoorkeeperApplication.new
      app.name = "test"
      app.redirect_uri = "http://test.redirect.com.au/"
      app.uid = "my-special-uid"

      begin
        app.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      app.persisted?.should be_true
      app.uid.should eq("my-special-uid")
    end
  end
end
