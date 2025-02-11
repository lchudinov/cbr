Add-Type -AssemblyName System.Windows.Forms

# Создаем форму
$form = New-Object System.Windows.Forms.Form
$form.Text = "Курс доллара ЦБ РФ"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Метка для даты
$label = New-Object System.Windows.Forms.Label
$label.Text = "Выберите дату:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

# Элемент выбора даты
$datePicker = New-Object System.Windows.Forms.DateTimePicker
$datePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$datePicker.Location = New-Object System.Drawing.Point(20, 50)
$form.Controls.Add($datePicker)

# Поле для вывода курса (TextBox)
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(20, 90)
$outputTextBox.Size = New-Object System.Drawing.Size(240, 20)
$outputTextBox.ReadOnly = $true
$form.Controls.Add($outputTextBox)

# Функция запроса курса
function Get-UsdRate {
	param([string]$On_date)

	$uri = "https://cbr.ru/DailyInfoWebServ/DailyInfo.asmx"
	$soapAction = "http://web.cbr.ru/GetCursOnDateXML"
	$headers = @{ "Content-Type" = "text/xml; charset=utf-8"; "SOAPAction" = $soapAction }

	$body = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
               xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCursOnDateXML xmlns="http://web.cbr.ru/">
      <On_date>$On_date</On_date>
    </GetCursOnDateXML>
  </soap:Body>
</soap:Envelope>
"@

	try {
		$response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $body -UseBasicParsing
		[xml]$xml = $response.Content

		# Определяем пространство имен
		$namespace = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
		$namespace.AddNamespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
		$namespace.AddNamespace("cbr", "http://web.cbr.ru/")

		# Получаем XML-результат
		$resultNode = $xml.SelectSingleNode("//soap:Body/cbr:GetCursOnDateXMLResponse/cbr:GetCursOnDateXMLResult", $namespace)

		if ($resultNode) {
			[xml]$valuteData = $resultNode.OuterXml
			$valutes = $valuteData.SelectNodes("//ValuteCursOnDate")

			foreach ($valute in $valutes) {
				$code = $valute.VchCode
				$rate = $valute.Vcurs

				if ($code -eq "USD") {
					return "$rate"
				}
			}
		}
	} catch {
		return "Ошибка запроса: $_"
	}
	return "Данные не найдены"
}

# Функция обновления курса
function Update-Rate {
	$selectedDate = $datePicker.Value.ToString("yyyy-MM-dd")
	$outputTextBox.Text = "Загрузка..."
	$rate = Get-UsdRate -On_date $selectedDate
	$outputTextBox.Text = $rate
	if ($rate -notmatch "Ошибка|Данные не найдены") {
		Set-Clipboard -Value $rate
	}
}

# Событие изменения даты
$datePicker.Add_ValueChanged({ Update-Rate })

# Автозагрузка курса на текущую дату при запуске формы
$form.Add_Shown({ Update-Rate })

# Запуск формы
$form.ShowDialog()
