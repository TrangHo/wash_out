xml.instruct!
xml.definitions 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @name,
                'targetNamespace' => @namespace do

  xml.types do
    xml.tag! "schema", :targetNamespace => @namespace, :xmlns => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        (formats[:in] + formats[:out]).each do |p|
          wsdl_type xml, p, defined
        end
      end
    end
  end

  xml.portType :name => "#{@name}_port" do
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}"
        xml.output :message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"
      end
    end
  end

  xml.binding :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
    xml.tag! "soap:binding", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.tag! "soap:operation", :soapAction => @map[operation][:action_name]
        xml.input do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
        xml.output do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
      end
    end
  end

  xml.service :name => "service" do
    xml.port :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :location => send("#{@name}_action_url")
    end
  end

  @map.each do |operation, formats|
    xml.message :name => "#{operation}" do
      formats[:in].each do |p|
        xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.message :name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}" do
      formats[:out].each do |p|
        xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
  end
end
