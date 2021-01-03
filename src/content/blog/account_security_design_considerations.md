---
title: Access Control System Design Considerations
date: 2021-01-03

toc: True
---


## Purpose & Scope

Due to the incredibly broad nature of the information security field, this post
is strictly limited to discussing the considerations, design decisions, and
potential regulatory requirements that should be assessed prior to implementing
an access control system. Furthermore, this post was written under the
presumption that the access control system will be implemented for a web/mobile
application; however, many of the high-level concepts may be extended to other
information systems.


## Disclaimer

It is strongly encouraged that both your organization's Information Security
and Legal teams be consulted prior to finalizing your access control
system's requirements and architecture proposal. Your organization may be
subject to previously unknown regulatory, industry, or contractual obligations
which may impact the requirements for the access control system being designed.


## Background

Over the last decade, the threat of both cyber attacks and their repercussions
to organizations has grown tremendously.

It is no longer acceptable for any organization to disregard information
security best-practices and gaps in their security posture.

Several jurisdictions have enacted legislation mandating that organizations
maintain adequate information security programs, policies, and safeguards to
protect against cyber attacks and data breaches.

For example, the [State of New York](https://www.nysenate.gov/legislation/laws/GBS/899-BB)
requires that buesinesses posessing the private information of a New York
resident to implement a data security program and "reasonable technical
safeguards".



is an incredibly broad field encompassing many areas, for
the sake of this post account security will be discusses exclusively.





Organizations and their executives may be held responsible and legally liable
for their failure to implement "reasonable" security programs and safe-guards -
regardless of whether or not a breach has actually occurred.

In September 2020, [Dunkin Donuts](https://www.dunkindonuts.com) [settled](https://ag.ny.gov/press-release/2020/attorney-general-james-gets-dunkin-fill-holes-security-reimburse-hacked-customers)
a [lawsuit](https://ag.ny.gov/press-release/2019/ag-james-sues-dunkin-donuts-glazing-over-cyberattacks-targeting-thousands)
with the New York Attorney General over Dunkin's non-compliance with New York
data-security statutes. In the settlement, Dunkin agreed to pay $650,000 in
penalties for their inadequate response to attacks targetting user accounts.

While the Dunkin lawsuit was initiated following an attack, the statute incurs
a global penalty to organizations that fail to "maintain reasonable safeguards
to protect NY residents' private information". It is feasible that the New York
Attorney General














With regard to account security alone, compromised user accounts have the
potential to expose private and confidential information, up to and including
[personally identifable information (PII)](https://en.wikipedia.org/wiki/Personal_data).

and penalties


guidelines that organizations must follow, penalties for noncomplianice, and notification requirements when PII has been exposed.

or even prohibiting the usage of PII in certain circumstances



and the consquences resulting from them, with regard to regulatory penalties

legal liabilities
civil penalties
public relations impact






As technologists, in our individual capacity
it is our duty and responsibility in to ensure 

engineers cannot blindly and solely rely on their Information Security department to ensure coverage is thorough and 


everyone's responsibility to critically assess the security postures of our organizations.












resulted in a $650,000
settlement
over compromised customer accounts and their lack of security safe-guards.


who either
(1) decline to implement "reasonable" safe-guards or (2) omit
decision makers

decline to implement
omission



basic account


All technologists are security practitioners.
software engineer
site reliability
product manager

## Security Practicioner Mentality

Questions to ask:

- Can this feature or functionality be abused?
- If yes, how can abuse be prevented before it occurs?
- In the event that preventative security mechanisms fail, how can abuse be
  detected, responded to, and mitigated after the fact?
- Are these detection, response, and mitigation processes manual or automated?
- Can you detect abuse that circumvents your preventative measures?



data breaches
data exfiltration

built-in
bolted-on


Implementing reasonable security measures and safe-guards to protect user
accounts, information, and privacy is paramount.

The exact measures and safe-guards built-into the system may depend on the

regulatory compliance
contractual obligations
industry standards
jurisdiction



ensuring security.




personally identifable information (PII)

fraud, abuse


phishing



TODO

inception

strapping security on later


## Considerations

IAAA

### Account Security

#### Identification

TODO

#### Authentication

TODO

#### Authorization

TODO

#### Accountability / Audit

TODO


### Internal Processes

#### Credential Stuffing Prevention, Detection, and Remediation

TODO

#### Abuse and Fraud Prevention and Detection

TODO


## Technical Solutions

SIEM


## 30,000-Foot View

### Account Creation

TODO

### Authentication

TODO

### Authorization

TODO

### Forgot Credential

TODO

### Account Changes

#### Account Information

TODO

### Credential Reset

TODO

###
Transaction



## Compliance

TODO

### Regulatory Guidelines

HIPPA
GDPR


### Industry Best-Practices

PCIDSS


### Legal Compliance

TODO



retention

evidence


logging 
        (username?)


