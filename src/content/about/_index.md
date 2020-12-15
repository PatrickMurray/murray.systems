---
title: About
---


My name is Patrick Murray and I am a security and software engineer based out
of the New York City metropolitan area.

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
