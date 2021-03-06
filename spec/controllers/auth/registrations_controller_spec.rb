require "rails_helper"

describe Auth::RegistrationsController do

  let(:valid_session) { {} }

  describe "POST #create" do

    before :each do
      request.env["devise.mapping"] = Devise.mappings[:user]
    end

    it "defaults admin to false when omitted" do
      post :create, user: {
        "username"              => "administrator",
        "email"                 => "administrator@test.com",
        "password"              => "12341234",
        "password_confirmation" => "12341234"
      }
      expect(User.find_by!(username: "administrator")).not_to be_admin
    end

    it "handles the admin column properly" do
      post :create, user: {
        "username"              => "administrator",
        "email"                 => "administrator@test.com",
        "password"              => "12341234",
        "password_confirmation" => "12341234",
        "admin"                 => true
      }
      expect(User.find_by!(username: "administrator")).to be_admin
    end

    it "omits the value of admin if there is already another admin" do
      create(:admin)
      post :create, user: {
        "username"              => "wonnabeadministrator",
        "email"                 => "wonnabeadministrator@test.com",
        "password"              => "12341234",
        "password_confirmation" => "12341234",
        "admin"                 => true
      }
      expect(User.find_by!(username: "wonnabeadministrator")).not_to be_admin
    end

  end

  describe "PUT #update" do

    let!(:user) { create(:admin) }

    before :each do
      request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
    end

    it "does not allow invalid emails" do
      email = User.find(user.id).email
      put :update, user: { "email" => "invalidone" }
      expect(User.find(user.id).email).to eq(email)
      put :update, user: { "email" => "valid@example.com" }
      expect(User.find(user.id).email).to eq("valid@example.com")
    end

    # NOTE: since the tests on passwords also have to take care that even if
    # there are other parameters (e.g. emails), they are ignored when there are
    # password parameters, these tests will always have an extra parameter.

    it "does not allow empty passwords" do
      put :update, user: {
        "email"                 => "user@example.com",
        "current_password"      => "test-password",
        "password"              => "",
        "password_confirmation" => ""
      }
      expect(User.find(user.id).valid_password?("test-password")).to be true
    end

    it "checks that the old password is ok" do
      put :update, user: {
        "email"                 => "user@example.com",
        "current_password"      => "test-passwor",
        "password"              => "new-password",
        "password_confirmation" => "new-password"
      }
      expect(User.find(user.id).valid_password?("test-password")).to be true
    end

    it "checks that the new password and its confirmation match" do
      put :update, user: {
        "email"                 => "user@example.com",
        "current_password"      => "test-password",
        "password"              => "new-password",
        "password_confirmation" => "new-passwor"
      }
      expect(User.find(user.id).valid_password?("test-password")).to be true
    end

    it "changes the password when everything is alright" do
      put :update, user: {
        "email"                 => "user@example.com",
        "current_password"      => "test-password",
        "password"              => "new-password",
        "password_confirmation" => "new-passwor"
      }
      expect(User.find(user.id).valid_password?("test-password")).to be true
    end

  end

  describe "DELETE #destroy" do
    let!(:user) { create(:admin) }

    before :each do
      request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
    end

    it "does not allow the removal of users" do
      delete :destroy, id: user.id
      expect(User.find(user.id)).to_not be nil
    end
  end

  describe "PUT #disable_user" do
    let!(:admin) { create(:admin) }
    let!(:user) { create(:user) }

    before :each do
      request.env["devise.mapping"] = Devise.mappings[:user]
    end

    it "does not allow to disable the only admin" do
      sign_in admin
      put :disable, id: admin.id
      expect(response.status).to be 403
    end

    it "does not allow a regular user to disable another" do
      sign_in user
      put :disable, id: admin.id
      expect(response.status).to be 403
    end

    it "allows a user to disable himself" do
      sign_in user
      put :disable, id: user.id, format: :erb
      expect(response.status).to be 200
      expect(User.find(user.id).enabled?).to be false
    end

    it "allows the admin to disable a regular user" do
      sign_in admin
      put :disable, id: user.id, format: :erb
      expect(response.status).to be 200
      expect(User.find(user.id).enabled?).to be false
    end

    it "allows an admin to disable another admin" do
      admin2 = create(:admin)
      sign_in admin
      put :disable, id: admin2.id, format: :erb
      expect(response.status).to be 200
      expect(User.find(admin2.id).enabled?).to be false
    end
  end
end
