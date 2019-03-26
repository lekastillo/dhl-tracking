require 'rubygems'
require 'httparty'
require 'erb'
require 'set'

class Dhl::Tracking::Request
  attr_reader :site_id, :password
  attr_accessor :requested_all_check_point, :language, :awb_number, :pieces_enable

  URLS = {
    :production => 'https://xmlpi-ea.dhl.com/XMLShippingServlet',
    :test       => 'https://xmlpitest-ea.dhl.com/XMLShippingServlet'
  }

  def initialize(options = {})
    @test_mode = !!options[:test_mode] || Dhl::Tracking.test_mode?

    @site_id = options[:site_id] || Dhl::Tracking.site_id
    @password = options[:password] || Dhl::Tracking.password

    [ :site_id, :password ].each do |req|
      unless instance_variable_get("@#{req}").to_s.size > 0
        raise Dhl::Tracking::OptionsError, ":#{req} is a required option"
      end
    end

    @requested_all_check_point = true
    @language = 'es'
    @pieces_enable = 'S'

  end

  def test_mode?
    !!@test_mode
  end

  def test_mode!
    @test_mode = true
  end

  def production_mode!
    @test_mode = false
  end

  def request_all_check_point!
    @requested_all_check_point = true
  end
  
  def not_request_all_check_point!
    @requested_all_check_point = false
  end

  def requested_pickup_time?
    !!@requested_all_check_point
  end
  
  def to_xml
    validate!
    @to_xml = ERB.new(File.new(xml_template_path).read, nil,'%<>-').result(binding)
  end

  # # ready times are only 8a-5p(17h)
  # def ready_time(time=Time.now)
  #   if time.hour >= 17 || time.hour < 8
  #     time.strftime("PT08H00M")
  #   else
  #     time.strftime("PT%HH%MM")
  #   end
  # end

  # # ready dates are only mon-fri
  # def ready_date(t=Time.now)
  #   date = Date.parse(t.to_s)
  #   if (date.cwday >= 6) || (date.cwday >= 5 && t.hour >= 17)
  #     date.send(:next_day, 8-date.cwday)
  #   else
  #     date
  #   end.strftime("%Y-%m-%d")
  # end

  def post
    response = HTTParty.post(servlet_url,
      :body => to_xml,
      :headers => { 'Content-Type' => 'application/xml' }
    ).response

    return Dhl::Tracking::Response.new(response.body)
  rescue Exception => e
    request_xml = if @to_xml.to_s.size>0
      @to_xml
    else
      '<not generated at time of error>'
    end

    response_body = if (response && response.body && response.body.to_s.size > 0)
      response.body
    else
      '<not received at time of error>'
    end

    log_level = if e.respond_to?(:log_level)
      e.log_level
    else
      :critical
    end

    log_request_and_response_xml(log_level, e, request_xml, response_body )
    raise e
  end


protected

  def servlet_url
    test_mode? ? URLS[:test] : URLS[:production]
  end

  def validate!
    raise Dhl::Tracking::IwbNumberNotSetError, "#from() is not set" unless !(@awb_number)
  end

  def xml_template_path
    spec = Gem::Specification.find_by_name("dhl-tracking")
    gem_root = spec.gem_dir
    gem_root + "/tpl/request.xml.erb"
  end

private

  def deprication_notice(meth, m)
    messages = {
      :metric => "Method replaced by Dhl::Tracking::Request#metic_measurements!(). I am now setting your measurements to metric",
      :us     => "Method replaced by Dhl::Tracking::Request#us_measurements!(). I am now setting your measurements to US customary",
    }
    puts "!!!! Method \"##{meth}()\" is depricated. #{messages[m.to_sym]}."
  end

  def log_request_and_response_xml(level, exception, request_xml, response_xml)
    log_exception(exception, level)
    log_request_xml(request_xml, level)
    log_response_xml(response_xml, level)
  end

  def log_exception(exception, level)
    log("Exception: #{exception}", level)
  end

  def log_request_xml(xml, level)
    log("Request XML: #{xml}", level)
  end

  def log_response_xml(xml, level)
    log("Response XML: #{xml}", level)
  end

  def log(msg, level)
    Dhl::Tracking.log(msg, level)
  end

end
