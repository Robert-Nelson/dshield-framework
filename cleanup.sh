#!/bin/sh
for name in *.parser; do
	base=`basename $name .parser`
	rm -rf $base{,.pl,.tar.gz}
done
rm -rf framework{,.tar.gz}
