# Security

## Reporting a problem

Please report security problems privately, not in a public issue.

On GitHub, open the **Security** tab of this repo and choose
**Report a vulnerability**. Only the maintainer sees the report.

If that button is not there, open an issue titled **Security contact
please**, with no details in it. The maintainer will reach out to you privately.

You can expect a first reply within a week.

## What counts

Anything that lets these scripts do something the person running them did not
agree to. For example:

- the settings file being run as code instead of read as text
- an installer writing to a file other than the ones it names
- `cc` or `cx` turning off the agent safety check without the user choosing to
- a way to get a shortcut to run a different program than the one it names

## Supported versions

Only the latest commit on `main` gets fixes.
