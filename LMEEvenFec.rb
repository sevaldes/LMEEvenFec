require 'date'
require 'savon'
require 'csv'
require 'mail'
require 'dotenv'

Dotenv.load


def build_request(financiador, financiador_password, desde, hasta)
    return "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WsLMEInet\">
    <soapenv:Header/>
    <soapenv:Body>
       <urn:LMEEvenFec soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
          <LMEEvenFec xsi:type=\"urn:LMEEvenFec\">
             <CodigoOperador xsi:type=\"xsd:string\">3</CodigoOperador>
             <TipoInstitucion xsi:type=\"xsd:string\">A</TipoInstitucion>
             <CodUsuario xsi:type=\"xsd:string\">#{financiador}</CodUsuario>
             <Clave xsi:type=\"xsd:string\">#{financiador_password}</Clave>
             <FecDesde xsi:type=\"xsd:dateTime\">#{desde}</FecDesde>
             <FecHasta xsi:type=\"xsd:dateTime\">#{hasta}</FecHasta>
          </LMEEvenFec>
       </urn:LMEEvenFec>
    </soapenv:Body>
    </soapenv:Envelope>"
end

def actualizar_desde(fecha_ultimo_registro)
    return fecha_ultimo_registro + Rational(1, 86400)
end

def send_mail(filename)
    options = { 
        address:              "smtp.gmail.com",
        port:                 587,
        user_name:            ENV['MAIL_USERNAME'],
        password:             ENV['MAIL_PASSWORD'],
        authentication:       'plain',
        enable_starttls_auto: true  
    }
    
    mail = Mail.new do
        from        ENV['SENDER']
        to          ENV['RECIPIENTS']
        subject     ENV['SUBJECT']
        body        ''
    end

    mail.delivery_method :smtp, options
    mail.add_file(filename)
    mail.deliver!
end

def generar_reporte
    financiador_codigo = ENV['FINANCIADOR_CODIGO']
    financiador_password = ENV['FINANCIADOR_PASSWORD']

    hasta = Date.today.to_datetime
    desde = Date.today.prev_day.to_datetime

    desde_str = desde.strftime("%Y-%m-%dT00:00:00")
    hasta_str = hasta.strftime("%Y-%m-%dT00:00:00")

    filename = "#{financiador_codigo}_#{desde.strftime('%Y%m%d')}.csv"

    url_wsdl = 'http://ws.licencia.cl/Wslme.php?wsdl'

    client = Savon.client(wsdl: url_wsdl)

    CSV.open(filename, "wb") do |csv|
        csv << ['NumLicencia', 'DvLicencia', 'Estado', 'Fecha']

        loop do
            request = build_request(financiador_codigo, financiador_password, desde_str, hasta_str)
            response = client.call(:lme_even_fec, xml: request)
            eventos = response.body[:lme_even_fec_response][:lme_even_fec_return][:lista_licencias]

            break if eventos.nil?
            eventos[:item].each do |row| 
                csv << [
                    row[:num_licencia],
                    row[:dig_licencia],
                    row[:estado],
                    row[:fecha].strftime("%Y-%m-%d %H:%M:%S")
                ]
            end

            desde_tmp = actualizar_desde(eventos[:item].last[:fecha])
            break if desde_tmp >= hasta
            desde_str = desde_tmp.strftime("%Y-%m-%dT%H:%M:%S")
        end
    end

    return filename
end

filename = generar_reporte
send_mail(filename)