param(
    [string]$On_date = (Get-Date -Format "yyyy-MM-dd")
)

$uri = "https://cbr.ru/DailyInfoWebServ/DailyInfo.asmx"
$soapAction = "http://web.cbr.ru/GetCursOnDateXML"
$headers = @{ "Content-Type" = "text/xml; charset=utf-8"; "SOAPAction" = $soapAction }

$body = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCursOnDateXML xmlns="http://web.cbr.ru/">
      <On_date>$On_date</On_date>
    </GetCursOnDateXML>
  </soap:Body>
</soap:Envelope>
"@

$response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $body

# Load XML
[xml]$xml = $response.Content

# Find all currency nodes
$valutes = $xml.SelectNodes("//ValuteCursOnDate")

foreach ($valute in $valutes) {
    $code = $valute.VchCode
    $rate = $valute.Vcurs

    if ($code -eq "USD") {
        Write-Output "Exchange rate for USD: $rate"
        break
    }
}