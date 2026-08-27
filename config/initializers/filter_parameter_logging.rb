# Never log these, and never send them to AppSignal.
Rails.application.config.filter_parameters += %i[
  passw email secret token _key crypt salt certificate otp ssn phone address
]
