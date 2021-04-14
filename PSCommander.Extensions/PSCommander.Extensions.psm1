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

function New-CommanderDriveSpaceChart
{
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