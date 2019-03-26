class Dhl
  class Tracking
    VERSION = "0.1"

    PostInstallMessage = <<EOS

*** NOTE Dhl-Tracking ***

This version introduces the following changes from 0.1:

* Logging of request and response in the event of an error
* Logging levels and logging method can be set
EOS
  end
end
