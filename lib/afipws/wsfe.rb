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
      t = autenticar_y_tomar_array(:cbte_tipo) { |auth| @client.fe_param_get_tipos_cbte auth }
      parse t, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_documentos
      t = autenticar_y_tomar_array(:doc_tipo) { |auth| @client.fe_param_get_tipos_doc auth }
      parse t, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_monedas
      t = autenticar_y_tomar_array(:moneda) { |auth| @client.fe_param_get_tipos_monedas auth }
      parse t, :fch_desde => :date, :fch_hasta => :date
    end
    
    def cotizacion moneda_id
      c = autenticar { |auth| @client.fe_param_get_cotizacion auth.merge 'MonId' => moneda_id }
      parse c, :mon_cotiz => :float, :fch_cotiz => :date
    end

    private
    def autenticar
      @ta ||= @wsaa.login
      rta = yield 'Auth' => { 'Token' => @ta[:token], 'Sign' => @ta[:sign], 'Cuit' => cuit }
      rta[:result_get]
    end
    
    def autenticar_y_tomar_array array_element, &block
      response = autenticar &block
      Array.wrap response[array_element]
    end
    
    def parse array_o_hash, types
      case array_o_hash
      when Array then array_o_hash.map { |hash| parse hash, types }
      when Hash then Hash[array_o_hash.map { |k, v| [k, parsing_fn[types[k]].call(v)] }]
      else array_o_hash
      end
    end
    
    def parsing_fn
      @parsing ||= Hash.new(Proc.new { |other| other }).tap { |p|
        p[:date] = Proc.new { |date| ::Date.parse(date) rescue nil }
        p[:integer] = Proc.new { |integer| integer.to_i }
        p[:float] = Proc.new { |float| float.to_f }
      }
    end
  end
end
