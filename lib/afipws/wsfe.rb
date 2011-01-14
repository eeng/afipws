module Afipws
  class WSFE
    extend Forwardable
    attr_reader :wsaa
    def_delegators :wsaa, :ta, :auth, :cuit

    WSDL = {
      :dev => "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL",
      :test => Root + '/spec/fixtures/wsfe.wsdl'
    }
    
    def initialize options = {}
      @wsaa = options[:wsaa] || WSAA.new(options.merge(:service => 'wsfe'))
      @client = Client.new WSDL[options[:env] || :test]
    end
    
    def dummy
      @client.fe_dummy
    end
    
    def tipos_comprobantes
      r = @client.fe_param_get_tipos_cbte auth
      parse get_array(r, :cbte_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_documentos
      r = @client.fe_param_get_tipos_doc auth
      parse get_array(r, :doc_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_monedas
      r = @client.fe_param_get_tipos_monedas auth
      parse get_array(r, :moneda), :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_iva
      r = @client.fe_param_get_tipos_iva auth
      parse get_array(r, :iva_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end

    def cotizacion moneda_id
      r = @client.fe_param_get_cotizacion auth.merge :mon_id => moneda_id
      parse r[:result_get], :mon_cotiz => :float, :fch_cotiz => :date
    end
    
    def autorizar_comprobante comprobante
      r = @client.fecae_solicitar auth.merge comprobante
      parse r, :fch_proceso => :date, :cbte_desde => :integer, :cbte_hasta => :integer, :cae_fch_vto => :date
    end
    
    def ultimo_comprobante_autorizado opciones
      @client.fe_comp_ultimo_autorizado(auth.merge(opciones))[:cbte_nro].to_i
    end
    
    private
    def get_array response, array_element
      Array.wrap response[:result_get][array_element]
    end

    # Hace una conversión recursiva de tipo de todos los values según los tipos de las keys indicados en types
    def parse array_o_hash, types
      case array_o_hash
      when Array then array_o_hash.map { |hash| parse hash, types }
      when Hash then Hash[array_o_hash.map { |k, v| [k, v.is_a?(Hash) || v.is_a?(Array) ? parse(v, types) : parsing_fn[types[k]].call(v)] }]
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
