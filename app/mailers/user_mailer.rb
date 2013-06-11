class UserMailer < ActionMailer::Base
  include SendGrid
  include Resque::Mailer
  
  default from: "from@example.com"
end
