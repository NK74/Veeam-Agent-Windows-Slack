# Veeam Agent for Windows (VAW) to Slack
Your Veeam Agent for Windows backup status to your Slack channel with Powershell 5.1 !


## Installation

It's a simple powershell script, 2 script requirement : 
- Powershell 5.0 or 5.1
- PSModule PSSLACK (@RamblingCookieMonster https://github.com/RamblingCookieMonster/PSSlack )

`Install-Module PSSlack -Force`


## Configuration

You only need to create your webhook token on Slack
And custom information field on PS script


## Acknowledgements

Special credit to Veeam community forum whose Veeam Endpoint script & @RamblingCookieMonster for Powershell Webhook to Slack that I used as a jumping off point for this.
