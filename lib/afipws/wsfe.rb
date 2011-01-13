module Afipws
  class WSFE
    attr_reader :cuit, :wsaa, :ta
    
    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = options[:wsaa] || WSAA.new(options.merge(:service => 'wsfe'))
      @client = Client.new "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
    end
    
    def dummy
      @client.fe_dummy
    end
    
    def tipos_comprobantes
      autenticar_y_tomar_array(:cbte_tipo) { |auth| @client.fe_param_get_tipos_cbte auth }
    end
    
    def tipos_documentos
      autenticar_y_tomar_array(:doc_tipo) { |auth| @client.fe_param_get_tipos_doc auth }
    end

    def login
      # TODO ver el tema de expiracion del token
      @ta ||= @wsaa.login
    end
    
    private
    def autenticar
      ta = login
      yield 'Auth' => { 'Token' => ta[:token], 'Sign' => ta[:sign], 'Cuit' => cuit }
    end
    
    def autenticar_y_tomar_array array_element, &block
      response = autenticar &block
      array = Array.wrap response[:result_get][array_element]
      parse array, :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def parse array, types
      array.map { |hash| Hash[hash.map { |k, v| [k, parsing_fn[types[k]].call(v)] }] }
    end
    
    def parsing_fn
      @parsing ||= Hash.new(Proc.new { |other| other }).tap { |p|
        p[:date] = Proc.new { |date| ::Date.parse(date) rescue nil }
        p[:integer] = Proc.new { |integer| integer.to_i }
      }
    end
  end
end
