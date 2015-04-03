#!/bin/sh
for name in *.parser; do
	base=`basename $name .parser`
	rm -rf $base $base.pl $base.tar.gz
done
rm -rf framework framework.tar.gz
