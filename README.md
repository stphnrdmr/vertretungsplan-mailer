[![Dependency Status](https://gemnasium.com/badges/github.com/stphnrdmr/vertretungsplan-mailer.svg)](https://gemnasium.com/github.com/stphnrdmr/vertretungsplan-mailer)
[![Code Climate](https://codeclimate.com/github/srodeme/vertretungsplan-mailer/badges/gpa.svg)](https://codeclimate.com/github/srodeme/vertretungsplan-mailer)
# Vertretungsplan-Mailer

This program sends notifications containing the relevant entries for the next day.
In addition to e-mail, a notification can be sent via slack.

For sending e-mail it uses [mailgun](http://www.mailgun.com/).
The slack notification is sent via the webhooks integration of slack.

# Configuration

The file ``.env.example`` has to be copied to ``.env`` and the settings need to be adjusted.

E-mail and slack notifications can be enabled/disabled in ``feature.yml``.

# License

This content is released under the [MIT License](http://www.opensource.org/licenses/MIT).
