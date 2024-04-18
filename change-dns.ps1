<#
    Script Name: DNS Configuration Tool
    Description: This script changes the DNS settings for all active network adapters.
    Author: Vamsi
    URL: https://windowsloop.com
#>

function Get-ValidIPAddress {
    param (
        [string]$prompt,
        [bool]$allowEmpty = $false
    )
    do {
        $ip = Read-Host -Prompt $prompt
        if ($allowEmpty -and $ip -eq "") {
            return $null
        }
        $ipValid = $ip -match '^\d{1,3}(\.\d{1,3}){3}$' -and ($ip.Split('.') | ForEach-Object {$_ -ge 0 -and $_ -le 255})
        if (-not $ipValid) {
            Write-Host "Invalid IP address. Please enter a valid IPv4 address or leave blank if optional." -ForegroundColor Red
        }
    } while (-not $ipValid)
    return $ip
}

function DisplayCurrentDNS {
    param (
        [string]$description,
        [System.Management.Automation.PSObject]$adapters
    )
    Write-Host "`n$description" -ForegroundColor Cyan
    foreach ($adapter in $adapters) {
        $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex).ServerAddresses
        $dnsString = if ($dns) { $dns -join ', ' } else { "Not Set" }
        Write-Host "Adapter: $($adapter.Name) - DNS: $dnsString" -ForegroundColor Yellow
    }
}

# Get all network adapters that are enabled
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Display current DNS settings
DisplayCurrentDNS -description "Current DNS Settings:" -adapters $adapters

# Ask for Primary and Secondary DNS addresses
$primaryDNS = Get-ValidIPAddress -prompt 'Primary DNS'
$secondaryDNS = Get-ValidIPAddress -prompt 'Secondary DNS (leave blank if not needed)' -allowEmpty $true

# Set DNS servers for each adapter and display changes
foreach ($adapter in $adapters) {
    Write-Host "`nSetting DNS for adapter: $($adapter.Name)" -ForegroundColor Green
    $dnsSettings = @($primaryDNS) + @($secondaryDNS | Where-Object { $_ }) # Only add secondary if not null
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsSettings -ErrorAction Stop
        Write-Host "DNS changed successfully for $($adapter.Name)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to change DNS for $($adapter.Name)" -ForegroundColor Red
    }
}

# Display new DNS settings
DisplayCurrentDNS -description "New DNS Settings:" -adapters $adapters
