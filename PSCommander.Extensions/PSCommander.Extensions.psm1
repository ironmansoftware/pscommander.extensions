function New-CommanderSimplePerformanceInfo
{
    <#
    .SYNOPSIS
    Creates a simple performance info bar.
    
    .DESCRIPTION
    Creates a simple performance info bar.
    
    .PARAMETER Height
    Height
    
    .PARAMETER Width
    Width
    
    .PARAMETER Top
    Top position.
    
    .PARAMETER Left
    Left position
    #>
    param(
        [Parameter()]
        [int]$Height = 200,
        [Parameter()]
        [int]$Width = 1400,
        [Parameter()]
        [int]$Top = 20,
        [Parameter()]
        [int]$Left = 100
    )

    Register-CommanderDataSource -Name 'ComputerInfo' -LoadData {
        $Stats = Get-NetAdapterStatistics
        $NetworkDown = 0
        $Stats.ReceivedBytes | Foreach-Object { $NetworkDown += $_ } 
        
        $NetworkUp = 0
        $Stats.SentBytes | Foreach-Object { $NetworkUp += $_ } 
            
        @{
            CPU = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -Expand Average
            Memory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
            NetworkUp = $NetworkUp / 1KB
            NetworkDown = $NetworkDown / 1KB
            Space = (Get-PSDrive C).Free / 1GB
        }
    } -RefreshInterval 5
     
    New-CommanderDesktopWidget -LoadWidget {
        [xml]$Form = Get-Content ("$PSScriptRoot\XAML\SimplePerformanceInfo.xaml") -Raw
            $XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
            [Windows.Markup.XamlReader]::Load($XMLReader)
    } -Height $Height -Width $Width -Top $Top -Left $Left -DataSource 'ComputerInfo'
}

function New-CommanderDriveSpaceGauge
{
    <#
    .SYNOPSIS
    Creates a simple gauge to display drive space.
    
    .DESCRIPTION
    Creates a simple gauge to display drive space.
    
    .PARAMETER DriveLetter
    The drive letter to display the space for.
    
    .PARAMETER Height
    Widget height
    
    .PARAMETER Width
    Widget width
    
    .PARAMETER Top
    Widget top offset
    
    .PARAMETER Left
    Widget left offset. 
    
    .EXAMPLE
    New-CommanderDriveSpaceGauage -DriveLetter C
    #>
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        [Parameter()]
        [int]$Height = 200,
        [Parameter()]
        [int]$Width = 200,
        [Parameter()]
        [int]$Top = 50,
        [Parameter()]
        [int]$Left = 50
    )

    Register-CommanderDataSource -Name "DriveSpace_$DriveLetter" -LoadData {
        $Drive = Get-PSDrive $args[0]
        @{
            Used = [Math]::Round($Drive.Used / 1GB)
            Total = [Math]::Round(($Drive.Free + $Drive.Used) / 1GB)
            Drive = $args[0]
        }
    } -RefreshInterval 60 -ArgumentList @($DriveLetter)

    New-CommanderDesktopWidget -LoadWidget {
        [xml]$Form = Get-Content ("$PSScriptRoot\XAML\DriveSpace.xaml") -Raw
            $XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
            [Windows.Markup.XamlReader]::Load($XMLReader)
    } -Height $Height -Width $Width -Top $Top -Left $Left -DataSource "DriveSpace_$DriveLetter"
}

function New-CommanderTimeAndDate 
{
    <#
    .SYNOPSIS
    Displays the date and time
    
    .DESCRIPTION
    Displays the date and time
    
    .PARAMETER Height
    Widget height
    
    .PARAMETER Width
    Widget width
    
    .PARAMETER Top
    Widget top offset
    
    .PARAMETER Left
    Widget left offset. 
    
    .EXAMPLE
    New-CommanderTimeAndDate
    #>
    param(
        [Parameter()]
        [int]$Height = 200,
        [Parameter()]
        [int]$Width = 300,
        [Parameter()]
        [int]$Top = 50,
        [Parameter()]
        [int]$Left = 50,
        [Parameter()]
        [System.TimeZoneInfo]$TimeZone
    )

    Register-CommanderDataSource -Name "Time" -LoadData {
        if ($args[0] -ne $null)
        {
            $Date = [TimeZoneInfo]::ConvertTime((Get-Date), $args[0])
            @{
                TimeZone = $args[0].Id
                Date = $Date
            }
        }
        else 
        {
            @{
                Date = Get-Date 
            }
        }
    } -RefreshInterval 60 -ArgumentList @($TimeZone)

    New-CommanderDesktopWidget -LoadWidget {
        [xml]$Form = Get-Content ("$PSScriptRoot\XAML\Clock.xaml") -Raw
            $XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
            [Windows.Markup.XamlReader]::Load($XMLReader)
    } -Height $Height -Width $Width -Top $Top -Left $Left -DataSource "Time"
}

function New-CommanderComputerInfo 
{
    <#
    .SYNOPSIS
    Displays computer information.
    
    .DESCRIPTION
    Displays computer information.
    
    .PARAMETER Height
    Widget height
    
    .PARAMETER Width
    Widget width
    
    .PARAMETER Top
    Widget top offset
    
    .PARAMETER Left
    Widget left offset. 
    
    .EXAMPLE
    New-CommanderComputerInfo

    #>
    param(
        [Parameter()]
        [int]$Height = 600,
        [Parameter()]
        [int]$Width = 400,
        [Parameter()]
        [int]$Top = 50,
        [Parameter()]
        [int]$Left = 50
    )

    Register-CommanderDataSource -Name "ComputerInfo" -LoadData {
        Get-ComputerInfo
    } -RefreshInterval 60

    New-CommanderDesktopWidget -LoadWidget {
        [xml]$Form = Get-Content ("$PSScriptRoot\XAML\ComputerInfo.xaml") -Raw
            $XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
            [Windows.Markup.XamlReader]::Load($XMLReader)
    } -Height $Height -Width $Width -Top $Top -Left $Left -DataSource "ComputerInfo"
}


function New-CommanderTicker 
{
    <#
    .SYNOPSIS
    Displays a stock or crypto ticker
    
    .DESCRIPTION
    Displays a stock or crypto ticker
    
    .PARAMETER Height
    Widget height
    
    .PARAMETER Width
    Widget width
    
    .PARAMETER Top
    Widget top offset
    
    .PARAMETER Left
    Widget left offset. 

    .PARAMETER StockSymbol
    Stock symbol

    .PARAMETER CryptoSymbol
    Crypto symbol
    
    .EXAMPLE
    New-CommanderTicker -StockSymbol MSFT -ApiKey ''

    #>
    param(
        [Parameter()]
        [int]$Height = 600,
        [Parameter()]
        [int]$Width = 400,
        [Parameter()]
        [int]$Top = 50,
        [Parameter()]
        [int]$Left = 50,
        [Parameter(Mandatory, ParameterSetName = "Stock")]
        [string]$StockSymbol,
        [Parameter(Mandatory, ParameterSetName = "Crypto")]
        [string]$CryptoSymbol,
        [Parameter(ParameterSetName = "Crypto")]
        [string]$CryptoTarget = 'USD',
        [Parameter(Mandatory)]
        [string]$ApiKey
    )

    $Symbol = $CryptoSymbol 
    if ($StockSymbol)
    {
        $Symbol = $StockSymbol
    }

    Register-CommanderDataSource -Name "Stock_$Symbol" -LoadData {

        $Symbol = $Args[0]
        $ApiKey = $Args[1]
        $Type = $Args[2]
        $CryptoTarget = $Args[3]

        $Date = Get-Date
        if ($Date.DayOfWeek -eq [DayOfWeek]::Monday)
        {
            $Date = $Date.AddDays(-2)
        }

        if ($Date.DayOfWeek -eq [DayOfWeek]::Saturday)
        {
            $Date = $Date.AddDays(-1)
        }

        $StrDate = $Date.ToString("yyyy-MM-dd")

        if ($Type -eq 'Crypto')
        {
            $Uri = "v1/open-close/crypto/$Symbol/USD/$($StrDate)?apiKey=$ApiKey"
        }
        else 
        {
            $Uri = "v1/open-close/$Symbol/$($StrDate)?unadjusted=true&apiKey=$ApiKey"
        }
    
        $Result = Invoke-RestMethod "https://api.polygon.io/$Uri" -ErrorAction SilentlyContinue

        if ($Result.Close -lt $Result.Open)
        {
            $ForegroundColor = "#c63629"
        }
        else 
        {
            $ForegroundColor = "#28bf37"
        }

        if ($Type -eq 'Crypto')
        {
            $Symbol = "$Symbol-$CryptoTarget"
        }

        @{
            Symbol = $Symbol
            Close = $Result.Close
            Open = $Result.Open
            ForegroundColor = $ForegroundColor
        }
    } -RefreshInterval 86400 -ArgumentList @($Symbol, $ApiKey, $PSCmdlet.ParameterSetName, $CryptoTarget)

    New-CommanderDesktopWidget -LoadWidget {
        [xml]$Form = Get-Content ("$PSScriptRoot\XAML\Ticker.xaml") -Raw
        $XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
        [Windows.Markup.XamlReader]::Load($XMLReader)
    } -Height $Height -Width $Width -Top $Top -Left $Left -DataSource "Stock_$Symbol"
}