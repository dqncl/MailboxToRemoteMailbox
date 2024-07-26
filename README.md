# Mailbox Conversion Script

This PowerShell script is designed to automate the conversion of on-premises mailboxes to remote mailboxes in an Exchange environment. The script performs several key functions including identifying mailboxes to convert, updating attributes, and verifying the conversion.

## Prerequisites

- Exchange Online PowerShell Module
- Sufficient permissions to run mailbox and remote mailbox commands

## Script Functions

### Get-MailboxToConvert

Identifies the next mailbox that needs to be converted based on a specified filter.

**Parameters:**
- `Filter` (string): The filter to identify mailboxes to be converted. Default is `*MR-*@example.com`.

### Update-RemoteMailboxAttribute

Updates specific attributes of the remote mailbox to match the original mailbox.

**Parameters:**
- `remoteMailbox` (PSCustomObject): The remote mailbox object.
- `MailboxToConvert` (PSCustomObject): The original mailbox object.
- `attribute` (string): The attribute to be updated.

### ConvertMailboxToRemoteMailbox

Disables the original mailbox and enables it as a remote mailbox. It also updates necessary attributes and verifies the conversion.

**Parameters:**
- `MailboxToConvert` (PSCustomObject): The original mailbox object to be converted.

### TestConvertedMailbox

Checks if specific attributes of the converted mailbox match those of the original mailbox and logs any discrepancies.

**Parameters:**
- `OriginalMailbox` (PSCustomObject): The original mailbox object.
- `ConvertedMailbox` (PSCustomObject): The converted remote mailbox object.

### main

Main function that orchestrates the conversion process. It runs in a loop, converting mailboxes one by one until no more mailboxes match the filter.

**Parameters:**
- `SleepInterval` (int): Time in seconds to pause between conversions. Default is 10 seconds.
- `Filter` (string): The filter to identify mailboxes to be converted. Default is `*MR-*@example.com`.

## Usage

1. Ensure you have the necessary permissions and the Exchange Online PowerShell module installed.
2. Modify the script if necessary to fit your environment.
3. Run the script in a PowerShell session with appropriate privileges.

```powershell
$VerbosePreference = 'Continue'
main -SleepInterval 10 -Filter "*MR-*@example.com"
