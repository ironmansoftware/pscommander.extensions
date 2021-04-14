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
    } -Height 200 -Width 1400 -Top 20 -Left 100 -DataSource 'ComputerInfo'
}