class Dhl::Tracking::Response
  include Dhl::Tracking::Helper

  attr_reader :raw_xml, :parsed_xml, :errors
  attr_reader , :weight_charge_tax

  def initialize(xml="")
    @raw_xml = xml
    @errors = []

    begin
      @parsed_xml = MultiXml.parse(xml)
    rescue MultiXml::ParseError => e
      @errors << e
      return self
    end

    if response_indicates_error?
      @error = case response_error_condition_code.to_s
      when "100"
        Dhl::Tracking::Upstream::ValidationFailureError.new(response_error_condition_data)
      when "111"
        Dhl::Tracking::Upstream::ParsinDataError.new(response_error_condition_data)
      else
        Dhl::Tracking::Upstream::UnknownError.new(response_error_condition_data)
      end
    else

      puts 'all is good'
    end
  end

  def error?
    !@errors.empty?
  end

  
  def all_awb_infos
    awb_infos.map do |m|
      Dhl::Tracking::Awbinfo.new(m)
    end.sort{|a,b| a.shipment_date <=> b.shipment_date }
  end

protected

  def awb_infos
    @awb_infos ||= begin
      srv = @parsed_xml["TrackingResponse"]
      a = []
      if srv.is_a? Array
        srv.each{|aa| a << aa["AWBInfo"]}
      else
        a << srv["AWBInfo"]
      end
      a.flatten
    end
      # @parsed_xml["DCTResponse"]["GetQuoteResponse"]["Srvs"]["Srv"]["MrkSrv"]
  end

end