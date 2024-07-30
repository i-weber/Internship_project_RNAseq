#!/bin/bash

prefetch SRR13761525 --max-size 420000000000
prefetch SRR13761526 --max-size 420000000000
prefetch SRR13761527 --max-size 420000000000

fasterq-dump SRR13761521
fasterq-dump SRR13761522
fasterq-dump SRR13761523
fasterq-dump SRR13761524
fasterq-dump SRR13761525
fasterq-dump SRR13761526
fasterq-dump SRR13761527

