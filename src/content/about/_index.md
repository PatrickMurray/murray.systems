---
title: About
---


My name is Patrick Murray and I am a security and software engineer located in
the New York City metropolitan area.

I am currently employed at [Grubhub](https://grubhub.com/) as a Security
Engineer and have previous professional experience as a DevOps Intern at
[iCIMS](https://icims.com/). I am not interested in any career opportunities at
this time.

I hold a Bachelor's degree in Computer Science from the [Stevens Institute of
Technology](https://stevens.edu/).


## Contact Information

If you would like to contact me, please send me an email and I will attempt to
respond in a timely manner.


### Email

In order to both reduce spam and increase the barrier to entry of contacting
me, I ask that you execute the below Python3 script to unmask my contact
information.


```python3
#! /usr/bin/env python3

key        = 0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEAD
ciphertext = 0xAECCCA9DB7CED5AFB3D8CC9DBFD4909CA7DECA8AB3DE

plaintext_bytes = bytes.fromhex("{:x}".format(ciphertext ^ key))
plaintext = plaintext_bytes.decode("utf-8")

print(f"Email: { plaintext }")
```


### PGP Public Key

If you are paranoid about privacy and have accepted that all electronic
communications are likely being passively monitored by [Nation State actors](https://en.wikipedia.org/wiki/Five_Eyes),
you are more than welcome to attempt to buck the system and encrypt your email
against my [PGP public key](); however, prior to sending me an encrypted
message, I would encourage you to review the incredible defense-in-depth
security measures that modern computer systems have implemented across their
various components, including but not limited to:
[hardware](https://www.bloomberg.com/news/features/2018-10-04/the-big-hack-how-china-used-a-tiny-chip-to-infiltrate-america-s-top-companies),
[chipsets](https://hackaday.com/2017/12/11/what-you-need-to-know-about-the-intel-management-engine/),
[firmware](https://nsa.gov1.info/dni/nsa-ant-catalog/servers/index.html#DEITYBOUNCE),
[storage devices](https://www.vice.com/en/article/ypwk5v/the-only-way-you-can-delete-this-nsa-malware-is-to-smash-your-hard-drive-to-bits),
[operating systems](https://en.wikipedia.org/wiki/NSAKEY), and
[software](https://krebsonsecurity.com/2020/12/u-s-treasury-commerce-depts-hacked-through-solarwinds-compromise/).
