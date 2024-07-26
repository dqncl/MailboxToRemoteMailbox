function Get-MailboxToConvert {
    param (
        [string]$Filter = "*@example.com"
    )

    $MailboxToConvert = Get-Mailbox | Where-Object { $_.ForwardingSmtpAddress -like $Filter } | Select-Object -First 1
    return $MailboxToConvert
}

function Update-RemoteMailboxAttribute {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteMailbox,
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MailboxToConvert,
        [Parameter(Mandatory = $true)]
        [string] $attribute
    )

    if ($remoteMailbox.$attribute -ne $MailboxToConvert.$attribute) {
        Write-Verbose "Updating $attribute for: $($MailboxToConvert.SamAccountName)"
        switch ($attribute) {
            "HiddenFromAddressListsEnabled" {
                Set-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -HiddenFromAddressListsEnabled $MailboxToConvert.HiddenFromAddressListsEnabled
            }
            "EmailAddresses" {
                Set-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -EmailAddresses $MailboxToConvert.EmailAddresses
            }
            "CustomAttribute1" {
                Set-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -CustomAttribute1 $MailboxToConvert.CustomAttribute1
            }
            "PrimarySmtpAddress" {
                Set-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -PrimarySmtpAddress $MailboxToConvert.PrimarySmtpAddress
            }
        }
    }
}

function ConvertMailboxToRemoteMailbox {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MailboxToConvert
    )

    try {
        Write-Verbose "Disabling mailbox for: $($MailboxToConvert.SamAccountName)"
        Disable-Mailbox -Identity $MailboxToConvert.SamAccountName -Confirm:$false

        Write-Verbose "Enabling remote mailbox for: $($MailboxToConvert.SamAccountName)"
        Enable-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -RemoteRoutingAddress $MailboxToConvert.ForwardingSmtpAddress

        Write-Verbose "Disabling email address policy for: $($MailboxToConvert.SamAccountName)"
        Set-RemoteMailbox -Identity $MailboxToConvert.SamAccountName -EmailAddressPolicyEnabled $false

        $remoteMailbox = Get-RemoteMailbox -Identity $MailboxToConvert.SamAccountName

        $attributesToCheck = @("HiddenFromAddressListsEnabled", "EmailAddresses", "CustomAttribute1", "PrimarySmtpAddress")

        foreach ($attribute in $attributesToCheck) {
            Update-RemoteMailboxAttribute -remoteMailbox $remoteMailbox -MailboxToConvert $MailboxToConvert -attribute $attribute
        }

        Write-Output "Mailbox $($MailboxToConvert.SamAccountName) successfully converted to remote mailbox."

    } catch {
        Write-Error "An error occurred while converting mailbox $($MailboxToConvert.SamAccountName): $_"
    }
}

function TestConvertedMailbox {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $OriginalMailbox,
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ConvertedMailbox
    )

    $changes = @()

    if ($OriginalMailbox.EmailAddresses.Count -ne $ConvertedMailbox.EmailAddresses.Count) {
        $changes += "EmailAddresses"
    }
    if ($OriginalMailbox.PrimarySmtpAddress -ne $ConvertedMailbox.PrimarySmtpAddress) {
        $changes += "PrimarySmtpAddress"
    }

    if ($changes.Count -gt 0) {
        Write-Warning "The following attributes changed for $($ConvertedMailbox.SamAccountName): $($changes -join ', ')"
    } else {
        Write-Output "No attribute changes detected for $($ConvertedMailbox.SamAccountName)."
    }
}

function main {
    param (
        [int]$SleepInterval = 10,
        [string]$Filter = "*@example.com"
    )

    while ($true) {
        $Mailbox = Get-MailboxToConvert -Filter $Filter
        if ($Mailbox) {
            $OriginalMailbox = [PSCustomObject]$Mailbox.PSObject.Copy()
            ConvertMailboxToRemoteMailbox -MailboxToConvert $Mailbox
            $ConvertedMailbox = Get-RemoteMailbox -Identity $Mailbox.SamAccountName
            TestConvertedMailbox -OriginalMailbox $OriginalMailbox -ConvertedMailbox $ConvertedMailbox
        } else {
            Write-Host "No mailboxes left to convert."
            break
        }
        Start-Sleep -Seconds $SleepInterval # Pause to avoid rapid looping
    }
}

$VerbosePreference = 'Continue'

main -SleepInterval 10 -Filter "*@example.com"
